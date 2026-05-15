/// Ball distance state — drives the dominant screen color.
enum BallState {
  /// Ball is far. Red. Do not swing.
  far,

  /// Ball is approaching. Yellow. Prepare.
  near,

  /// Ball is in the hit zone. Green. Swing NOW.
  ready,
}

/// Direction the ball is travelling, mapped to a screen edge.
enum BallEdge { top, right, bottom, left, center }

/// Last gameplay event — drives the flash overlay.
enum SwingEvent { none, hit, smash, miss }

/// Top-level game lifecycle status.
enum GameStatus { playing, paused, ended }

/// Speed tier — drives blink rate. Each step roughly doubles intensity.
enum BallSpeed { slow, normal, fast, urgent }
