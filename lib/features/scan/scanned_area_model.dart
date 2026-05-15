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

  static const defaults = ScannedAreaModel(
    widthMeters: 2.5,
    lengthMeters: 3.0,
    leftBoundaryCaptured: false,
    rightBoundaryCaptured: false,
    lengthCaptured: false,
  );

  bool get isReady =>
      leftBoundaryCaptured && rightBoundaryCaptured && lengthCaptured;
  double get playAreaSizeSquareMeters =>
      _roundToTenth(widthMeters * lengthMeters);

  double get nearZoneMeters =>
      _roundToTenth((lengthMeters * 0.35).clamp(0.8, 1.4));
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
      leftBoundaryCaptured: leftBoundaryCaptured ?? this.leftBoundaryCaptured,
      rightBoundaryCaptured:
          rightBoundaryCaptured ?? this.rightBoundaryCaptured,
      lengthCaptured: lengthCaptured ?? this.lengthCaptured,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'widthMeters': widthMeters,
      'lengthMeters': lengthMeters,
      'leftBoundaryCaptured': leftBoundaryCaptured,
      'rightBoundaryCaptured': rightBoundaryCaptured,
      'lengthCaptured': lengthCaptured,
    };
  }

  factory ScannedAreaModel.fromJson(Map<String, Object?> json) {
    return ScannedAreaModel(
      widthMeters: _readDouble(json['widthMeters'], defaults.widthMeters),
      lengthMeters: _readDouble(json['lengthMeters'], defaults.lengthMeters),
      leftBoundaryCaptured:
          json['leftBoundaryCaptured'] as bool? ?? defaults.leftBoundaryCaptured,
      rightBoundaryCaptured: json['rightBoundaryCaptured'] as bool? ??
          defaults.rightBoundaryCaptured,
      lengthCaptured:
          json['lengthCaptured'] as bool? ?? defaults.lengthCaptured,
    );
  }

  ScannedAreaModel markReady() {
    return copyWith(
      leftBoundaryCaptured: true,
      rightBoundaryCaptured: true,
      lengthCaptured: true,
    );
  }

  static double _readDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  static double _roundToTenth(double value) =>
      (value * 10).roundToDouble() / 10;
}
