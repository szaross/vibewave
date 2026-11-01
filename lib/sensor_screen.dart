import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'player.dart';

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

  final SoundPlayer _soundPlayer = SoundPlayer();
  StreamSubscription<Vector3>? _accelSubscription;
  
  bool _isAudioEnabled = false;
  double _currentFrequency = 440.0;

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
    Future<void> _initAudio() async {
    await _soundPlayer.init();
    }
    _initAudio();
    _gyroscope = gyroscope?.map((e) => (x: e.x, y: e.y, z: e.z));
    DateTime _lastPlayTime = DateTime.now();

    _accelSubscription = _accelerometer?.listen((data) {
      if (!_isAudioEnabled) return;

      final now = DateTime.now();
      if (now.difference(_lastPlayTime).inMilliseconds < 100) return;

      final clampedY = data.y.clamp(-10.0, 10.0);
      final normalized = (clampedY + 10.0) / 20.0;
      final newFreq = 150.0 + (normalized * 850.0);

      if ((newFreq - _currentFrequency).abs() > 15.0) {
        _currentFrequency = newFreq;
        _lastPlayTime = now;

        _soundPlayer.playTone(
          frequency: _currentFrequency,
          durationSeconds: 0.1,
          waveType: WaveType.sine,
        );
      }
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeWave Synth'),
        actions: [
          IconButton(
            icon: Icon(_isAudioEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _isAudioEnabled = !_isAudioEnabled;
              });
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _isAudioEnabled ? Colors.indigo.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isAudioEnabled
                        ? 'Częstotliwość: ${_currentFrequency.round()} Hz'
                        : 'Włącz dźwięk ikoną w prawym górnym rogu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _soundPlayer.playTone(
                        frequency: 440,
                        durationSeconds: 0.5,
                      );
                    },
                    child: const Text('Test (440Hz)'),
                  )
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
