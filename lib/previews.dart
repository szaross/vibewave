import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'home_screen.dart';
import 'theme.dart';
import 'widgets/synth_card.dart';

Widget vibeWaveThemed(Widget child) => Theme(data: vibeWaveTheme, child: child);

@Preview(
  group: 'Home',
  name: 'Sample sensor data',
  size: Size(400, 800),
  wrapper: vibeWaveThemed,
)
Widget homeScreenPreview() => HomeScreen(
  gyroscope: Stream.value(GyroscopeEvent(0.12, -0.05, 0.31, DateTime(2026))),
  accelerometer: Stream.value(
    AccelerometerEvent(0.42, 9.71, 1.18, DateTime(2026)),
  ),
);

@Preview(
  group: 'Home',
  name: 'No sensors',
  size: Size(400, 800),
  wrapper: vibeWaveThemed,
)
Widget homeScreenNoSensorsPreview() => const HomeScreen();

@Preview(
  group: 'Synth',
  name: 'Synth card',
  size: Size.fromWidth(400),
  wrapper: vibeWaveThemed,
)
Widget synthCardPreview() => const SynthCard();
