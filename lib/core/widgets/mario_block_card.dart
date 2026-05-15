import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// White card with the signature Mario thick black outline + hard shadow.
///
/// Use to group related information without competing with primary CTAs.
class MarioBlockCard extends StatelessWidget {
  const MarioBlockCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MarioSpacing.md),
    this.background = MarioColors.cloudWhite,
    this.outline = MarioColors.bowserBlack,
    this.outlineWidth = 3,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color outline;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MarioRadius.lg),
        border: Border.all(color: outline, width: outlineWidth),
        boxShadow: const [
          BoxShadow(
            color: MarioColors.bowserBlack,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
