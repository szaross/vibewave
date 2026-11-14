import 'package:flutter_soloud/flutter_soloud.dart';

import 'waveform.dart';

/// A single oscillator voice whose waveform and frequency can change while it
/// plays. The first [start] call starts the SoLoud engine.
class SynthPlayer {
  SynthPlayer({this._waveform = Waveform.sine, this._frequency = 440});

  Waveform _waveform;
  double _frequency;
  AudioSource? _source;
  SoundHandle? _handle;

  SoLoud get _soloud => SoLoud.instance;

  bool get isPlaying => _handle != null;
  Waveform get waveform => _waveform;
  double get frequency => _frequency;

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
  }

  Future<void> stop() async {
    final handle = _handle;
    if (handle == null) return;
    _handle = null;
    await _soloud.stop(handle);
  }

  void setWaveform(Waveform waveform) {
    _waveform = waveform;
    final source = _source;
    if (source != null) _soloud.setWaveform(source, waveform.soloudWave);
    final handle = _handle;
    if (handle != null) _soloud.setVolume(handle, waveform.gain);
  }

  void setFrequency(double frequency) {
    _frequency = frequency;
    final source = _source;
    if (source != null) _soloud.setWaveformFreq(source, frequency);
  }

  Future<void> dispose() async {
    _handle = null;
    _source = null;
    if (_soloud.isInitialized) await _soloud.deinitAsync();
  }
}
