import 'package:flutter/foundation.dart';

import 'scanned_area_model.dart';

enum ScanStep { left, right, length, confirm }

class ScanController extends ChangeNotifier {
  ScanController()
      : _area = const ScannedAreaModel(
          widthMeters: 2.5,
          lengthMeters: 3.0,
          leftBoundaryCaptured: false,
          rightBoundaryCaptured: false,
          lengthCaptured: false,
        );

  static const List<double> widthOptions = [1.8, 2.2, 2.5, 2.8, 3.2];

  ScannedAreaModel _area;
  ScanStep _step = ScanStep.left;

  ScannedAreaModel get area => _area;
  ScanStep get step => _step;

  bool get canGoBack => _step != ScanStep.left;
  bool get canCapture => _step != ScanStep.confirm;
  bool get canConfirm => _area.isReady && _step == ScanStep.confirm;
  double get progress => (_step.index + 1) / ScanStep.values.length;

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
    _area = const ScannedAreaModel(
      widthMeters: 2.5,
      lengthMeters: 3.0,
      leftBoundaryCaptured: false,
      rightBoundaryCaptured: false,
      lengthCaptured: false,
    );
    _step = ScanStep.left;
    notifyListeners();
  }
}
