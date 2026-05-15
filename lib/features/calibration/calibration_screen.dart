import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../game/game_screen.dart';
import '../scan/scanned_area_model.dart';
import 'swing_profile_model.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key, required this.playArea});

  final ScannedArea playArea;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  SwingProfile _profile = SwingProfile.demo();

  void _startMatch() {
    Navigator.pushNamed(
      context,
      AppRoutes.game,
      arguments: GameScreenArgs(
        playArea: widget.playArea,
        swingProfile: _profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calibrate your swing',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Set a baseline hit threshold and a stronger smash threshold so the motion paddle logic has clean starting values.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scanned area',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('Width: ${widget.playArea.widthLabel}'),
                    Text('Length: ${widget.playArea.lengthLabel}'),
                    Text(
                      'Hit zone: ${widget.playArea.hitZone.toStringAsFixed(2)} m',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dominant hand',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: DominantHand.values.map((hand) {
                        final selected = _profile.dominantHand == hand;
                        return ChoiceChip(
                          label: Text(
                            hand == DominantHand.left ? 'Left' : 'Right',
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _profile = _profile.copyWith(dominantHand: hand);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _CalibrationSlider(
                      label: 'Normal swing threshold',
                      value: _profile.hitThreshold,
                      min: 2,
                      max: 8,
                      onChanged: (value) {
                        setState(() {
                          _profile = _profile.copyWith(hitThreshold: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _CalibrationSlider(
                      label: 'Smash threshold',
                      value: _profile.smashThreshold,
                      min: 5,
                      max: 12,
                      onChanged: (value) {
                        setState(() {
                          _profile = _profile.copyWith(smashThreshold: value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _CalibrationSlider(
                      label: 'Swing sensitivity',
                      value: _profile.sensitivity,
                      min: 0.2,
                      max: 1,
                      onChanged: (value) {
                        setState(() {
                          _profile = _profile.copyWith(sensitivity: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _startMatch,
              child: const Text('Start match'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalibrationSlider extends StatelessWidget {
  const _CalibrationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
