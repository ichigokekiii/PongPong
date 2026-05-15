import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../calibration/swing_profile_model.dart';
import '../game/game_models.dart';
import '../game/game_screen.dart';
import '../scan/scanned_area_model.dart';

class ResultScreenArgs {
  const ResultScreenArgs({
    required this.result,
    required this.playArea,
    required this.swingProfile,
  });

  final GameResult result;
  final ScannedArea playArea;
  final SwingProfile swingProfile;
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.args});

  final ResultScreenArgs args;

  @override
  Widget build(BuildContext context) {
    final accuracyPercent = (args.result.accuracy * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match results',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'This shell already carries the shared scan and calibration data into the outcome screen, so the next team integrations only need to replace placeholders with live services.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _ResultTile(label: 'Score', value: '${args.result.score}'),
                  _ResultTile(label: 'Hits', value: '${args.result.hits}'),
                  _ResultTile(
                    label: 'Smashes',
                    value: '${args.result.smashes}',
                  ),
                  _ResultTile(
                    label: 'Longest rally',
                    value: '${args.result.longestRally}',
                  ),
                  _ResultTile(label: 'Accuracy', value: '$accuracyPercent%'),
                  _ResultTile(
                    label: 'Peak speed',
                    value: '${args.result.peakBallSpeed.toStringAsFixed(2)}x',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.game,
                arguments: GameScreenArgs(
                  playArea: args.playArea,
                  swingProfile: args.swingProfile,
                ),
              ),
              child: const Text('Play again'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
