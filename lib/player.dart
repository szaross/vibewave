import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

enum WaveType { sine, square, sawtooth }

class SoundPlayer {
  static const int sampleRate = 44100;
  static const int bufferSize = 4096;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _player.openPlayer();
    
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: 1,
      sampleRate: sampleRate,
      bufferSize: bufferSize,
      onBufferUnderflow: () {
        print('Warning: Buffer Underflow in SoundPlayer');
      },
    );

    _isInitialized = true;
  }

  void playTone({
    required double frequency,
    required double durationSeconds,
    WaveType waveType = WaveType.sine,
  }) {
    if (!_isInitialized) return;

    final int totalSamples = (durationSeconds * sampleRate).toInt();
    
    final ByteData byteData = ByteData(totalSamples * 2);
    final double fadeLength = sampleRate * 0.01; // 10ms

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      double sampleValue = 0.0;

      switch (waveType) {
        case WaveType.sine:
          sampleValue = sin(2 * pi * frequency * t);
          break;
        case WaveType.square:
          sampleValue = sin(2 * pi * frequency * t) >= 0 ? 0.7 : -0.7;
          break;
        case WaveType.sawtooth:
          sampleValue = 2 * (frequency * t - (frequency * t + 0.5).floor());
          break;
      }

      double envelope = 1.0;
      if (i < fadeLength) {
        envelope = i / fadeLength;
      } else if (i > totalSamples - fadeLength) {
        envelope = (totalSamples - i) / fadeLength;
      }

      final int sampleInt = (sampleValue * 32767 * envelope).toInt().clamp(-32768, 32767);
      
      byteData.setInt16(i * 2, sampleInt, Endian.little);
    }

    _player.feedFromStream(byteData.buffer.asUint8List());
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _player.stopPlayer();
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _player.stopPlayer();
      await _player.closePlayer();
      _isInitialized = false;
    }
  }
}