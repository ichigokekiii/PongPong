import 'package:flutter/foundation.dart';

/// Holds runtime accessibility / preference flags.
///
/// Exposed as a single [ChangeNotifier] consumed by every screen via
/// [AnimatedBuilder]. Kept intentionally tiny — no persistence, no DI — so the
/// hackathon team can replace it with shared_preferences post-MVP.
class A11yController extends ChangeNotifier {
  A11yController({
    bool highContrast = true,
    bool largerTargets = true,
    bool reducedMotion = false,
    Handedness handedness = Handedness.right,
  })  : _highContrast = highContrast,
        _largerTargets = largerTargets,
        _reducedMotion = reducedMotion,
        _handedness = handedness;

  bool _highContrast;
  bool _largerTargets;
  bool _reducedMotion;
  Handedness _handedness;

  bool get highContrast => _highContrast;
  bool get largerTargets => _largerTargets;
  bool get reducedMotion => _reducedMotion;
  Handedness get handedness => _handedness;

  /// Minimum tap target — 44pt standard, 54pt when largerTargets is on.
  double get minTapTarget => _largerTargets ? 54 : 44;

  /// True when the bottom HUD / score chips should mirror to the left side.
  bool get mirrorForLeftHand => _handedness == Handedness.left;

  void setHighContrast(bool value) {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
  }

  void setLargerTargets(bool value) {
    if (_largerTargets == value) return;
    _largerTargets = value;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    if (_reducedMotion == value) return;
    _reducedMotion = value;
    notifyListeners();
  }

  void setHandedness(Handedness value) {
    if (_handedness == value) return;
    _handedness = value;
    notifyListeners();
  }
}

enum Handedness { left, right }
