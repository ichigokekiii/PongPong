import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

/// Swing-strength calibration UI. Sensor logic is Member 3's job — this only
/// shows the guided flow + UI mock for normal / smash thresholds.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _normalDone = false;
  bool _smashDone = false;
  double _sensitivity = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MarioColors.luigiGreen,
      appBar: AppBar(
        backgroundColor: MarioColors.luigiGreen,
        foregroundColor: MarioColors.cloudWhite,
        title: const Text('CALIBRATION'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                label: 'TUNE YOUR PADDLE',
                title: 'Show us your\nswing!',
                titleColor: MarioColors.cloudWhite,
              ),
              const SizedBox(height: MarioSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _CalibTile(
                        icon: Icons.sports_tennis_rounded,
                        title: 'Normal swing',
                        body: 'Swing the phone like you would for a regular hit.',
                        done: _normalDone,
                        a11y: widget.a11y,
                        onCapture: () => setState(() => _normalDone = true),
                      ),
                      const SizedBox(height: MarioSpacing.sm),
                      _CalibTile(
                        icon: Icons.bolt_rounded,
                        title: 'Smash swing',
                        body: 'Now swing HARD. Like a Bowser-launching power-up.',
                        done: _smashDone,
                        a11y: widget.a11y,
                        onCapture: () => setState(() => _smashDone = true),
                      ),
                      const SizedBox(height: MarioSpacing.sm),
                      MarioBlockCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sensitivity', style: t.titleMedium),
                            const SizedBox(height: MarioSpacing.xxs),
                            Text(
                              _sensitivity < 0.34
                                  ? 'Easy-going · big window'
                                  : _sensitivity < 0.67
                                      ? 'Standard · balanced'
                                      : 'Hardcore · sharper window',
                              style: t.bodyMedium,
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: MarioColors.marioRed,
                                inactiveTrackColor: MarioColors.bowserBlack
                                    .withValues(alpha: 0.15),
                                thumbColor: MarioColors.marioRed,
                                overlayColor: MarioColors.marioRed
                                    .withValues(alpha: 0.2),
                                trackHeight: 8,
                              ),
                              child: Slider(
                                value: _sensitivity,
                                onChanged: (v) =>
                                    setState(() => _sensitivity = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MarioSpacing.sm),
                      _HandednessSelector(a11y: widget.a11y),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MarioSpacing.sm),
              MarioButton(
                a11y: widget.a11y,
                label: _normalDone && _smashDone
                    ? 'START THE RALLY'
                    : 'COMPLETE BOTH SWINGS',
                icon: const Icon(Icons.play_arrow_rounded),
                expand: true,
                color: MarioColors.marioRed,
                onPressed: _normalDone && _smashDone
                    ? () => Navigator.pushReplacementNamed(context, Routes.game)
                    : null,
              ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibTile extends StatelessWidget {
  const _CalibTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.a11y,
    required this.onCapture,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool done;
  final A11yController a11y;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MarioBlockCard(
      background: done ? MarioColors.coin : MarioColors.cloudWhite,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(MarioSpacing.sm),
            decoration: BoxDecoration(
              color: done ? MarioColors.pipe : MarioColors.marioRed,
              borderRadius: BorderRadius.circular(MarioRadius.md),
              border: Border.all(color: MarioColors.bowserBlack, width: 2),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: MarioColors.cloudWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: MarioSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: t.bodyMedium),
                const SizedBox(height: MarioSpacing.xs),
                MarioButton(
                  a11y: a11y,
                  label: done ? 'RE-CAPTURE' : 'CAPTURE',
                  compact: true,
                  color: done ? MarioColors.marioBlue : MarioColors.marioRed,
                  onPressed: onCapture,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandednessSelector extends StatelessWidget {
  const _HandednessSelector({required this.a11y});
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: a11y,
      builder: (context, _) {
        return MarioBlockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Handedness', style: t.titleMedium),
              const SizedBox(height: MarioSpacing.xxs),
              Text(
                'Mirrors HUD controls for comfortable one-handed play.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: MarioSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _HandChip(
                      label: 'LEFT',
                      selected: a11y.handedness == Handedness.left,
                      onTap: () => a11y.setHandedness(Handedness.left),
                    ),
                  ),
                  const SizedBox(width: MarioSpacing.xs),
                  Expanded(
                    child: _HandChip(
                      label: 'RIGHT',
                      selected: a11y.handedness == Handedness.right,
                      onTap: () => a11y.setHandedness(Handedness.right),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HandChip extends StatelessWidget {
  const _HandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? MarioColors.marioRed : MarioColors.cloudWhite,
          borderRadius: BorderRadius.circular(MarioRadius.md),
          border: Border.all(color: MarioColors.bowserBlack, width: 2.5),
        ),
        child: Text(
          label,
          style: t.labelLarge?.copyWith(
            color: selected ? MarioColors.cloudWhite : MarioColors.bowserBlack,
          ),
        ),
      ),
    );
  }
}
