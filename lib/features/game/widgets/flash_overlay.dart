import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../theme/mario_theme.dart';
import '../models/game_state_models.dart';

/// Full-screen sharp flash drawn over the play area on hit / smash / miss.
///
/// Implements the "sharp arcade" preference: hard color cut, ~160 ms total.
class FlashOverlay extends StatelessWidget {
  const FlashOverlay({
    super.key,
    required this.event,
    required this.a11y,
  });

  final SwingEvent event;
  final A11yController a11y;

  Color? get _color => switch (event) {
        SwingEvent.hit => MarioColors.hitFlash,
        SwingEvent.smash => MarioColors.smashFlash,
        SwingEvent.miss => MarioColors.missFlash,
        SwingEvent.none => null,
      };

  String? get _label => switch (event) {
        SwingEvent.hit => 'HIT!',
        SwingEvent.smash => 'SMASH!!',
        SwingEvent.miss => 'MISS',
        SwingEvent.none => null,
      };

  @override
  Widget build(BuildContext context) {
    final c = _color;
    if (c == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: a11y.reducedMotion
            ? Duration.zero
            : MarioMotion.flash,
        opacity: 1,
        child: Container(
          color: c.withValues(alpha: 0.85),
          alignment: Alignment.center,
          child: Text(
            _label ?? '',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: event == SwingEvent.smash
                      ? MarioColors.bowserBlack
                      : MarioColors.bowserBlack,
                  fontSize: 36,
                  letterSpacing: 2,
                ),
          ),
        ),
      ),
    );
  }
}
