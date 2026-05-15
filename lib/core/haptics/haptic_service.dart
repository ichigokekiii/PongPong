import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so the rest of the app does not have
/// to import a Flutter SDK class everywhere it triggers a vibration.
class HapticService {
  const HapticService();

  Future<void> tap() => HapticFeedback.selectionClick();
  Future<void> light() => HapticFeedback.lightImpact();
  Future<void> medium() => HapticFeedback.mediumImpact();
  Future<void> heavy() => HapticFeedback.heavyImpact();
  Future<void> miss() => HapticFeedback.vibrate();
}
