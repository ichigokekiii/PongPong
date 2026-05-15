import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../core/painters/coin_painter.dart';
import '../../../core/widgets/mario_chip.dart';
import '../../../theme/mario_theme.dart';
import '../game_controller.dart';

/// Top HUD: pause button on the leading side, SCORE + RALLY chips trailing.
///
/// Mirrors to the right when the user picks left-handed mode (Mario coin
/// always sits closest to the user's grip hand for one-handed glanceability).
class ScoreHud extends StatelessWidget {
  const ScoreHud({
    super.key,
    required this.controller,
    required this.a11y,
    required this.onPause,
    required this.onOpenDemo,
  });

  final GameController controller;
  final A11yController a11y;
  final VoidCallback onPause;
  final VoidCallback onOpenDemo;

  @override
  Widget build(BuildContext context) {
    final chips = ValueListenableBuilder<int>(
      valueListenable: controller.score,
      builder: (context, score, _) {
        return ValueListenableBuilder<int>(
          valueListenable: controller.rally,
          builder: (context, rally, __) {
            return Wrap(
              spacing: MarioSpacing.xs,
              runSpacing: MarioSpacing.xs,
              children: [
                MarioChip(
                  label: 'SCORE',
                  value: '$score',
                  color: MarioColors.coin,
                  icon: const CoinIcon(size: 18),
                ),
                MarioChip(
                  label: 'RALLY',
                  value: '$rally',
                  color: MarioColors.cloudWhite,
                ),
              ],
            );
          },
        );
      },
    );

    final pauseBtn = _SquareButton(
      icon: Icons.pause_rounded,
      label: 'Pause',
      a11y: a11y,
      onTap: onPause,
    );
    final demoBtn = _SquareButton(
      icon: Icons.tune_rounded,
      label: 'Demo controls',
      a11y: a11y,
      onTap: onOpenDemo,
      color: MarioColors.marioBlue,
    );

    final leading = a11y.mirrorForLeftHand
        ? <Widget>[demoBtn, const SizedBox(width: MarioSpacing.xs), Expanded(child: chips), pauseBtn]
        : <Widget>[pauseBtn, const SizedBox(width: MarioSpacing.xs), Expanded(child: chips), demoBtn];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: leading,
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.label,
    required this.a11y,
    required this.onTap,
    this.color = MarioColors.cloudWhite,
  });

  final IconData icon;
  final String label;
  final A11yController a11y;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = a11y.minTapTarget;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(MarioRadius.md),
            border: Border.all(color: MarioColors.bowserBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: MarioColors.bowserBlack,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color == MarioColors.cloudWhite
                ? MarioColors.bowserBlack
                : MarioColors.cloudWhite,
            size: 24,
          ),
        ),
      ),
    );
  }
}
