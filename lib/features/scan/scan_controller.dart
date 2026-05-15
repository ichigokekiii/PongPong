import 'package:flutter/foundation.dart';

import 'scanned_area_model.dart';

/// Discrete steps the player walks through while scanning their play area.
/// The order matches the task spec: width first (left + right edges), then
/// length, then a confirmation step.
enum ScanStep {
  leftBoundary(
    title: 'Scan left boundary',
    description: 'Aim the camera at the left edge of your playable lane.',
    progressLabel: 'Scanning width…',
  ),
  rightBoundary(
    title: 'Scan right boundary',
    description: 'Sweep to the right edge to lock in the lane width.',
    progressLabel: 'Scanning width…',
  ),
  forwardLength(
    title: 'Scan forward length',
    description: 'Point forward to set how deep the virtual rally goes.',
    progressLabel: 'Scanning length…',
  ),
  confirm(
    title: 'Confirm play area',
    description: 'Review the measured space before starting calibration.',
    progressLabel: 'Play area ready',
  );

  const ScanStep({
    required this.title,
    required this.description,
    required this.progressLabel,
  });

  final String title;
  final String description;
  final String progressLabel;
}

/// Controller that owns the scan state machine. Pulled out of the screen so
/// the data flow (left/right/forward → ScannedArea) is testable and isolated
/// from the camera/UI plumbing.
class ScanController extends ChangeNotifier {
  ScanController();

  int _stepIndex = 0;
  ScannedArea _area = ScannedArea.empty();

  // Captured measurements (simulated for the MVP).
  double? _leftOffset;
  double? _rightOffset;
  double? _forwardLength;

  ScanStep get step => ScanStep.values[_stepIndex];
  int get stepIndex => _stepIndex;
  int get totalSteps => ScanStep.values.length;
  double get progress => (_stepIndex + 1) / totalSteps;
  ScannedArea get area => _area;
  bool get isComplete => step == ScanStep.confirm && _area.isReady;

  String get widthLabel => _area.widthLabel;
  String get lengthLabel => _area.lengthLabel;

  /// Advance to the next step. The MVP simulates real spatial scanning by
  /// using believable values that vary slightly per capture so the demo
  /// looks alive instead of always showing identical numbers.
  void captureCurrentStep() {
    switch (step) {
      case ScanStep.leftBoundary:
        _leftOffset = -1.3 - (_jitter() * 0.15);
        _stepIndex += 1;
      case ScanStep.rightBoundary:
        _rightOffset = 1.3 + (_jitter() * 0.15);
        _area = _area.copyWith(width: _computedWidth);
        _stepIndex += 1;
      case ScanStep.forwardLength:
        _forwardLength = 3.0 + (_jitter() * 0.4);
        final length = _forwardLength!;
        _area = _area.copyWith(
          length: length,
          nearZone: length * 0.32,
          hitZone: length * 0.18,
        );
        _stepIndex += 1;
      case ScanStep.confirm:
        return;
    }
    notifyListeners();
  }

  /// Resets the scan flow back to the first step.
  void restart() {
    _stepIndex = 0;
    _leftOffset = null;
    _rightOffset = null;
    _forwardLength = null;
    _area = ScannedArea.empty();
    notifyListeners();
  }

  double get _computedWidth {
    final left = _leftOffset ?? 0;
    final right = _rightOffset ?? 0;
    final span = (right - left).abs();
    return span <= 0 ? 0 : span;
  }

  double _jitter() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return ((ms % 100) / 100.0) - 0.5;
  }
}
