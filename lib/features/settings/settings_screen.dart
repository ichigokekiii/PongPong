import 'package:flutter/material.dart';

import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarioColors.sky,
      appBar: AppBar(title: const Text('SETTINGS')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: a11y,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(MarioSpacing.md),
              children: [
                const SectionHeader(
                  label: 'PREFERENCES',
                  title: 'Make it yours',
                ),
                const SizedBox(height: MarioSpacing.md),
                MarioBlockCard(
                  child: Column(
                    children: [
                      _SettingSwitch(
                        title: 'High contrast',
                        subtitle:
                            'Boosts outlines and removes translucent layers.',
                        value: a11y.highContrast,
                        onChanged: a11y.setHighContrast,
                      ),
                      _Divider(),
                      _SettingSwitch(
                        title: 'Larger touch targets',
                        subtitle:
                            'Buttons grow to 54 pt for confident one-handed taps.',
                        value: a11y.largerTargets,
                        onChanged: a11y.setLargerTargets,
                      ),
                      _Divider(),
                      _SettingSwitch(
                        title: 'Reduced motion',
                        subtitle:
                            'Disables blinks and pulses. State colors still change.',
                        value: a11y.reducedMotion,
                        onChanged: a11y.setReducedMotion,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MarioSpacing.md),
                MarioBlockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handedness',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: MarioSpacing.xxs),
                      Text(
                        'Mirrors HUD chips & demo controls to your dominant hand.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: MarioSpacing.xs),
                      SegmentedButton<Handedness>(
                        segments: const [
                          ButtonSegment(
                            value: Handedness.left,
                            label: Text('LEFT'),
                            icon: Icon(Icons.back_hand_rounded),
                          ),
                          ButtonSegment(
                            value: Handedness.right,
                            label: Text('RIGHT'),
                            icon: Icon(Icons.front_hand_rounded),
                          ),
                        ],
                        selected: {a11y.handedness},
                        onSelectionChanged: (s) => a11y.setHandedness(s.first),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeColor: MarioColors.cloudWhite,
      activeTrackColor: MarioColors.pipe,
      inactiveTrackColor:
          MarioColors.bowserBlack.withValues(alpha: 0.18),
      title: Text(title, style: t.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: t.bodyMedium),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: MarioSpacing.xxs),
      color: MarioColors.bowserBlack.withValues(alpha: 0.12),
    );
  }
}
