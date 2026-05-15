import 'package:flutter/material.dart';
import 'package:pongpong/features/multiplayer/multiplayer_session_controller.dart';
import 'package:pongpong/features/scan/scan_controller.dart';
import 'package:pongpong/features/scan/scanned_area_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.onScanComplete,
    this.multiplayerSession,
  });

  final ValueChanged<ScannedAreaModel> onScanComplete;
  final MultiplayerSessionController? multiplayerSession;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanController? _localController;
  bool _navigated = false;

  bool get _isMultiplayer => widget.multiplayerSession != null;
  bool get _isHost => widget.multiplayerSession?.state.isHost ?? false;
  Listenable get _listenable => widget.multiplayerSession ?? _localController!;

  ScanStep get _currentStep => _isMultiplayer
      ? widget.multiplayerSession!.state.sharedScanState.step
      : _localController!.step;

  ScannedAreaModel get _area => _isMultiplayer
      ? widget.multiplayerSession!.state.sharedScanState.area
      : _localController!.area;

  double get _progress => (_currentStep.index + 1) / ScanStep.values.length;

  @override
  void initState() {
    super.initState();
    if (!_isMultiplayer) {
      _localController = ScanController();
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _listenable,
      builder: (context, _) {
        final sessionState = widget.multiplayerSession?.state;
        if (sessionState?.sharedScanState.confirmed == true && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onScanComplete(_area);
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isMultiplayer ? 'Shared Spatial Setup' : 'Scan Your Play Area',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStep.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Text(
                        'Step ${_currentStep.index + 1} of ${ScanStep.values.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      _StatusPill(label: _currentStep.progressLabel),
                      if (_isMultiplayer)
                        _StatusPill(
                          label: _isHost
                              ? 'Host controls scan'
                              : 'Joiner mirrors scan',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoCard(
                    title:
                        _isMultiplayer ? 'Shared scan status' : 'Scan status',
                    body: _isMultiplayer && !_isHost
                        ? 'The host is driving the shared setup. Your phone mirrors each step and will advance when the host confirms the court.'
                        : _currentStep.previewLabel,
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(area: _area),
                  const SizedBox(height: 16),
                  _buildControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    if (_isMultiplayer && !_isHost) {
      return const _InfoCard(
        title: 'Waiting on host',
        body:
            'This phone will stay in sync automatically while the host captures the shared play area.',
      );
    }

    switch (_currentStep) {
      case ScanStep.left:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChecklistCard(
              title: 'Left boundary',
              body:
                  'Move to the left-most safe swing position and capture that edge first.',
              ready: _area.leftBoundaryCaptured,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _captureCurrentStep,
              child: const Text('Capture Left Boundary'),
            ),
          ],
        );
      case ScanStep.right:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCard(
              label: 'Play area width',
              value: '${_area.widthMeters.toStringAsFixed(1)} m',
              child: Slider(
                value: _area.widthMeters,
                min: ScanController.widthOptions.first,
                max: ScanController.widthOptions.last,
                divisions: 14,
                label: '${_area.widthMeters.toStringAsFixed(1)} m',
                onChanged: _setWidth,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _goBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _captureCurrentStep,
                  child: const Text('Lock Width'),
                ),
              ],
            ),
          ],
        );
      case ScanStep.length:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCard(
              label: 'Court length',
              value: '${_area.lengthMeters.toStringAsFixed(1)} m',
              child: Slider(
                value: _area.lengthMeters,
                min: 2.0,
                max: 5.0,
                divisions: 30,
                label: '${_area.lengthMeters.toStringAsFixed(1)} m',
                onChanged: _setLength,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _goBack,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _captureCurrentStep,
                  child: const Text('Lock Length'),
                ),
              ],
            ),
          ],
        );
      case ScanStep.confirm:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _InfoCard(
              title: 'Play area ready',
              body:
                  'The boundaries and dimensions are captured. Confirm this court to continue into calibration.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _goBack,
                  child: const Text('Adjust'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _confirm,
                  child: Text(
                    _isMultiplayer
                        ? 'Confirm Shared Space'
                        : 'Start Calibration',
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  void _setWidth(double value) {
    if (_isMultiplayer) {
      widget.multiplayerSession!.setWidth(value);
    } else {
      _localController!.setWidth(value);
    }
  }

  void _setLength(double value) {
    if (_isMultiplayer) {
      widget.multiplayerSession!.setLength(value);
    } else {
      _localController!.setLength(value);
    }
  }

  void _captureCurrentStep() {
    if (_isMultiplayer) {
      widget.multiplayerSession!.captureCurrentStep();
    } else {
      _localController!.captureCurrentStep();
    }
  }

  void _goBack() {
    if (_isMultiplayer) {
      widget.multiplayerSession!.goBack();
    } else {
      _localController!.goBack();
    }
  }

  void _confirm() {
    if (_isMultiplayer) {
      widget.multiplayerSession!.confirmSharedScan();
    } else {
      widget.onScanComplete(_area);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.area});

  final ScannedAreaModel area;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current estimate',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text('Width ${area.widthMeters.toStringAsFixed(1)} m'),
          Text('Length ${area.lengthMeters.toStringAsFixed(1)} m'),
          Text('Area ${area.playAreaSizeSquareMeters.toStringAsFixed(1)} m²'),
          const SizedBox(height: 12),
          _CaptureState(
            label: 'Left boundary',
            ready: area.leftBoundaryCaptured,
          ),
          _CaptureState(
            label: 'Right boundary',
            ready: area.rightBoundaryCaptured,
          ),
          _CaptureState(label: 'Length', ready: area.lengthCaptured),
        ],
      ),
    );
  }
}

class _CaptureState extends StatelessWidget {
  const _CaptureState({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: ready ? Colors.green : Colors.black45,
          ),
          const SizedBox(width: 8),
          Text('$label ${ready ? 'captured' : 'pending'}'),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.title,
    required this.body,
    required this.ready,
  });

  final String title;
  final String body;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: title,
      body: '$body ${ready ? 'Captured.' : 'Pending capture.'}',
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(value),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
