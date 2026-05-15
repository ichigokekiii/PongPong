import 'package:camera/camera.dart' as camera;
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/widgets/mario_block_card.dart';
import '../../core/widgets/mario_button.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/mario_theme.dart';
import 'play_area_storage.dart';
import 'scan_controller.dart';
import 'scanned_area_model.dart';

/// Camera-guided spatial scan flow.
///
/// This guides the player through left / right / forward capture steps, lets
/// them tune approximate dimensions, and saves a usable virtual play area for
/// later screens.
class SpatialScanScreen extends StatefulWidget {
  const SpatialScanScreen({super.key, required this.a11y});
  final A11yController a11y;

  @override
  State<SpatialScanScreen> createState() => _SpatialScanScreenState();
}

class _SpatialScanScreenState extends State<SpatialScanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _progress;
  late final ScanController _controller;
  final PlayAreaStorage _storage = const PlayAreaStorage();
  camera.CameraController? _cameraController;
  String? _cameraError;
  bool _isCameraStarting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ScanController();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _loadSavedArea();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _loadSavedArea() async {
    final saved = await _storage.load();
    if (!mounted || saved == null) return;

    _controller.restoreSavedArea(saved);
    setState(() {});
  }

  Future<void> _initializeCamera() async {
    if (_isCameraStarting) return;

    _isCameraStarting = true;
    try {
      final cameras = await camera.availableCameras();
      if (cameras.isEmpty) {
        throw camera.CameraException('no_camera', 'No camera found');
      }

      final selected = cameras.firstWhere(
        (description) =>
            description.lensDirection == camera.CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = camera.CameraController(
        selected,
        camera.ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _cameraError = null;
      });
    } on camera.CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = switch (error.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' =>
            'Camera permission is blocked. Allow camera access to scan the play area.',
          'no_camera' => 'No camera found on this device.',
          _ => 'Camera failed to start. ${error.description ?? error.code}',
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _cameraError = 'Camera failed to start. $error');
    } finally {
      _isCameraStarting = false;
    }
  }

  void _restartScanSweep() {
    _progress
      ..reset()
      ..forward();
  }

  void _capture() {
    _controller.captureCurrentStep();
    if (_controller.step != ScanStep.confirm) {
      _restartScanSweep();
    }
    setState(() {});
  }

  void _goBack() {
    _controller.goBack();
    if (_controller.step != ScanStep.confirm) {
      _restartScanSweep();
    }
    setState(() {});
  }

  Future<void> _confirmPlayArea() async {
    final area = _controller.area.markReady();
    await _storage.save(area);
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      Routes.calibration,
      arguments: area,
    );
  }

  String get _title => switch (_controller.step) {
        ScanStep.left => 'Scan LEFT boundary',
        ScanStep.right => 'Scan RIGHT boundary',
        ScanStep.length => 'Scan FORWARD length',
        ScanStep.confirm => 'Play area READY',
      };

  String get _body => switch (_controller.step) {
        ScanStep.left =>
          'Point your phone toward the LEFT edge of your play area, then capture it as your rally limit.',
        ScanStep.right =>
          'Now face the RIGHT edge. Pick the width that best matches the space you can safely swing in.',
        ScanStep.length =>
          'Aim forward. Set how deep the court should feel so the invisible ball has believable approach distance.',
        ScanStep.confirm =>
          'Your virtual court is locked in. Confirm the space, then move on to swing calibration.',
      };

  IconData get _icon => switch (_controller.step) {
        ScanStep.left => Icons.arrow_back_rounded,
        ScanStep.right => Icons.arrow_forward_rounded,
        ScanStep.length => Icons.arrow_upward_rounded,
        ScanStep.confirm => Icons.check_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final area = _controller.area;

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
                label: 'STEP ${_controller.step.index + 1} OF 4',
                title: _title,
                titleColor: MarioColors.cloudWhite,
              ),
              const SizedBox(height: MarioSpacing.sm),
              _OverallProgressBar(progress: _controller.progress),
              const SizedBox(height: MarioSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CameraPreviewFrame(
                        step: _controller.step,
                        icon: _icon,
                        progress: _progress,
                        area: area,
                        cameraController: _cameraController,
                        cameraError: _cameraError,
                        onRetryCamera: _initializeCamera,
                      ),
                      const SizedBox(height: MarioSpacing.md),
                      MarioBlockCard(
                        child: Text(_body, style: t.bodyMedium),
                      ),
                      const SizedBox(height: MarioSpacing.sm),
                      _LiveAreaSummary(area: area),
                      const SizedBox(height: MarioSpacing.sm),
                      if (_controller.step == ScanStep.right)
                        _WidthSelector(
                          selectedWidth: area.widthMeters,
                          onSelect: (width) {
                            _controller.setWidth(width);
                            setState(() {});
                          },
                        ),
                      if (_controller.step == ScanStep.length)
                        _LengthSelector(
                          lengthMeters: area.lengthMeters,
                          onChanged: (value) {
                            _controller.setLength(value);
                            setState(() {});
                          },
                        ),
                      if (_controller.step == ScanStep.confirm)
                        _ZoneBreakdown(area: area),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MarioSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: MarioButton(
                      a11y: widget.a11y,
                      label: _controller.step == ScanStep.confirm
                          ? 'RE-SCAN'
                          : 'BACK',
                      color: MarioColors.coin,
                      foregroundColor: MarioColors.bowserBlack,
                      compact: true,
                      onPressed: _controller.step == ScanStep.left
                          ? null
                          : (_controller.step == ScanStep.confirm
                              ? () {
                                  _controller.reset();
                                  _restartScanSweep();
                                  setState(() {});
                                }
                              : _goBack),
                    ),
                  ),
                  const SizedBox(width: MarioSpacing.xs),
                  Expanded(
                    flex: 2,
                    child: MarioButton(
                      a11y: widget.a11y,
                      label: _controller.step == ScanStep.confirm
                          ? 'CONFIRM PLAY AREA'
                          : 'CAPTURE',
                      icon: Icon(
                        _controller.step == ScanStep.confirm
                            ? Icons.arrow_forward_rounded
                            : Icons.center_focus_strong_rounded,
                      ),
                      expand: true,
                      color: _controller.step == ScanStep.confirm
                          ? MarioColors.pipe
                          : MarioColors.marioRed,
                      onPressed: _controller.step == ScanStep.confirm
                          ? _confirmPlayArea
                          : _capture,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MarioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallProgressBar extends StatelessWidget {
  const _OverallProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: MarioColors.cloudWhite.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(MarioRadius.pill),
        border: Border.all(color: MarioColors.cloudWhite, width: 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: MarioColors.coin,
              borderRadius: BorderRadius.circular(MarioRadius.pill),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewFrame extends StatelessWidget {
  const _CameraPreviewFrame({
    required this.step,
    required this.icon,
    required this.progress,
    required this.area,
    required this.cameraController,
    required this.cameraError,
    required this.onRetryCamera,
  });

  final ScanStep step;
  final IconData icon;
  final AnimationController progress;
  final ScannedAreaModel area;
  final camera.CameraController? cameraController;
  final String? cameraError;
  final VoidCallback onRetryCamera;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        return Container(
          height: 280,
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
                _CameraSurface(
                  controller: cameraController,
                  error: cameraError,
                  onRetry: onRetryCamera,
                ),
                CustomPaint(painter: _ScanGridPainter(progress.value)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: MarioColors.coin, size: 72),
                      const SizedBox(height: MarioSpacing.xs),
                      Text(
                        step == ScanStep.confirm
                            ? 'WIDTH ${area.widthMeters.toStringAsFixed(1)} m · LENGTH ${area.lengthMeters.toStringAsFixed(1)} m'
                            : '${(progress.value * 100).round()}%',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: MarioColors.cloudWhite),
                        textAlign: TextAlign.center,
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

class _CameraSurface extends StatelessWidget {
  const _CameraSurface({
    required this.controller,
    required this.error,
    required this.onRetry,
  });

  final camera.CameraController? controller;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cameraController = controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cameraController.value.previewSize?.height ?? 1,
          height: cameraController.value.previewSize?.width ?? 1,
          child: camera.CameraPreview(cameraController),
        ),
      );
    }

    if (error != null) {
      return Container(
        color: MarioColors.bowserBlack,
        padding: const EdgeInsets.all(MarioSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: MarioColors.coin,
              size: 42,
            ),
            const SizedBox(height: MarioSpacing.xs),
            Text(
              error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MarioColors.cloudWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MarioSpacing.sm),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry camera'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: MarioColors.bowserBlack,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: MarioColors.coin),
    );
  }
}

class _LiveAreaSummary extends StatelessWidget {
  const _LiveAreaSummary({required this.area});
  final ScannedAreaModel area;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MarioBlockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current play area', style: t.titleMedium),
          const SizedBox(height: MarioSpacing.xs),
          Wrap(
            spacing: MarioSpacing.xs,
            runSpacing: MarioSpacing.xs,
            children: [
              _DataChip(
                label: 'WIDTH',
                value: '${area.widthMeters.toStringAsFixed(1)} m',
                ready: area.rightBoundaryCaptured,
              ),
              _DataChip(
                label: 'LENGTH',
                value: '${area.lengthMeters.toStringAsFixed(1)} m',
                ready: area.lengthCaptured,
              ),
              _DataChip(
                label: 'LEFT',
                value: area.leftBoundaryCaptured ? 'CAPTURED' : 'PENDING',
                ready: area.leftBoundaryCaptured,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WidthSelector extends StatelessWidget {
  const _WidthSelector({
    required this.selectedWidth,
    required this.onSelect,
  });

  final double selectedWidth;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MarioBlockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Court width', style: t.titleMedium),
          const SizedBox(height: MarioSpacing.xxs),
          Text(
            'Choose the safest side-to-side swing space.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: MarioSpacing.xs),
          Wrap(
            spacing: MarioSpacing.xs,
            runSpacing: MarioSpacing.xs,
            children: ScanController.widthOptions
                .map(
                  (width) => _ChoiceChip(
                    label: '${width.toStringAsFixed(1)} m',
                    selected: selectedWidth == width,
                    onTap: () => onSelect(width),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LengthSelector extends StatelessWidget {
  const _LengthSelector({
    required this.lengthMeters,
    required this.onChanged,
  });

  final double lengthMeters;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MarioBlockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Court length', style: t.titleMedium),
          const SizedBox(height: MarioSpacing.xxs),
          Text(
            'Set how much forward room the invisible ball can travel through.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: MarioSpacing.xs),
          Text(
            '${lengthMeters.toStringAsFixed(1)} m',
            style: t.headlineMedium?.copyWith(color: MarioColors.marioBlue),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: MarioColors.coin,
              inactiveTrackColor:
                  MarioColors.bowserBlack.withValues(alpha: 0.15),
              thumbColor: MarioColors.coin,
              overlayColor: MarioColors.coin.withValues(alpha: 0.2),
              trackHeight: 8,
            ),
            child: Slider(
              min: 2.0,
              max: 4.5,
              divisions: 25,
              value: lengthMeters,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneBreakdown extends StatelessWidget {
  const _ZoneBreakdown({required this.area});
  final ScannedAreaModel area;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return MarioBlockCard(
      background: MarioColors.cloudWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Derived rally zones', style: t.titleMedium),
          const SizedBox(height: MarioSpacing.xs),
          _ZoneRow(
            color: MarioColors.stateFar,
            title: 'Far zone',
            value: '${area.farZoneStartMeters.toStringAsFixed(1)} m onward',
          ),
          const SizedBox(height: MarioSpacing.xs),
          _ZoneRow(
            color: MarioColors.stateNear,
            title: 'Near zone',
            value: 'up to ${area.nearZoneMeters.toStringAsFixed(1)} m',
          ),
          const SizedBox(height: MarioSpacing.xs),
          _ZoneRow(
            color: MarioColors.stateReady,
            title: 'Hit window',
            value:
                '${area.hitZoneStartMeters.toStringAsFixed(1)} m - ${area.hitZoneEndMeters.toStringAsFixed(1)} m',
          ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(MarioRadius.sm),
            border: Border.all(color: MarioColors.bowserBlack, width: 2),
          ),
        ),
        const SizedBox(width: MarioSpacing.xs),
        Expanded(
          child: Text(
            '$title · $value',
            style: t.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MarioSpacing.sm,
          vertical: MarioSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? MarioColors.marioRed : MarioColors.cloudWhite,
          borderRadius: BorderRadius.circular(MarioRadius.pill),
          border: Border.all(color: MarioColors.bowserBlack, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: MarioColors.bowserBlack,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: t.labelLarge?.copyWith(
            color: selected ? MarioColors.cloudWhite : MarioColors.bowserBlack,
          ),
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({
    required this.label,
    required this.value,
    required this.ready,
  });

  final String label;
  final String value;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MarioSpacing.sm,
        vertical: MarioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ready ? MarioColors.coin : MarioColors.cloudWhite,
        borderRadius: BorderRadius.circular(MarioRadius.pill),
        border: Border.all(color: MarioColors.bowserBlack, width: 2),
      ),
      child: Text(
        '$label · $value',
        style: t.labelMedium,
      ),
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

    final scanY = size.height * t;
    final scan = Paint()
      ..color = MarioColors.coin
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scan);
  }

  @override
  bool shouldRepaint(covariant _ScanGridPainter old) => old.t != t;
}
