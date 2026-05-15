import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';
import 'multiplayer_models.dart';
import 'multiplayer_session_controller.dart';

class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({
    super.key,
    required this.a11y,
    required this.sessionController,
  });

  final A11yController a11y;
  final MultiplayerSessionController sessionController;

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    widget.sessionController.hostSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarioColors.marioBlue,
      appBar: AppBar(
        backgroundColor: MarioColors.marioBlue,
        foregroundColor: MarioColors.cloudWhite,
        title: const Text('HOST GAME'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.sessionController,
          builder: (context, _) {
            final state = widget.sessionController.state;
            if (state.isConnected && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                Navigator.pushReplacementNamed(
                  context,
                  Routes.scan,
                  arguments: widget.sessionController,
                );
              });
            }

            return Padding(
              padding: const EdgeInsets.all(MarioSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    label: 'HOST STATUS',
                    title: 'Show the QR\nto your friend',
                    titleColor: MarioColors.cloudWhite,
                  ),
                  const SizedBox(height: MarioSpacing.md),
                  MarioBlockCard(
                    child: Text(_statusText(state)),
                  ),
                  const SizedBox(height: MarioSpacing.sm),
                  if (state.payload != null)
                    _HostQrCard(payload: state.payload!)
                  else
                    const MarioBlockCard(
                      child: Text(
                        'Preparing the local room and generating the join payload.',
                      ),
                    ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: MarioSpacing.sm),
                    MarioBlockCard(
                      background: MarioColors.coin,
                      child: Text(state.errorMessage!),
                    ),
                  ],
                  if (state.disconnectReason != null) ...[
                    const SizedBox(height: MarioSpacing.sm),
                    MarioBlockCard(
                      background: MarioColors.coin,
                      child: Text(state.disconnectReason!),
                    ),
                  ],
                  const Spacer(),
                  MarioButton(
                    a11y: widget.a11y,
                    label: 'RETRY HOSTING',
                    icon: const Icon(Icons.refresh_rounded),
                    expand: true,
                    color: MarioColors.pipe,
                    onPressed: () => widget.sessionController.hostSession(),
                  ),
                  const SizedBox(height: MarioSpacing.sm),
                  MarioButton(
                    a11y: widget.a11y,
                    label: 'CANCEL',
                    expand: true,
                    color: MarioColors.cloudWhite,
                    foregroundColor: MarioColors.bowserBlack,
                    onPressed: () async {
                      await widget.sessionController.closeSession(
                        reason: 'Host cancelled the session.',
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _statusText(MultiplayerSessionState state) {
    switch (state.connectionStatus) {
      case MultiplayerConnectionStatus.hosting:
        return 'Creating the local multiplayer room now.';
      case MultiplayerConnectionStatus.waitingForJoiner:
        return 'Room ready. The second phone can scan the QR code now.';
      case MultiplayerConnectionStatus.connected:
        return 'Both phones are connected. Starting shared spatial creation.';
      case MultiplayerConnectionStatus.disconnected:
        return state.disconnectReason ?? 'The host session closed.';
      case MultiplayerConnectionStatus.error:
        return state.errorMessage ?? 'Unable to create the host session.';
      case MultiplayerConnectionStatus.idle:
      case MultiplayerConnectionStatus.joining:
        return 'Preparing the host flow.';
    }
  }
}

class _HostQrCard extends StatelessWidget {
  const _HostQrCard({required this.payload});

  final PairingPayload payload;

  @override
  Widget build(BuildContext context) {
    return MarioBlockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room ${payload.roomId}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: MarioSpacing.xs),
          Text('${payload.hostAddress}:${payload.port}'),
          const SizedBox(height: MarioSpacing.sm),
          Center(
            child: QrImageView(
              data: payload.encode(),
              size: 220,
              backgroundColor: MarioColors.cloudWhite,
            ),
          ),
          const SizedBox(height: MarioSpacing.sm),
          SelectableText(
            payload.encode(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
