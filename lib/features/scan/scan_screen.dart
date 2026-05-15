import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import 'scan_controller.dart';
import 'scanned_area_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanController _controller = ScanController();
  CameraController? _cameraController;
  String _cameraStatus = 'Preparing live camera preview...';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeCamera() async {
    final previousController = _cameraController;
    _cameraController = null;
    await previousController?.dispose();

    if (mounted) {
      setState(() {
        _cameraStatus = 'Preparing live camera preview...';
      });
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraStatus = 'No camera was found on this device.';
        });
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraStatus = 'Live camera preview ready';
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraStatus = switch (error.code) {
          'CameraAccessDenied' =>
            'Camera permission denied. Allow access to scan your space.',
          'CameraAccessDeniedWithoutPrompt' =>
            'Camera access is blocked. Open settings to enable it.',
          'CameraAccessRestricted' =>
            'Camera access is restricted on this device.',
          _ => 'Unable to start the camera preview.',
        };
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _cameraStatus = 'Camera plugin is unavailable in this environment.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraStatus = 'Unable to start the camera preview.';
      });
    }
  }

  Widget _buildCameraSurface() {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF223645), Color(0xFF101A22)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 42,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                _cameraStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _initializeCamera,
                child: const Text('Retry camera'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPrimaryAction() {
    if (_controller.step == ScanStep.confirm) {
      Navigator.pushNamed(
        context,
        AppRoutes.calibration,
        arguments: _controller.area,
      );
      return;
    }
    _controller.captureCurrentStep();
  }

  String get _primaryButtonLabel {
    switch (_controller.step) {
      case ScanStep.leftBoundary:
        return 'Capture left edge';
      case ScanStep.rightBoundary:
        return 'Capture right edge';
      case ScanStep.forwardLength:
        return 'Capture forward length';
      case ScanStep.confirm:
        return 'Confirm play area';
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _controller.step;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_controller.stepIndex > 0)
            TextButton(
              onPressed: _controller.restart,
              child: const Text('Restart scan'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan your play area', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(step.progressLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(step.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _controller.progress),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _ScanStepDots(currentIndex: _controller.stepIndex),
                      const SizedBox(height: 16),
                      Expanded(
                        child: step == ScanStep.confirm
                            ? _PlayAreaSummary(area: _controller.area)
                            : _ScanCameraPanel(
                                surface: _buildCameraSurface(),
                                statusText: _cameraStatus,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Width',
                              value: _controller.widthLabel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              label: 'Length',
                              value: _controller.lengthLabel,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onPrimaryAction,
              child: Text(_primaryButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCameraPanel extends StatelessWidget {
  const _ScanCameraPanel({required this.surface, required this.statusText});

  final Widget surface;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(child: surface),
          const Positioned.fill(child: _ScannerGrid()),
          Center(
            child: Container(
              width: 180,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF4A261), width: 3),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayAreaSummary extends StatelessWidget {
  const _PlayAreaSummary({required this.area});

  final ScannedArea area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F4EF), Color(0xFFF8EADD)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2A9D8F)),
                const SizedBox(width: 8),
                Text(
                  'Play area ready',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Width', value: area.widthLabel),
            _SummaryRow(label: 'Length', value: area.lengthLabel),
            _SummaryRow(
              label: 'Near zone',
              value: '${area.nearZone.toStringAsFixed(2)} m',
            ),
            _SummaryRow(
              label: 'Hit zone',
              value: '${area.hitZone.toStringAsFixed(2)} m',
            ),
            const Spacer(),
            const _VirtualCourtPreview(),
          ],
        ),
      ),
    );
  }
}

class _VirtualCourtPreview extends StatelessWidget {
  const _VirtualCourtPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF11212D),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color(0xFFF4A261), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Virtual court',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ScanStepDots extends StatelessWidget {
  const _ScanStepDots({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < ScanStep.values.length; i++) ...[
          _Dot(active: i <= currentIndex, label: '${i + 1}'),
          if (i != ScanStep.values.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < currentIndex
                    ? const Color(0xFF2A9D8F)
                    : const Color(0xFFE0DACF),
              ),
            ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF11212D) : const Color(0xFFE0DACF),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF11212D),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScannerGrid extends StatelessWidget {
  const _ScannerGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8FB8A8).withValues(alpha: 0.24)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
