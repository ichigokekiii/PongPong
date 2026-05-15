import 'package:flutter/material.dart';

import '../../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF6EC), Color(0xFFF5E0D5), Color(0xFFE7F2EE)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _TopBadge(label: 'Flutter MVP'),
                          _TopBadge(label: 'iPhone + Android'),
                          _TopBadge(label: 'Phone-as-paddle'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('PongPong', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 12),
                      Text(
                        'Motion table tennis for your phone.',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan a safe play area, calibrate your swing, then rally against an invisible ping-pong ball using only screen cues, sound, and motion.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      const _FlowCard(),
                      const SizedBox(height: 20),
                      const _FeatureStrip(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.safety),
                        child: const Text('Start Game'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (context) => const _HowToPlaySheet(),
                        ),
                        child: const Text('How It Works'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11212D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard();

  @override
  Widget build(BuildContext context) {
    final steps = ['Home', 'Safety', 'Scan', 'Calibration', 'Game', 'Results'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demo flow', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final step in steps)
                  Chip(
                    label: Text(step),
                    avatar: const Icon(Icons.arrow_forward, size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MiniFeature(
            title: 'Spatial setup',
            detail: 'Width + length scan',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniFeature(
            title: 'Motion hit',
            detail: 'Swing timing + smash',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniFeature(
            title: 'Cue system',
            detail: 'Color + edge feedback',
          ),
        ),
      ],
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detail, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to play', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('1. Scan your safe play area.'),
          const SizedBox(height: 8),
          const Text('2. Calibrate a normal swing and a smash swing.'),
          const SizedBox(height: 8),
          const Text('3. Watch the screen edges and color shifts.'),
          const SizedBox(height: 8),
          const Text('4. Swing when the center turns green.'),
        ],
      ),
    );
  }
}
