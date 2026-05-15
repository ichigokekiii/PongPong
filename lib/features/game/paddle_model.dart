/// Classifies how strongly the player swung the phone.
enum SwingStrength { none, weak, normal, smash }

/// A single detected swing event coming out of the motion sensor service.
class SwingResult {
  const SwingResult({
    required this.strength,
    required this.acceleration,
    required this.gyro,
    required this.timestamp,
  });

  factory SwingResult.idle() => SwingResult(
    strength: SwingStrength.none,
    acceleration: 0,
    gyro: 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  final SwingStrength strength;
  final double acceleration;
  final double gyro;
  final DateTime timestamp;

  bool get isSwinging => strength != SwingStrength.none;
  bool get isHit =>
      strength == SwingStrength.normal || strength == SwingStrength.smash;
  bool get isSmash => strength == SwingStrength.smash;
  bool get isWeak => strength == SwingStrength.weak;

  String get label {
    switch (strength) {
      case SwingStrength.smash:
        return 'Smash swing';
      case SwingStrength.normal:
        return 'Normal swing';
      case SwingStrength.weak:
        return 'Weak swing';
      case SwingStrength.none:
        return 'No swing';
    }
  }
}
