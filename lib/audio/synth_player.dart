import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'waveform.dart';

class SynthPlayer extends ChangeNotifier {
  SynthPlayer({this._waveform = Waveform.sine, this._frequency = 440});

  Waveform _waveform;
  double _frequency;
  double _modulationDepth = 0.0;
  double _lfoPhase = 0.0;
  Timer? _lfoTimer;

  AudioSource? _source;
  SoundHandle? _handle;

  SoLoud get _soloud => SoLoud.instance;

  bool get isPlaying => _handle != null;
  Waveform get waveform => _waveform;
  double get frequency => _frequency;
  double get modulation => _modulationDepth;

  Future<void> start() async {
    if (_handle != null) return;
    if (!_soloud.isInitialized) await _soloud.init();
    final source = _source ??= await _soloud.loadWaveform(
      _waveform.soloudWave,
      false,
      1,
      0,
    );
    _soloud
      ..setWaveform(source, _waveform.soloudWave)
      ..setWaveformFreq(source, _frequency);
    _handle = _soloud.play(source, volume: _waveform.gain);

    _startLfoLoop();
    notifyListeners();
  }

  void _startLfoLoop() {
    _lfoTimer?.cancel();
    _lfoTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final source = _source;
      if (source == null || !isPlaying) return;

      if (_modulationDepth <= 0.01) {
        _soloud.setWaveformFreq(source, _frequency);
        return;
      }

      final lfoRateHz = 4.0 + (_modulationDepth * 8.0);
      _lfoPhase += (2 * math.pi * lfoRateHz) * 0.016;
      if (_lfoPhase > 2 * math.pi) _lfoPhase -= 2 * math.pi;

      final lfoValue = math.sin(_lfoPhase);
      final deviation = _frequency * 0.15 * _modulationDepth * lfoValue;
      _soloud.setWaveformFreq(source, _frequency + deviation);
    });
  }

  Future<void> stop() async {
    _lfoTimer?.cancel();
    final handle = _handle;
    if (handle == null) return;
    _handle = null;
    await _soloud.stop(handle);
    notifyListeners();
  }

  void setWaveform(Waveform waveform) {
    _waveform = waveform;
    final source = _source;
    if (source != null) _soloud.setWaveform(source, waveform.soloudWave);
    final handle = _handle;
    if (handle != null) _soloud.setVolume(handle, waveform.gain);
    notifyListeners();
  }

  void setFrequency(double frequency) {
    _frequency = frequency;
    if (_modulationDepth <= 0.01 && _source != null) {
      _soloud.setWaveformFreq(_source!, frequency);
    }
    notifyListeners();
  }

  void setModulation(double depth) {
    final clamped = depth.clamp(0.0, 1.0);
    if ((_modulationDepth - clamped).abs() < 0.005) return;
    _modulationDepth = clamped;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _lfoTimer?.cancel();
    _handle = null;
    _source = null;
    if (_soloud.isInitialized) await _soloud.deinitAsync();
    super.dispose();
  }
}