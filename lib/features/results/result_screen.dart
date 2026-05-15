import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/painters/coin_painter.dart';
import '../../core/painters/paddle_painter.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

/// Game-over summary route arguments.
class ResultArgs {
  const ResultArgs({
    required this.score,
    required this.longestRally,
    required this.hits,
    required this.smashes,
    required this.accuracy,
  });

  const ResultArgs.empty()
      : score = 0,
        longestRally = 0,
        hits = 0,
        smashes = 0,
        accuracy = 0.0;

  final int score;
  final int longestRally;
  final int hits;
  final int smashes;
  final double accuracy;
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.a11y, required this.args});

  final A11yController a11y;
  final ResultArgs args;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: MarioColors.marioRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MarioSpacing.sm),
              const SectionHeader(
                label: 'GAME OVER',
                title: 'Nice rally,\nchamp!',
                titleColor: MarioColors.cloudWhite,
              ),
              const SizedBox(height: MarioSpacing.md),
              Center(
                child: Hero(
                  tag: 'home-paddle',
                  child: PaddleIcon(size: mq.size.width * 0.36),
                ),
              ),
              const SizedBox(height: MarioSpacing.md),
              MarioBlockCard(
                background: MarioColors.coin,
                child: Row(
                  children: [
                    const CoinIcon(size: 36),
                    const SizedBox(width: MarioSpacing.sm),
                    Text(
                      'SCORE',
                      style: t.labelLarge?.copyWith(letterSpacing: 1.6),
                    ),
                    const Spacer(),
                    Text(
                      '${args.score}',
                      style: t.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MarioSpacing.sm),
              MarioBlockCard(
                child: Column(
                  children: [
                    _StatRow(label: 'Longest rally', value: '${args.longestRally}'),
                    _StatRow(label: 'Hits', value: '${args.hits}'),
                    _StatRow(label: 'Smashes', value: '${args.smashes}'),
                    _StatRow(
                      label: 'Accuracy',
                      value: '${(args.accuracy * 100).round()}%',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              MarioButton(
                a11y: a11y,
                label: 'PLAY AGAIN',
                icon: const Icon(Icons.replay_rounded),
                expand: true,
                color: MarioColors.pipe,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, Routes.game),
              ),
              const SizedBox(height: MarioSpacing.xs),
              MarioButton(
                a11y: a11y,
                label: 'HOME',
                icon: const Icon(Icons.home_rounded),
                expand: true,
                color: MarioColors.cloudWhite,
                foregroundColor: MarioColors.bowserBlack,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.home,
                  (_) => false,
                ),
              ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MarioSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: t.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: MarioColors.bowserBlack.withValues(alpha: 0.55),
              ),
            ),
          ),
          Text(
            value,
            style: t.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
