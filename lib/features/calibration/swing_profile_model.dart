enum DominantHand { left, right }

class SwingProfile {
  const SwingProfile({
    required this.dominantHand,
    required this.hitThreshold,
    required this.smashThreshold,
    required this.sensitivity,
  });

  final DominantHand dominantHand;
  final double hitThreshold;
  final double smashThreshold;
  final double sensitivity;

  String get handLabel =>
      dominantHand == DominantHand.left ? 'Left-handed' : 'Right-handed';

  factory SwingProfile.demo() {
    return const SwingProfile(
      dominantHand: DominantHand.right,
      hitThreshold: 4.5,
      smashThreshold: 7.8,
      sensitivity: 0.72,
    );
  }

  SwingProfile copyWith({
    DominantHand? dominantHand,
    double? hitThreshold,
    double? smashThreshold,
    double? sensitivity,
  }) {
    return SwingProfile(
      dominantHand: dominantHand ?? this.dominantHand,
      hitThreshold: hitThreshold ?? this.hitThreshold,
      smashThreshold: smashThreshold ?? this.smashThreshold,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }
}
