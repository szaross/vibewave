import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';

/// Plays a continuous sine tone by streaming PCM chunks to flutter_sound.
///
/// Only one feed may be in flight at a time: flutter_sound writes each feed on
/// its own native thread to a shared AudioTrack, and concurrent writes (or
/// stopping mid-write) segfault on Android.
class SinePlayer {
  static const int sampleRate = 44100;
  static const int _chunkSamples = 2048;
  static const int _bufferBytes = 2 * 2 * _chunkSamples;
  static const int _fadeSamples = sampleRate ~/ 100;
  static const double _amplitude = 0.5;

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isOpen = false;
  bool _running = false;
  double _phase = 0;
  Future<void>? _loop;
  Future<void> _queue = Future.value();

  bool get isPlaying => _loop != null;

  Future<void> start({double frequency = 440}) =>
      _enqueue(() => _start(frequency));

  Future<void> stop() => _enqueue(_stop);

  Future<void> dispose() => _enqueue(() async {
    await _stop();
    if (_isOpen) {
      _isOpen = false;
      await _player.closePlayer();
    }
  });

  Future<void> _enqueue(Future<void> Function() op) =>
      _queue = _queue.catchError((_) {}).then((_) => op());

  Future<void> _start(double frequency) async {
    if (_loop != null) return;
    if (!_isOpen) {
      await _player.openPlayer();
      _isOpen = true;
    }
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: 1,
      sampleRate: sampleRate,
      bufferSize: _bufferBytes,
    );
    _running = true;
    _phase = 0;
    _loop = _feedLoop(2 * pi * frequency / sampleRate);
  }

  Future<void> _stop() async {
    final loop = _loop;
    if (loop == null) return;
    _running = false;
    try {
      await loop;
    } finally {
      _loop = null;
      await _player.stopPlayer();
    }
  }

  Future<void> _feedLoop(double step) async {
    await _player.feedUint8FromStream(
      _sine(_chunkSamples, step, (i) => min(1.0, i / _fadeSamples)),
    );
    while (_running) {
      await _player.feedUint8FromStream(_sine(_chunkSamples, step, (_) => 1.0));
    }
    await _player.feedUint8FromStream(
      _sine(_fadeSamples, step, (i) => 1.0 - i / _fadeSamples),
    );
  }

  Uint8List _sine(int count, double step, double Function(int i) envelope) {
    final data = ByteData(count * 2);
    for (var i = 0; i < count; i++) {
      final sample = sin(_phase) * _amplitude * envelope(i);
      data.setInt16(i * 2, (sample * 32767).round(), Endian.little);
      _phase = (_phase + step) % (2 * pi);
    }
    return data.buffer.asUint8List();
  }
}
