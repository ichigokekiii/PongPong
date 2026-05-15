class ScannedAreaModel {
  const ScannedAreaModel({
    required this.widthMeters,
    required this.lengthMeters,
    required this.leftBoundaryCaptured,
    required this.rightBoundaryCaptured,
    required this.lengthCaptured,
  });

  final double widthMeters;
  final double lengthMeters;
  final bool leftBoundaryCaptured;
  final bool rightBoundaryCaptured;
  final bool lengthCaptured;

  bool get isReady =>
      leftBoundaryCaptured && rightBoundaryCaptured && lengthCaptured;

  double get nearZoneMeters => _roundToTenth((lengthMeters * 0.35).clamp(0.8, 1.4));
  double get hitZoneStartMeters =>
      _roundToTenth((lengthMeters * 0.45).clamp(1.0, 1.8));
  double get hitZoneEndMeters =>
      _roundToTenth((lengthMeters * 0.62).clamp(1.5, lengthMeters - 0.2));
  double get farZoneStartMeters =>
      _roundToTenth((lengthMeters * 0.75).clamp(1.8, lengthMeters));

  ScannedAreaModel copyWith({
    double? widthMeters,
    double? lengthMeters,
    bool? leftBoundaryCaptured,
    bool? rightBoundaryCaptured,
    bool? lengthCaptured,
  }) {
    return ScannedAreaModel(
      widthMeters: widthMeters ?? this.widthMeters,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      leftBoundaryCaptured:
          leftBoundaryCaptured ?? this.leftBoundaryCaptured,
      rightBoundaryCaptured:
          rightBoundaryCaptured ?? this.rightBoundaryCaptured,
      lengthCaptured: lengthCaptured ?? this.lengthCaptured,
    );
  }

  static double _roundToTenth(double value) =>
      (value * 10).roundToDouble() / 10;
}
