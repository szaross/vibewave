import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sine_player.dart';

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

  final SinePlayer _sine = SinePlayer();
  late final AppLifecycleListener _lifecycle;
  bool _isTestBusy = false;

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
    _lifecycle = AppLifecycleListener(onPause: _stopTest);
  }

  Future<void> _toggleTest() async {
    setState(() => _isTestBusy = true);
    try {
      if (_sine.isPlaying) {
        await _sine.stop();
      } else {
        await _sine.start(frequency: 440);
      }
    } finally {
      if (mounted) setState(() => _isTestBusy = false);
    }
  }

  Future<void> _stopTest() async {
    await _sine.stop();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _sine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _sine.isPlaying;
    return Scaffold(
      appBar: AppBar(title: const Text('VibeWave')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isPlaying ? 'Playing 440 Hz sine' : 'Test tone',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isTestBusy ? null : _toggleTest,
                    icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      isPlaying ? 'Stop test' : 'Start test (440 Hz)',
                    ),
                  ),
                ],
              ),
            ),
          ),
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
