import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Pill chip used in HUDs (score, rally, etc.). Black outline, tight padding.
class MarioChip extends StatelessWidget {
  const MarioChip({
    super.key,
    required this.label,
    required this.value,
    this.color = MarioColors.cloudWhite,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MarioSpacing.sm,
        vertical: MarioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MarioRadius.pill),
        border: Border.all(color: MarioColors.bowserBlack, width: 3),
        boxShadow: const [
          BoxShadow(
            color: MarioColors.bowserBlack,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: MarioSpacing.xs),
          ],
          Text(
            '$label  ',
            style: t.labelMedium?.copyWith(
              color: MarioColors.bowserBlack.withValues(alpha: 0.55),
              letterSpacing: 1.1,
            ),
          ),
          Text(
            value,
            style: t.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
