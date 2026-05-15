import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

class MultiplayerSetupScreen extends StatelessWidget {
  const MultiplayerSetupScreen({
    super.key,
    required this.a11y,
    required this.createSessionController,
  });

  final A11yController a11y;
  final SessionControllerFactory createSessionController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarioColors.sky,
      appBar: AppBar(
        backgroundColor: MarioColors.sky,
        title: const Text('MULTIPLAYER SETUP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                label: 'TWO-PHONE FLOW',
                title: 'Pick a host\nfor the match',
              ),
              const SizedBox(height: MarioSpacing.md),
              const MarioBlockCard(
                child: Text(
                  'One phone hosts the room and shows a QR code. The second phone joins with that QR code. After both phones connect, the host drives the shared spatial creation and the joiner mirrors the progress.',
                ),
              ),
              const Spacer(),
              MarioButton(
                a11y: a11y,
                label: 'HOST GAME',
                icon: const Icon(Icons.wifi_tethering_rounded),
                expand: true,
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.hostLobby,
                  arguments: createSessionController(),
                ),
              ),
              const SizedBox(height: MarioSpacing.sm),
              MarioButton(
                a11y: a11y,
                label: 'JOIN GAME',
                icon: const Icon(Icons.qr_code_scanner_rounded),
                expand: true,
                color: MarioColors.coin,
                foregroundColor: MarioColors.bowserBlack,
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.joinSession,
                  arguments: createSessionController(),
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
