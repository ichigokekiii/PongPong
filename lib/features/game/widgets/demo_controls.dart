import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../core/widgets/mario_block_card.dart';
import '../../../core/widgets/mario_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../theme/mario_theme.dart';
import '../game_controller.dart';
import '../models/game_state_models.dart';

/// Bottom-sheet panel that lets the hackathon presenter drive every visual
/// state of the game without real sensors.
///
/// Lives outside the game's render path so opening / closing it is cheap and
/// the underlying game state keeps reacting in real time.
class DemoControls extends StatelessWidget {
  const DemoControls({
    super.key,
    required this.controller,
    required this.a11y,
    required this.onEndRally,
  });

  final GameController controller;
  final A11yController a11y;
  final VoidCallback onEndRally;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(MarioSpacing.md),
        child: SingleChildScrollView(
          child: MarioBlockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  label: 'HACKATHON DEMO',
                  title: 'Mock controls',
                ),
                const SizedBox(height: MarioSpacing.sm),
                _BallStateRow(controller: controller, a11y: a11y),
                const SizedBox(height: MarioSpacing.sm),
                _EdgeRow(controller: controller, a11y: a11y),
                const SizedBox(height: MarioSpacing.sm),
                _SpeedRow(controller: controller, a11y: a11y),
                const SizedBox(height: MarioSpacing.sm),
                _OutcomeRow(
                  controller: controller,
                  a11y: a11y,
                  onMiss: onEndRally,
                ),
                const SizedBox(height: MarioSpacing.sm),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Close panel'),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BallStateRow extends StatelessWidget {
  const _BallStateRow({required this.controller, required this.a11y});
  final GameController controller;
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BallState>(
      valueListenable: controller.ballState,
      builder: (context, current, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('BALL STATE', context),
            const SizedBox(height: MarioSpacing.xxs),
            Row(
              children: [
                Expanded(
                  child: _toggleBtn(
                    'FAR',
                    MarioColors.marioRed,
                    current == BallState.far,
                    () => controller.setBallState(BallState.far),
                    a11y,
                  ),
                ),
                const SizedBox(width: MarioSpacing.xs),
                Expanded(
                  child: _toggleBtn(
                    'NEAR',
                    MarioColors.coin,
                    current == BallState.near,
                    () => controller.setBallState(BallState.near),
                    a11y,
                    fg: MarioColors.bowserBlack,
                  ),
                ),
                const SizedBox(width: MarioSpacing.xs),
                Expanded(
                  child: _toggleBtn(
                    'READY',
                    MarioColors.pipe,
                    current == BallState.ready,
                    () => controller.setBallState(BallState.ready),
                    a11y,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EdgeRow extends StatelessWidget {
  const _EdgeRow({required this.controller, required this.a11y});
  final GameController controller;
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BallEdge>(
      valueListenable: controller.ballEdge,
      builder: (context, current, _) {
        Widget btn(String label, IconData icon, BallEdge edge) {
          return Expanded(
            child: MarioButton(
              a11y: a11y,
              label: label,
              icon: Icon(icon, size: 18),
              compact: true,
              expand: true,
              color: current == edge
                  ? MarioColors.marioBlue
                  : MarioColors.cloudWhite,
              foregroundColor: current == edge
                  ? MarioColors.cloudWhite
                  : MarioColors.bowserBlack,
              onPressed: () => controller.setBallEdge(edge),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('BALL DIRECTION', context),
            const SizedBox(height: MarioSpacing.xxs),
            Row(
              children: [
                btn('LEFT', Icons.arrow_back_rounded, BallEdge.left),
                const SizedBox(width: MarioSpacing.xs),
                btn('TOP', Icons.arrow_upward_rounded, BallEdge.top),
                const SizedBox(width: MarioSpacing.xs),
                btn('RIGHT', Icons.arrow_forward_rounded, BallEdge.right),
              ],
            ),
            const SizedBox(height: MarioSpacing.xs),
            Row(
              children: [
                btn('BOTTOM', Icons.arrow_downward_rounded, BallEdge.bottom),
                const SizedBox(width: MarioSpacing.xs),
                btn('CENTER', Icons.adjust_rounded, BallEdge.center),
                const SizedBox(width: MarioSpacing.xs),
                const Spacer(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.controller, required this.a11y});
  final GameController controller;
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BallSpeed>(
      valueListenable: controller.speed,
      builder: (context, current, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('BALL SPEED', context),
            const SizedBox(height: MarioSpacing.xxs),
            Row(
              children: [
                for (final s in BallSpeed.values) ...[
                  Expanded(
                    child: _toggleBtn(
                      s.name.toUpperCase(),
                      MarioColors.marioBlue,
                      current == s,
                      () => controller.setSpeed(s),
                      a11y,
                    ),
                  ),
                  if (s != BallSpeed.values.last)
                    const SizedBox(width: MarioSpacing.xs),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.controller,
    required this.a11y,
    required this.onMiss,
  });
  final GameController controller;
  final A11yController a11y;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('OUTCOME', context),
        const SizedBox(height: MarioSpacing.xxs),
        Row(
          children: [
            Expanded(
              child: MarioButton(
                a11y: a11y,
                label: 'HIT +1',
                icon: const Icon(Icons.sports_tennis_rounded, size: 18),
                expand: true,
                color: MarioColors.pipe,
                onPressed: controller.registerHit,
              ),
            ),
            const SizedBox(width: MarioSpacing.xs),
            Expanded(
              child: MarioButton(
                a11y: a11y,
                label: 'SMASH +3',
                icon: const Icon(Icons.bolt_rounded, size: 18),
                expand: true,
                color: MarioColors.coin,
                foregroundColor: MarioColors.bowserBlack,
                onPressed: controller.registerSmash,
              ),
            ),
            const SizedBox(width: MarioSpacing.xs),
            Expanded(
              child: MarioButton(
                a11y: a11y,
                label: 'MISS',
                icon: const Icon(Icons.cancel_rounded, size: 18),
                expand: true,
                color: MarioColors.marioRed,
                onPressed: () {
                  controller.registerMiss();
                  onMiss();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _label(String text, BuildContext context) {
  return Text(
    text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: MarioColors.bowserBlack.withValues(alpha: 0.55),
          letterSpacing: 1.3,
        ),
  );
}

Widget _toggleBtn(
  String label,
  Color color,
  bool selected,
  VoidCallback onTap,
  A11yController a11y, {
  Color fg = MarioColors.cloudWhite,
}) {
  return MarioButton(
    a11y: a11y,
    label: label,
    compact: true,
    expand: true,
    color: selected ? color : MarioColors.cloudWhite,
    foregroundColor: selected ? fg : MarioColors.bowserBlack,
    onPressed: onTap,
  );
}
