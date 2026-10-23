import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibewave/sensor_screen.dart';

void main() {
  testWidgets('SensorScreen renders title and sensor cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SensorScreen(
          gyroscope: Stream.empty(),
          accelerometer: Stream.empty(),
        ),
      ),
    );

    expect(find.text('VibeWave'), findsOneWidget);
    expect(find.textContaining('Gyroscope'), findsOneWidget);
    expect(find.textContaining('Accelerometer'), findsOneWidget);
  });
}
