import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibewave/audio/frequency_scale.dart';

void main() {
  test('slider ends map to the frequency range', () {
    expect(frequencyFromSlider(0), minFrequency);
    expect(frequencyFromSlider(1), closeTo(maxFrequency, 1e-9));
  });

  test('each third of the slider is one octave', () {
    expect(frequencyFromSlider(1 / 3), closeTo(220, 1e-9));
    expect(frequencyFromSlider(2 / 3), closeTo(440, 1e-9));
    expect(frequencyFromSlider(0.5), closeTo(sqrt(110 * 880), 1e-9));
  });

  test('sliderFromFrequency inverts frequencyFromSlider', () {
    for (final position in [0.0, 0.1, 0.25, 0.5, 0.9, 1.0]) {
      expect(
        sliderFromFrequency(frequencyFromSlider(position)),
        closeTo(position, 1e-9),
      );
    }
  });

  test('out-of-range values are clamped', () {
    expect(frequencyFromSlider(-1), minFrequency);
    expect(frequencyFromSlider(2), closeTo(maxFrequency, 1e-9));
    expect(sliderFromFrequency(20), 0);
    expect(sliderFromFrequency(5000), closeTo(1, 1e-9));
  });
}
