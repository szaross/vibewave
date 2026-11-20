import 'package:material_ui/material_ui.dart';

import '../audio/frequency_scale.dart';
import '../audio/synth_player.dart';
import '../audio/waveform.dart';

class SynthCard extends StatefulWidget {
  const SynthCard({super.key, required this.player});

  final SynthPlayer player;

  @override
  State<SynthCard> createState() => _SynthCardState();
}

class _SynthCardState extends State<SynthCard> {
  late final AppLifecycleListener _lifecycle;
  bool _isBusy = false;

  SynthPlayer get _player => widget.player;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onPause: _stop);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    setState(() => _isBusy = true);
    try {
      if (_player.isPlaying) {
        await _player.stop();
      } else {
        await _player.start();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _player,
      builder: (context, _) {
        final isPlaying = _player.isPlaying;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Synth', style: textTheme.titleMedium),
                    ),
                    FilledButton.icon(
                      onPressed: _isBusy ? null : _toggle,
                      icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(isPlaying ? 'Stop' : 'Start'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<Waveform>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    for (final waveform in Waveform.values)
                      ButtonSegment(
                        value: waveform,
                        label: Text(waveform.label),
                      ),
                  ],
                  selected: {_player.waveform},
                  onSelectionChanged: (selection) =>
                      _player.setWaveform(selection.single),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Frequency', style: textTheme.labelLarge),
                    ),
                    Text(
                      '${_player.frequency.round()} Hz',
                      style: textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: sliderFromFrequency(_player.frequency).clamp(0.0, 1.0),
                  onChanged: (position) =>
                      _player.setFrequency(frequencyFromSlider(position)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Modulation (Gyro)',
                        style: textTheme.labelLarge,
                      ),
                    ),
                    Text(
                      '${(_player.modulation * 100).round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _player.modulation),
              ],
            ),
          ),
        );
      },
    );
  }
}