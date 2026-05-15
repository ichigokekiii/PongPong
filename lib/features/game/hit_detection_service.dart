import 'game_models.dart';
import 'paddle_model.dart';

/// Outcome of evaluating a swing against the current ball state.
enum HitOutcome {
  /// Clean hit during the green window.
  hit,

  /// Strong swing during the green window.
  smash,

  /// Player swung but the ball was not in the hit zone (too early/late).
  earlyMiss,

  /// Player swung during the hit window but the swing was too weak.
  weakMiss,

  /// Player never swung.
  noSwing,
}

extension HitOutcomeX on HitOutcome {
  bool get isMiss => switch (this) {
    HitOutcome.hit => false,
    HitOutcome.smash => false,
    _ => true,
  };

  String get readable => switch (this) {
    HitOutcome.hit => 'HIT',
    HitOutcome.smash => 'SMASH',
    HitOutcome.earlyMiss => 'MISS - bad timing',
    HitOutcome.weakMiss => 'MISS - swing too weak',
    HitOutcome.noSwing => 'MISS - no swing',
  };
}

/// Pure decision service that maps a (ball state, swing) pair to an outcome.
class HitDetectionService {
  const HitDetectionService();

  HitOutcome evaluate({
    required BallState ballState,
    required SwingResult swing,
  }) {
    if (!swing.isSwinging) {
      return HitOutcome.noSwing;
    }
    if (ballState != BallState.ready) {
      return HitOutcome.earlyMiss;
    }
    if (swing.strength == SwingStrength.weak) {
      return HitOutcome.weakMiss;
    }
    if (swing.strength == SwingStrength.smash) {
      return HitOutcome.smash;
    }
    return HitOutcome.hit;
  }
}
