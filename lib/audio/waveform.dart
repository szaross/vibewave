import 'package:flutter_soloud/flutter_soloud.dart';

enum Waveform {
  sine('Sine', WaveForm.sin, 0.8),
  square('Square', WaveForm.fSquare, 0.58),
  triangle('Triangle', WaveForm.triangle, 0.98),
  saw('Saw', WaveForm.fSaw, 1.0);

  const Waveform(this.label, this.soloudWave, this.gain);

  final String label;
  final WaveForm soloudWave;

  /// Playback volume that matches this oscillator's RMS level to SoLoud's
  /// Fourier saw, the quietest of the four.
  final double gain;
}
