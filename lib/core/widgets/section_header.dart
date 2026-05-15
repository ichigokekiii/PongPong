import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Small de-emphasized label above a large bold title — applies the
/// label-over-value hierarchy pattern (Refactoring UI).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    required this.title,
    this.titleColor,
  });

  final String label;
  final String title;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.labelMedium?.copyWith(
            color: MarioColors.bowserBlack.withValues(alpha: 0.55),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: MarioSpacing.xxs),
        Text(
          title,
          style: t.headlineMedium?.copyWith(color: titleColor),
        ),
      ],
    );
  }
}
