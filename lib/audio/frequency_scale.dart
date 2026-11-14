import 'dart:math';

const double minFrequency = 110;
const double maxFrequency = 880;

/// Maps a slider position in `[0, 1]` to a frequency on a logarithmic scale,
/// so every octave takes the same slider width.
double frequencyFromSlider(double position) =>
    minFrequency *
    pow(maxFrequency / minFrequency, position.clamp(0.0, 1.0)).toDouble();

double sliderFromFrequency(double frequency) =>
    log(frequency.clamp(minFrequency, maxFrequency) / minFrequency) /
    log(maxFrequency / minFrequency);
