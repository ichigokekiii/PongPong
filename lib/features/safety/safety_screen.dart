import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MarioColors.coin,
      appBar: AppBar(
        backgroundColor: MarioColors.coin,
        title: const Text('SAFETY CHECK'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                label: 'BEFORE YOU PLAY',
                title: 'Clear the\nbattlefield!',
              ),
              const SizedBox(height: MarioSpacing.md),
              const MarioBlockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SafetyRow(
                      icon: Icons.warning_amber_rounded,
                      title: 'Open space required',
                      body:
                          'Stand in a room with at least 2×2 m of clear floor.',
                    ),
                    _SafetyRow(
                      icon: Icons.pan_tool_rounded,
                      title: 'Grip your phone firmly',
                      body:
                          'Hold it like a paddle. We strongly recommend a strap.',
                    ),
                    _SafetyRow(
                      icon: Icons.pets_rounded,
                      title: 'No people, pets, or glass',
                      body:
                          'Keep fragile objects and breakable surfaces far away.',
                    ),
                    _SafetyRow(
                      icon: Icons.fitness_center_rounded,
                      title: 'You will be moving',
                      body:
                          'Take breaks. Stop if dizzy. Stay hydrated, champion.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              MarioBlockCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: MarioSpacing.sm,
                  vertical: MarioSpacing.xs,
                ),
                background: MarioColors.cloudWhite,
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: MarioColors.marioRed,
                      side: const BorderSide(
                        color: MarioColors.bowserBlack,
                        width: 2,
                      ),
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'I understand and my play area is safe.',
                        style: t.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MarioSpacing.sm),
              MarioButton(
                a11y: widget.a11y,
                label: _agreed ? "I'M READY" : 'CONFIRM ABOVE TO CONTINUE',
                icon: const Icon(Icons.arrow_forward_rounded),
                expand: true,
                onPressed: _agreed
                    ? () => Navigator.pushReplacementNamed(
                          context,
                          Routes.multiplayerSetup,
                        )
                    : null,
              ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MarioSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(MarioSpacing.xs),
            decoration: BoxDecoration(
              color: MarioColors.marioRed,
              borderRadius: BorderRadius.circular(MarioRadius.sm),
              border: Border.all(color: MarioColors.bowserBlack, width: 2),
            ),
            child: Icon(icon, color: MarioColors.cloudWhite, size: 20),
          ),
          const SizedBox(width: MarioSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: t.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
