import 'package:material_ui/material_ui.dart';

import 'home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const VibeWaveApp());
}

class VibeWaveApp extends StatelessWidget {
  const VibeWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeWave',
      theme: vibeWaveTheme,
      home: const HomeScreen(),
    );
  }
}
