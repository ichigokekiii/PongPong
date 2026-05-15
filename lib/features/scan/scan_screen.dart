import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import 'scanned_area_model.dart';

enum _ScanStep {
  leftBoundary(
    'Scan left boundary',
    'Mark the left edge of your playable lane.',
  ),
  rightBoundary(
    'Scan right boundary',
    'Sweep to the right edge to capture width.',
  ),
  forwardLength('Scan forward length', 'Point forward to set the rally depth.'),
  confirm(
    'Confirm play area',
    'Review the measured space before starting calibration.',
  );

  const _ScanStep(this.title, this.description);

  final String title;
  final String description;
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int _stepIndex = 0;
  ScannedArea _area = ScannedArea.empty();
  CameraController? _cameraController;
  String _cameraStatus = 'Preparing live camera preview...';

  _ScanStep get _step => _ScanStep.values[_stepIndex];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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
        if (!mounted) {
          return;
        }
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
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraStatus =
            'Camera plugin is unavailable in this environment.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
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

  void _advanceScan() {
    setState(() {
      switch (_step) {
        case _ScanStep.leftBoundary:
          _area = _area.copyWith(width: 1.3);
        case _ScanStep.rightBoundary:
          _area = _area.copyWith(width: 2.6);
        case _ScanStep.forwardLength:
          _area = _area.copyWith(length: 3.2, nearZone: 1.0, hitZone: 0.55);
        case _ScanStep.confirm:
          Navigator.pushNamed(context, AppRoutes.calibration, arguments: _area);
          return;
      }

      _stepIndex = (_stepIndex + 1).clamp(0, _ScanStep.values.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stepIndex + 1) / _ScanStep.values.length;

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan your play area',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              _step.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              Positioned.fill(child: _buildCameraSurface()),
                              const Positioned.fill(child: _ScannerGrid()),
                              Center(
                                child: Container(
                                  width: 180,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFFF4A261),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 24,
                                child: Text(
                                  _cameraStatus,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Width',
                              value: _area.widthLabel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              label: 'Length',
                              value: _area.lengthLabel,
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
              onPressed: _advanceScan,
              child: Text(
                _step == _ScanStep.confirm
                    ? 'Confirm play area'
                    : 'Capture step',
              ),
            ),
          ],
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
