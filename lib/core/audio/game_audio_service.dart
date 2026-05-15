import 'dart:async';

import 'package:flutter/services.dart';

import '../haptics/haptic_service.dart';

/// Centralizes ping-pong style audio + haptic cues. Because the MVP ships
/// without bundled audio assets, the service falls back on `SystemSound` clicks
/// + haptics. The "approach" cue is driven by a timer whose interval shrinks
/// as the ball gets faster, which is the audible equivalent of the green
/// indicator pulsing harder.
class GameAudioService {
  GameAudioService({HapticService? haptics})
    : _haptics = haptics ?? const HapticService();

  final HapticService _haptics;

  Timer? _approachTimer;
  bool _muted = false;

  bool get isMuted => _muted;

  void setMuted(bool value) {
    _muted = value;
    if (_muted) {
      stopApproachLoop();
    }
  }

  void toggleMute() => setMuted(!_muted);

  void playHit() {
    if (_muted) return;
    SystemSound.play(SystemSoundType.click);
    _haptics.medium();
  }

  void playSmash() {
    if (_muted) return;
    SystemSound.play(SystemSoundType.click);
    _haptics.heavy();
  }

  void playMiss() {
    if (_muted) return;
    SystemSound.play(SystemSoundType.alert);
    _haptics.miss();
  }

  void playApproachTick({bool urgent = false}) {
    if (_muted) return;
    SystemSound.play(SystemSoundType.click);
    if (urgent) {
      _haptics.light();
    } else {
      _haptics.tap();
    }
  }

  /// Starts (or restarts) a periodic approach cue whose interval is derived
  /// from the current ball speed multiplier. Faster ball → shorter interval.
  void startApproachLoop({required double speedMultiplier, bool urgent = false}) {
    stopApproachLoop();
    final base = urgent ? 320.0 : 650.0;
    final interval = (base / speedMultiplier).clamp(120.0, 900.0).round();
    _approachTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => playApproachTick(urgent: urgent),
    );
  }

  void stopApproachLoop() {
    _approachTimer?.cancel();
    _approachTimer = null;
  }

  void dispose() {
    stopApproachLoop();
  }
}
