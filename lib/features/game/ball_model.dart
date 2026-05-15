import 'game_models.dart';

/// Lightweight model for the virtual ping pong ball state.
class Ball {
  Ball({
    this.state = BallState.far,
    this.speed = 1.0,
    this.lane = BallLane.center,
  });

  BallState state;
  double speed;
  BallLane lane;

  /// Returns a perceived urgency in [0, 1] derived from ball state and speed.
  /// Used to drive blink rate and audio cue rate.
  double get urgency {
    final base = switch (state) {
      BallState.far => 0.2,
      BallState.near => 0.55,
      BallState.ready => 0.9,
      BallState.hit => 0.4,
      BallState.smash => 1.0,
      BallState.missed => 0.0,
    };
    return ((base * speed).clamp(0.0, 1.5)) / 1.5;
  }

  /// Blink interval in milliseconds for the current state/speed combo.
  int get blinkIntervalMs {
    final raw = switch (state) {
      BallState.far => 800.0,
      BallState.near => 480.0,
      BallState.ready => 220.0,
      BallState.hit => 320.0,
      BallState.smash => 140.0,
      BallState.missed => 1200.0,
    };
    return (raw / speed).clamp(80, 1200).round();
  }
}
