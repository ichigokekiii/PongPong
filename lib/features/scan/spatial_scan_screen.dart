import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';

enum _ScanStep { left, right, length, confirm }

/// Simulated spatial scan flow.
///
/// Camera & AR work belong to Member 2 — this UI only exposes the four-step
/// guided flow plus a progress fill so reviewers can see the concept.
class SpatialScanScreen extends StatefulWidget {
  const SpatialScanScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  State<SpatialScanScreen> createState() => _SpatialScanScreenState();
}

class _SpatialScanScreenState extends State<SpatialScanScreen>
    with SingleTickerProviderStateMixin {
  _ScanStep _step = _ScanStep.left;
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _runStep();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _runStep() {
    _progress
      ..reset()
      ..forward();
  }

  void _next() {
    final next = switch (_step) {
      _ScanStep.left => _ScanStep.right,
      _ScanStep.right => _ScanStep.length,
      _ScanStep.length => _ScanStep.confirm,
      _ScanStep.confirm => _ScanStep.confirm,
    };
    setState(() => _step = next);
    if (next != _ScanStep.confirm) _runStep();
  }

  String get _title => switch (_step) {
        _ScanStep.left => 'Scan LEFT boundary',
        _ScanStep.right => 'Scan RIGHT boundary',
        _ScanStep.length => 'Scan FORWARD length',
        _ScanStep.confirm => 'Play area READY',
      };

  String get _body => switch (_step) {
        _ScanStep.left =>
          'Point your phone toward the LEFT edge of your play area.',
        _ScanStep.right => 'Now point at the RIGHT edge. Stay steady, captain.',
        _ScanStep.length =>
          'Aim forward. We are measuring how deep you can swing.',
        _ScanStep.confirm =>
          'Your virtual court is locked in. Ready to calibrate?',
      };

  IconData get _icon => switch (_step) {
        _ScanStep.left => Icons.arrow_back_rounded,
        _ScanStep.right => Icons.arrow_forward_rounded,
        _ScanStep.length => Icons.arrow_upward_rounded,
        _ScanStep.confirm => Icons.check_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: MarioColors.marioBlue,
      appBar: AppBar(
        backgroundColor: MarioColors.marioBlue,
        foregroundColor: MarioColors.cloudWhite,
        title: const Text('SPATIAL SCAN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MarioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                label: 'STEP ${_step.index + 1} OF 4',
                title: _title,
                titleColor: MarioColors.cloudWhite,
              ),
              const SizedBox(height: MarioSpacing.md),
              Expanded(
                child: _CameraStubFrame(
                  step: _step,
                  icon: _icon,
                  progress: _progress,
                ),
              ),
              const SizedBox(height: MarioSpacing.md),
              MarioBlockCard(
                child: Text(_body, style: t.bodyMedium),
              ),
              const SizedBox(height: MarioSpacing.md),
              if (_step == _ScanStep.confirm)
                MarioButton(
                  a11y: widget.a11y,
                  label: 'CONFIRM PLAY AREA',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  expand: true,
                  color: MarioColors.pipe,
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    Routes.calibration,
                  ),
                )
              else
                MarioButton(
                  a11y: widget.a11y,
                  label: 'CAPTURE',
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  expand: true,
                  onPressed: _next,
                ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraStubFrame extends StatelessWidget {
  const _CameraStubFrame({
    required this.step,
    required this.icon,
    required this.progress,
  });
  final _ScanStep step;
  final IconData icon;
  final AnimationController progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: MarioColors.bowserBlack,
            borderRadius: BorderRadius.circular(MarioRadius.lg),
            border: Border.all(color: MarioColors.cloudWhite, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MarioRadius.lg - 3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Grid backdrop simulating AR scan view.
                CustomPaint(painter: _ScanGridPainter(progress.value)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: MarioColors.coin,
                        size: 72,
                      ),
                      const SizedBox(height: MarioSpacing.xs),
                      Text(
                        step == _ScanStep.confirm
                            ? 'WIDTH 2.5 m · LENGTH 3.0 m'
                            : '${(progress.value * 100).round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: MarioColors.cloudWhite),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanGridPainter extends CustomPainter {
  _ScanGridPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MarioColors.pipe.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Animated scan line.
    final scanY = size.height * t;
    final scan = Paint()
      ..color = MarioColors.coin
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scan);
  }

  @override
  bool shouldRepaint(covariant _ScanGridPainter old) => old.t != t;
}
