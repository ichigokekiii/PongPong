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
      : _localController!.currentStep;

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
            if (!mounted) {
              return;
            }
            widget.onScanComplete(_area);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isMultiplayer
                  ? 'Shared Spatial Creation'
                  : 'Scan Your Play Area',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isMultiplayer
                        ? 'Shared Spatial Creation'
                        : 'Scan Your Play Area',
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
                  _InfoCard(
                    title: _isMultiplayer
                        ? 'Multiplayer scan mode'
                        : 'Hackathon scan mode',
                    body: _isMultiplayer
                        ? _multiplayerInfoBody(sessionState)
                        : 'This simulated camera flow lets Member 2 demo the spatial setup without live depth mapping. The important part is the guided preparation of a believable play area.',
                  ),
                  if (sessionState?.disconnectReason != null) ...[
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Session closed',
                      body: sessionState!.disconnectReason!,
                    ),
                  ],
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
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                  _ScanPreviewCard(currentStep: _currentStep, area: _area),
                  const SizedBox(height: 16),
                  _buildControls(context, _currentStep, _area),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.straighten_rounded, size: 18),
                        label: Text(
                          'Width ${_area.widthMeters.toStringAsFixed(1)} m',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.open_in_full_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Length ${_area.lengthMeters.toStringAsFixed(1)} m',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.square_foot_rounded, size: 18),
                        label: Text(
                          'Area ${_area.playAreaSizeSquareMeters.toStringAsFixed(1)} m²',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _multiplayerInfoBody(dynamic sessionState) {
    if (_isHost) {
      return 'Both phones are connected. You are the host, so your scan controls drive the shared play area. The other phone mirrors each step and will move forward when you confirm the space.';
    }

    return 'The host is creating the shared play area now. Your phone mirrors the host scan so both players stay aligned before local calibration starts.';
  }

  Widget _buildControls(
    BuildContext context,
    ScanStep currentStep,
    ScannedAreaModel area,
  ) {
    if (_isMultiplayer && !_isHost) {
      return _buildJoinerMirror(currentStep, area);
    }

    switch (currentStep) {
      case ScanStep.leftBoundary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCard(
              label: 'Left boundary reach',
              value: '${area.leftReachMeters.toStringAsFixed(1)} m',
              child: Slider(
                value: area.leftReachMeters,
                min: 0.8,
                max: 2.0,
                divisions: 24,
                label: '${area.leftReachMeters.toStringAsFixed(1)} m',
                onChanged: _isMultiplayer
                    ? widget.multiplayerSession!.updateLeftReach
                    : _localController!.updateLeftReach,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isMultiplayer
                  ? widget.multiplayerSession!.nextScanStep
                  : _localController!.nextStep,
              child: Text(
                _isMultiplayer ? 'Lock Left Boundary' : 'Scan Left Boundary',
              ),
            ),
          ],
        );
      case ScanStep.rightBoundary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCard(
              label: 'Right boundary reach',
              value: '${area.rightReachMeters.toStringAsFixed(1)} m',
              child: Slider(
                value: area.rightReachMeters,
                min: 0.8,
                max: 2.0,
                divisions: 24,
                label: '${area.rightReachMeters.toStringAsFixed(1)} m',
                onChanged: _isMultiplayer
                    ? widget.multiplayerSession!.updateRightReach
                    : _localController!.updateRightReach,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.previousScanStep
                      : _localController!.previousStep,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.nextScanStep
                      : _localController!.nextStep,
                  child: Text(
                    _isMultiplayer
                        ? 'Lock Right Boundary'
                        : 'Scan Right Boundary',
                  ),
                ),
              ],
            ),
          ],
        );
      case ScanStep.forwardLength:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCard(
              label: 'Forward length',
              value: '${area.lengthMeters.toStringAsFixed(1)} m',
              child: Slider(
                value: area.lengthMeters,
                min: 2.0,
                max: 5.0,
                divisions: 30,
                label: '${area.lengthMeters.toStringAsFixed(1)} m',
                onChanged: _isMultiplayer
                    ? widget.multiplayerSession!.updateLength
                    : _localController!.updateLength,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.previousScanStep
                      : _localController!.previousStep,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.nextScanStep
                      : _localController!.nextStep,
                  child: Text(
                    _isMultiplayer
                        ? 'Lock Forward Length'
                        : 'Scan Forward Length',
                  ),
                ),
              ],
            ),
          ],
        );
      case ScanStep.confirm:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(
              title:
                  _isMultiplayer ? 'Shared play area ready' : 'Play area ready',
              body:
                  'Width ${area.widthMeters.toStringAsFixed(1)} m, length ${area.lengthMeters.toStringAsFixed(1)} m, play area ${area.playAreaSizeSquareMeters.toStringAsFixed(1)} m². '
                  '${_isMultiplayer ? 'Confirm this shared space to move both phones into calibration.' : 'This setup is ready to pass into calibration and gameplay.'}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.previousScanStep
                      : _localController!.previousStep,
                  child:
                      Text(_isMultiplayer ? 'Adjust Shared Space' : 'Adjust'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isMultiplayer
                      ? widget.multiplayerSession!.confirmSharedScan
                      : () => widget.onScanComplete(area),
                  child: Text(
                    _isMultiplayer
                        ? 'Confirm Shared Space'
                        : 'Start Game Setup',
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildJoinerMirror(ScanStep currentStep, ScannedAreaModel area) {
    final title = currentStep == ScanStep.confirm
        ? 'Waiting for host confirmation'
        : 'Waiting for host scan input';
    final body = currentStep == ScanStep.confirm
        ? 'The host is reviewing the shared play area now. Both phones will move to calibration after the host confirms the shared space.'
        : 'The host is controlling the sliders and scan steps. Your phone mirrors the shared spatial-creation progress so the multiplayer setup stays in sync.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(title: title, body: body),
        const SizedBox(height: 16),
        _MetricCard(
          label: 'Left boundary reach',
          value: '${area.leftReachMeters.toStringAsFixed(1)} m',
          child: Slider(
            value: area.leftReachMeters,
            min: 0.8,
            max: 2.0,
            divisions: 24,
            onChanged: null,
          ),
        ),
        const SizedBox(height: 16),
        _MetricCard(
          label: 'Right boundary reach',
          value: '${area.rightReachMeters.toStringAsFixed(1)} m',
          child: Slider(
            value: area.rightReachMeters,
            min: 0.8,
            max: 2.0,
            divisions: 24,
            onChanged: null,
          ),
        ),
        const SizedBox(height: 16),
        _MetricCard(
          label: 'Forward length',
          value: '${area.lengthMeters.toStringAsFixed(1)} m',
          child: Slider(
            value: area.lengthMeters,
            min: 2.0,
            max: 5.0,
            divisions: 30,
            onChanged: null,
          ),
        ),
      ],
    );
  }
}

class _ScanPreviewCard extends StatelessWidget {
  const _ScanPreviewCard({required this.currentStep, required this.area});

  final ScanStep currentStep;
  final ScannedAreaModel area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.primary;
    final previewColor = highlightColor.withValues(alpha: 0.12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: highlightColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.videocam_rounded, color: highlightColor),
              const SizedBox(width: 10),
              Text(
                'Simulated scan preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Align(
                  child: Container(
                    width: 160,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: highlightColor.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: _alignmentForStep(currentStep),
                  child: Container(
                    width: currentStep == ScanStep.forwardLength ? 120 : 12,
                    height: currentStep == ScanStep.forwardLength ? 12 : 120,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentStep.previewLabel,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current estimate: ${area.widthMeters.toStringAsFixed(1)} m wide, ${area.lengthMeters.toStringAsFixed(1)} m deep.',
          ),
        ],
      ),
    );
  }

  Alignment _alignmentForStep(ScanStep step) {
    switch (step) {
      case ScanStep.leftBoundary:
        return Alignment.centerLeft;
      case ScanStep.rightBoundary:
        return Alignment.centerRight;
      case ScanStep.forwardLength:
        return Alignment.topCenter;
      case ScanStep.confirm:
        return Alignment.center;
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
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
