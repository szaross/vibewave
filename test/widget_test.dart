import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibewave/audio/waveform.dart';
import 'package:vibewave/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders synth controls and sensor cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          gyroscope: Stream.empty(),
          accelerometer: Stream.empty(),
        ),
      ),
    );

    expect(find.text('VibeWave'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    for (final label in ['Sine', 'Square', 'Triangle', 'Saw']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('440 Hz'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.textContaining('Gyroscope'), findsOneWidget);
    expect(find.textContaining('Accelerometer'), findsOneWidget);
  });

  testWidgets('waveform and frequency change without starting audio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          gyroscope: Stream.empty(),
          accelerometer: Stream.empty(),
        ),
      ),
    );

    await tester.tap(find.text('Square'));
    await tester.pump();
    final segmented = tester.widget<SegmentedButton<Waveform>>(
      find.byType(SegmentedButton<Waveform>),
    );
    expect(segmented.selected, {Waveform.square});

    await tester.drag(find.byType(Slider), const Offset(-1000, 0));
    await tester.pump();
    expect(find.text('110 Hz'), findsOneWidget);
  });
}
