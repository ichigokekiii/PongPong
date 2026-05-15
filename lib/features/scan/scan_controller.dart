import 'package:flutter/foundation.dart';

import 'scanned_area_model.dart';

enum ScanStep { left, right, length, confirm }

extension ScanStepPresentation on ScanStep {
  String get title => switch (this) {
        ScanStep.left => 'Scan Left Boundary',
        ScanStep.right => 'Set Play Area Width',
        ScanStep.length => 'Set Court Length',
        ScanStep.confirm => 'Confirm Play Area',
      };

  String get subtitle => switch (this) {
        ScanStep.left =>
          'Stand at the safe left edge of the room and capture that boundary first.',
        ScanStep.right =>
          'Choose the width that best matches the space you can safely swing through.',
        ScanStep.length =>
          'Set how deep the rally lane should feel before locking it in.',
        ScanStep.confirm =>
          'Review the virtual court and confirm it before calibration.',
      };

  String get progressLabel => switch (this) {
        ScanStep.left => 'Left boundary',
        ScanStep.right => 'Width',
        ScanStep.length => 'Length',
        ScanStep.confirm => 'Ready',
      };

  String get previewLabel => switch (this) {
        ScanStep.left => 'Capturing the left safety boundary.',
        ScanStep.right => 'Dialing in the full side-to-side play width.',
        ScanStep.length => 'Adjusting forward depth for incoming shots.',
        ScanStep.confirm => 'The shared court is ready for calibration.',
      };

  static ScanStep fromName(String raw) {
    return ScanStep.values.where((step) => step.name == raw).firstOrNull ??
        ScanStep.left;
  }
}

class ScanController extends ChangeNotifier {
  ScanController() : _area = ScannedAreaModel.defaults;

  static const List<double> widthOptions = [1.8, 2.2, 2.5, 2.8, 3.2];

  ScannedAreaModel _area;
  ScanStep _step = ScanStep.left;

  ScannedAreaModel get area => _area;
  ScanStep get step => _step;

  bool get canGoBack => _step != ScanStep.left;
  bool get canCapture => _step != ScanStep.confirm;
  bool get canConfirm => _area.isReady && _step == ScanStep.confirm;
  double get progress => (_step.index + 1) / ScanStep.values.length;

  void restoreSavedArea(ScannedAreaModel area) {
    _area = area.markReady();
    _step = ScanStep.confirm;
    notifyListeners();
  }

  void setWidth(double widthMeters) {
    _area = _area.copyWith(widthMeters: widthMeters);
    notifyListeners();
  }

  void setLength(double lengthMeters) {
    final rounded = (lengthMeters * 10).roundToDouble() / 10;
    _area = _area.copyWith(lengthMeters: rounded);
    notifyListeners();
  }

  void captureCurrentStep() {
    switch (_step) {
      case ScanStep.left:
        _area = _area.copyWith(leftBoundaryCaptured: true);
        _step = ScanStep.right;
        break;
      case ScanStep.right:
        _area = _area.copyWith(rightBoundaryCaptured: true);
        _step = ScanStep.length;
        break;
      case ScanStep.length:
        _area = _area.copyWith(lengthCaptured: true);
        _step = ScanStep.confirm;
        break;
      case ScanStep.confirm:
        break;
    }
    notifyListeners();
  }

  void goBack() {
    switch (_step) {
      case ScanStep.left:
        break;
      case ScanStep.right:
        _step = ScanStep.left;
        break;
      case ScanStep.length:
        _step = ScanStep.right;
        break;
      case ScanStep.confirm:
        _step = ScanStep.length;
        break;
    }
    notifyListeners();
  }

  void reset() {
    _area = ScannedAreaModel.defaults;
    _step = ScanStep.left;
    notifyListeners();
  }
}
