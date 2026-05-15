import 'package:flutter/foundation.dart';

import 'scanned_area_model.dart';

class ScanController extends ChangeNotifier {
  ScanController({ScannedAreaModel? initialArea, ScanStep? initialStep})
      : _area = initialArea ??
            const ScannedAreaModel(
              leftReachMeters: 1.2,
              rightReachMeters: 1.3,
              lengthMeters: 3.0,
            ),
        _currentStep = initialStep ?? ScanStep.leftBoundary;

  ScanStep _currentStep;
  ScannedAreaModel _area;

  ScanStep get currentStep => _currentStep;
  ScannedAreaModel get area => _area;

  double get progress => (_currentStep.index + 1) / ScanStep.values.length;

  void updateLeftReach(double value) {
    _area = _area.copyWith(leftReachMeters: value);
    notifyListeners();
  }

  void updateRightReach(double value) {
    _area = _area.copyWith(rightReachMeters: value);
    notifyListeners();
  }

  void updateLength(double value) {
    _area = _area.copyWith(lengthMeters: value);
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep == ScanStep.confirm) {
      return;
    }

    _currentStep = ScanStep.values[_currentStep.index + 1];
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep == ScanStep.leftBoundary) {
      return;
    }

    _currentStep = ScanStep.values[_currentStep.index - 1];
    notifyListeners();
  }
}
