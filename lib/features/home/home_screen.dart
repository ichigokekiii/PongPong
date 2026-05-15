import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/painters/coin_painter.dart';
import '../../core/painters/paddle_painter.dart';
import '../../core/painters/question_block_painter.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../theme/mario_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: MarioColors.sky,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MarioSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHONE',
                          style: t.displayLarge?.copyWith(
                            color: MarioColors.marioRed,
                            height: 1,
                          ),
                        ),
                        Text(
                          'PONG',
                          style: t.displayLarge?.copyWith(
                            color: MarioColors.luigiGreen,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Open settings',
                    button: true,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.settings),
                      child: const QuestionBlockIcon(size: 56),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MarioSpacing.xs),
              Text(
                'Phone-as-paddle table tennis.\nNo table. No ball. Just motion.',
                style: t.bodyLarge?.copyWith(height: 1.4),
              ),
              const Spacer(),
              Center(
                child: Hero(
                  tag: 'home-paddle',
                  child: PaddleIcon(size: mq.size.width * 0.55),
                ),
              ),
              const Spacer(),
              MarioBlockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MarioButton(
                      a11y: a11y,
                      label: 'START GAME',
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      expand: true,
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.safety),
                    ),
                    const SizedBox(height: MarioSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: MarioButton(
                            a11y: a11y,
                            label: 'CALIBRATE',
                            color: MarioColors.marioBlue,
                            icon: const Icon(Icons.tune_rounded, size: 22),
                            expand: true,
                            compact: true,
                            onPressed: () => Navigator.pushNamed(
                                context, Routes.calibration),
                          ),
                        ),
                        const SizedBox(width: MarioSpacing.xs),
                        Expanded(
                          child: MarioButton(
                            a11y: a11y,
                            label: 'HOW TO',
                            color: MarioColors.coin,
                            foregroundColor: MarioColors.bowserBlack,
                            icon: const Icon(Icons.menu_book_rounded, size: 22),
                            expand: true,
                            compact: true,
                            onPressed: () => _showHowTo(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MarioSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 18),
                  const SizedBox(width: MarioSpacing.xs),
                  Text(
                    'HACKATHON MVP · v0.1',
                    style: t.labelMedium?.copyWith(
                      letterSpacing: 1.3,
                      color: MarioColors.bowserBlack.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final t = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: MarioBlockCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW TO PLAY', style: t.headlineMedium),
                const SizedBox(height: MarioSpacing.sm),
                _Tip(emoji: '1.', text: 'Scan your play area with the camera.'),
                _Tip(emoji: '2.', text: 'Calibrate your swing strength.'),
                _Tip(
                  emoji: '3.',
                  text: 'Watch screen color: RED far, YELLOW near, GREEN swing!',
                ),
                _Tip(
                  emoji: '4.',
                  text: 'Hard swing on GREEN = SMASH for bonus points.',
                ),
                const SizedBox(height: MarioSpacing.sm),
                MarioButton(
                  a11y: a11y,
                  label: 'GOT IT',
                  expand: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MarioSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              emoji,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
