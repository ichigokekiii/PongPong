import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';
import 'multiplayer_models.dart';
import 'multiplayer_session_controller.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({
    super.key,
    required this.a11y,
    required this.sessionController,
  });

  final A11yController a11y;
  final MultiplayerSessionController sessionController;

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final TextEditingController _payloadController = TextEditingController();
  bool _showScanner = false;
  bool _navigated = false;
  String? _formatError;

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarioColors.pipe,
      appBar: AppBar(
        backgroundColor: MarioColors.pipe,
        foregroundColor: MarioColors.cloudWhite,
        title: const Text('JOIN GAME'),
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
                    label: 'JOIN STATUS',
                    title: 'Connect to\nthe host room',
                    titleColor: MarioColors.cloudWhite,
                  ),
                  const SizedBox(height: MarioSpacing.md),
                  MarioBlockCard(
                    child: Text(_statusText(state)),
                  ),
                  const SizedBox(height: MarioSpacing.sm),
                  MarioBlockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Paste the host payload'),
                        const SizedBox(height: MarioSpacing.xs),
                        TextField(
                          controller: _payloadController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Paste the QR payload here if needed.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_formatError != null) ...[
                    const SizedBox(height: MarioSpacing.xs),
                    MarioBlockCard(
                      background: MarioColors.coin,
                      child: Text(_formatError!),
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: MarioSpacing.xs),
                    MarioBlockCard(
                      background: MarioColors.coin,
                      child: Text(state.errorMessage!),
                    ),
                  ],
                  if (state.disconnectReason != null) ...[
                    const SizedBox(height: MarioSpacing.xs),
                    MarioBlockCard(
                      background: MarioColors.coin,
                      child: Text(state.disconnectReason!),
                    ),
                  ],
                  const SizedBox(height: MarioSpacing.sm),
                  MarioButton(
                    a11y: widget.a11y,
                    label: 'JOIN WITH PAYLOAD',
                    icon: const Icon(Icons.login_rounded),
                    expand: true,
                    onPressed: _submitPayload,
                  ),
                  const SizedBox(height: MarioSpacing.xs),
                  MarioButton(
                    a11y: widget.a11y,
                    label: _showScanner ? 'HIDE SCANNER' : 'USE CAMERA SCANNER',
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    expand: true,
                    color: MarioColors.coin,
                    foregroundColor: MarioColors.bowserBlack,
                    onPressed: () =>
                        setState(() => _showScanner = !_showScanner),
                  ),
                  if (_showScanner) ...[
                    const SizedBox(height: MarioSpacing.sm),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(MarioRadius.lg),
                        child: MobileScanner(
                          onDetect: (capture) {
                            final rawValue = capture.barcodes
                                .map((barcode) => barcode.rawValue)
                                .whereType<String>()
                                .firstWhere(
                                  (value) => value.isNotEmpty,
                                  orElse: () => '',
                                );
                            if (rawValue.isEmpty || !mounted) {
                              return;
                            }
                            _payloadController.text = rawValue;
                            _submitPayload();
                          },
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(height: MarioSpacing.sm),
                  MarioButton(
                    a11y: widget.a11y,
                    label: 'RETRY JOIN',
                    icon: const Icon(Icons.refresh_rounded),
                    expand: true,
                    color: MarioColors.marioBlue,
                    onPressed: state.payload == null
                        ? null
                        : widget.sessionController.retryJoin,
                  ),
                  const SizedBox(height: MarioSpacing.xs),
                  MarioButton(
                    a11y: widget.a11y,
                    label: 'CANCEL',
                    expand: true,
                    color: MarioColors.cloudWhite,
                    foregroundColor: MarioColors.bowserBlack,
                    onPressed: () async {
                      await widget.sessionController.closeSession(
                        reason: 'Joiner left before connecting.',
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

  void _submitPayload() {
    try {
      final payload = PairingPayload.parse(_payloadController.text.trim());
      setState(() {
        _formatError = null;
      });
      widget.sessionController.joinSession(payload);
    } on FormatException catch (error) {
      setState(() {
        _formatError = error.message;
      });
    }
  }

  String _statusText(MultiplayerSessionState state) {
    switch (state.connectionStatus) {
      case MultiplayerConnectionStatus.joining:
        return 'Connecting to the host room now.';
      case MultiplayerConnectionStatus.connected:
        return 'Connected. Starting shared spatial creation.';
      case MultiplayerConnectionStatus.disconnected:
        return state.disconnectReason ?? 'The join session closed.';
      case MultiplayerConnectionStatus.error:
        return state.errorMessage ?? 'Unable to connect to the host room.';
      case MultiplayerConnectionStatus.idle:
      case MultiplayerConnectionStatus.hosting:
      case MultiplayerConnectionStatus.waitingForJoiner:
        return 'Scan the host QR code or paste the payload to join.';
    }
  }
}
