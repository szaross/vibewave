import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef Vector3 = ({double x, double y, double z});

bool get _sensorsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key, this.gyroscope, this.accelerometer});

  final Stream<GyroscopeEvent>? gyroscope;
  final Stream<AccelerometerEvent>? accelerometer;

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  Stream<Vector3>? _gyroscope;
  Stream<Vector3>? _accelerometer;

  @override
  void initState() {
    super.initState();
    final gyroscope =
        widget.gyroscope ??
        (_sensorsSupported
            ? gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
            : null);
    final accelerometer =
        widget.accelerometer ??
        (_sensorsSupported
            ? accelerometerEventStream(
                samplingPeriod: SensorInterval.uiInterval,
              )
            : null);
    _gyroscope = gyroscope?.map((e) => (x: e.x, y: e.y, z: e.z));
    _accelerometer = accelerometer?.map((e) => (x: e.x, y: e.y, z: e.z));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VibeWave')),
      body: ListView(
        padding: const EdgeInsetsSensorScreen.all(16),
        children: [
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
