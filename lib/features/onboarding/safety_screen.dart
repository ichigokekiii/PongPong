import 'package:flutter/material.dart';

import '../../app/routes.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety first',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 14),
            Text(
              'Clear the space around you before playing. Hold the phone firmly and stay away from people, pets, glass, and fragile objects.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SafetyRow(
                      label: 'Arm span',
                      detail:
                          'You should be able to swing without touching a wall.',
                    ),
                    SizedBox(height: 14),
                    _SafetyRow(
                      label: 'Grip',
                      detail: 'Use a case or wrist strap if available.',
                    ),
                    SizedBox(height: 14),
                    _SafetyRow(
                      label: 'Lighting',
                      detail: 'Keep the room bright enough for the scan flow.',
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.scan),
              child: const Text('Space is clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.verified_user_outlined, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
