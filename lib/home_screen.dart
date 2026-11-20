import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibewave/audio/synth_player.dart';

import 'widgets/synth_card.dart';

typedef Vector3 = ({double x, double y, double z});

bool get _sensorsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.gyroscope, this.accelerometer});

  final Stream<GyroscopeEvent>? gyroscope;
  final Stream<AccelerometerEvent>? accelerometer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SynthPlayer _player = SynthPlayer();

  Stream<Vector3>? _gyroscope;
  Stream<Vector3>? _accelerometer;

  StreamSubscription<Vector3>? _accelSub;
  StreamSubscription<Vector3>? _gyroSub;

  double _smoothTiltY = 0.0;
  double _smoothGyroEnergy = 0.0;

  @override
  void initState() {
    super.initState();
    final gyroscope =
        widget.gyroscope ??
        (_sensorsSupported
            ? gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
            : null);
    final accelerometer =
        widget.accelerometer ??
        (_sensorsSupported
            ? accelerometerEventStream(
                samplingPeriod: SensorInterval.gameInterval,
              )
            : null);

    _gyroscope = gyroscope
        ?.map((e) => (x: e.x, y: e.y, z: e.z))
        .asBroadcastStream();
    _accelerometer = accelerometer
        ?.map((e) => (x: e.x, y: e.y, z: e.z))
        .asBroadcastStream();

    _startSensorAudioMapping();
  }

  void _startSensorAudioMapping() {
    _accelSub = _accelerometer?.listen((accel) {
      _smoothTiltY = _smoothTiltY * 0.8 + accel.y * 0.2;

      final normalized = ((_smoothTiltY + 9.8) / 19.6).clamp(0.0, 1.0);
      const minFreq = 110.0; // A2
      const maxFreq = 880.0; // A5
      final freq = minFreq * math.pow(maxFreq / minFreq, normalized);

      if (_player.isPlaying) {
        _player.setFrequency(freq.toDouble());
      }
    });

    _gyroSub = _gyroscope?.listen((gyro) {
      final energy = math.sqrt(
        gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z,
      );
      _smoothGyroEnergy = _smoothGyroEnergy * 0.85 + energy * 0.15;

      if (_player.isPlaying) {
        final modDepth = ((_smoothGyroEnergy - 0.3) / 3.7).clamp(0.0, 1.0);
        _player.setModulation(modDepth);
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VibeWave')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SynthCard(player: _player),
          const SizedBox(height: 16),
          _SensorCard(title: 'Gyroscope', unit: 'rad/s', stream: _gyroscope),
          const SizedBox(height: 16),
          _SensorCard(
            title: 'Accelerometer',
            unit: 'm/s²',
            stream: _accelerometer,
          ),
        ],
      ),
    );
  }
}
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.unit,
    required this.stream,
  });

  final String title;
  final String unit;
  final Stream<Vector3>? stream;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title ($unit)', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            if (stream == null)
              const Text('Sensors not available on this platform')
            else
              StreamBuilder<Vector3>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Sensor not available on this device');
                  }
                  final value = snapshot.data;
                  if (value == null) return const Text('Waiting for data…');
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Axis(label: 'x', value: value.x),
                      _Axis(label: 'y', value: value.y),
                      _Axis(label: 'z', value: value.z),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Axis extends StatelessWidget {
  const _Axis({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: textTheme.labelLarge),
        Text(
          value.toStringAsFixed(2),
          style: textTheme.headlineSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
