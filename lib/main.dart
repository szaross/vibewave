import 'package:flutter/material.dart';

import 'sensor_screen.dart';

void main() {
  runApp(const VibeWaveApp());
}

class VibeWaveApp extends StatelessWidget {
  const VibeWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeWave',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const SensorScreen(),
    );
  }
}
