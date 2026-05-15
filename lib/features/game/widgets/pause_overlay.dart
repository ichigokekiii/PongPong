import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/accessibility/a11y_controller.dart';
import '../../../core/widgets/mario_block_card.dart';
import '../../../core/widgets/mario_button.dart';
import '../../../theme/mario_theme.dart';

/// Dimmed pause sheet — appears centered over the game when status is paused.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.a11y,
    required this.onResume,
    required this.onQuit,
  });

  final A11yController a11y;
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      color: MarioColors.bowserBlack.withValues(alpha: 0.55),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: MarioSpacing.md),
      child: MarioBlockCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_rounded,
                size: 64, color: MarioColors.marioRed),
            const SizedBox(height: MarioSpacing.xs),
            Text('PAUSED', style: t.headlineLarge),
            const SizedBox(height: MarioSpacing.xs),
            Text(
              'Catch your breath, champion.',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MarioSpacing.md),
            MarioButton(
              a11y: a11y,
              label: 'RESUME',
              icon: const Icon(Icons.play_arrow_rounded),
              expand: true,
              color: MarioColors.pipe,
              onPressed: onResume,
            ),
            const SizedBox(height: MarioSpacing.xs),
            MarioButton(
              a11y: a11y,
              label: 'QUIT TO HOME',
              icon: const Icon(Icons.home_rounded),
              expand: true,
              color: MarioColors.cloudWhite,
              foregroundColor: MarioColors.bowserBlack,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (_) => false,
                );
                onQuit();
              },
            ),
          ],
        ),
      ),
    );
  }
}
