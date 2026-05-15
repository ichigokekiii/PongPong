import 'package:flutter/material.dart';

import 'scan_controller.dart';
import 'scanned_area_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.onScanComplete});

  final ValueChanged<ScannedAreaModel> onScanComplete;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final ScanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScanController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final area = _controller.area;
        final currentStep = _controller.currentStep;

        return Scaffold(
          appBar: AppBar(title: const Text('Scan Your Play Area')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Your Play Area',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  const _InfoCard(
                    title: 'Hackathon scan mode',
                    body:
                        'This simulated camera flow lets Member 2 demo the spatial setup without live depth mapping. The important part is the guided preparation of a believable play area.',
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _controller.progress,
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
                        'Step ${currentStep.index + 1} of ${ScanStep.values.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      _StatusPill(label: currentStep.progressLabel),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ScanPreviewCard(currentStep: currentStep, area: area),
                  const SizedBox(height: 16),
                  _buildControls(context, currentStep, area),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.straighten_rounded, size: 18),
                        label: Text(
                          'Width ${area.widthMeters.toStringAsFixed(1)} m',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.open_in_full_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Length ${area.lengthMeters.toStringAsFixed(1)} m',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.square_foot_rounded, size: 18),
                        label: Text(
                          'Area ${area.playAreaSizeSquareMeters.toStringAsFixed(1)} m²',
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

  Widget _buildControls(
    BuildContext context,
    ScanStep currentStep,
    ScannedAreaModel area,
  ) {
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
                onChanged: _controller.updateLeftReach,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _controller.nextStep,
              child: const Text('Scan Left Boundary'),
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
                onChanged: _controller.updateRightReach,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _controller.previousStep,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _controller.nextStep,
                  child: const Text('Scan Right Boundary'),
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
                onChanged: _controller.updateLength,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _controller.previousStep,
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _controller.nextStep,
                  child: const Text('Scan Forward Length'),
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
              title: 'Play area ready',
              body:
                  'Width ${area.widthMeters.toStringAsFixed(1)} m, length ${area.lengthMeters.toStringAsFixed(1)} m, play area ${area.playAreaSizeSquareMeters.toStringAsFixed(1)} m². This setup is ready to pass into calibration and gameplay.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _controller.previousStep,
                  child: const Text('Adjust'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => widget.onScanComplete(area),
                  child: const Text('Start Game Setup'),
                ),
              ],
            ),
          ],
        );
    }
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
