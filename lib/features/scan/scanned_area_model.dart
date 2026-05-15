enum ScanStep { leftBoundary, rightBoundary, forwardLength, confirm }

class ScannedAreaModel {
  const ScannedAreaModel({
    required this.leftReachMeters,
    required this.rightReachMeters,
    required this.lengthMeters,
  });

  final double leftReachMeters;
  final double rightReachMeters;
  final double lengthMeters;

  double get widthMeters => leftReachMeters + rightReachMeters;
  double get playAreaSizeSquareMeters => widthMeters * lengthMeters;

  ScannedAreaModel copyWith({
    double? leftReachMeters,
    double? rightReachMeters,
    double? lengthMeters,
  }) {
    return ScannedAreaModel(
      leftReachMeters: leftReachMeters ?? this.leftReachMeters,
      rightReachMeters: rightReachMeters ?? this.rightReachMeters,
      lengthMeters: lengthMeters ?? this.lengthMeters,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'leftReachMeters': leftReachMeters,
      'rightReachMeters': rightReachMeters,
      'lengthMeters': lengthMeters,
    };
  }

  factory ScannedAreaModel.fromJson(Map<String, dynamic> json) {
    return ScannedAreaModel(
      leftReachMeters: (json['leftReachMeters'] as num?)?.toDouble() ?? 1.2,
      rightReachMeters: (json['rightReachMeters'] as num?)?.toDouble() ?? 1.3,
      lengthMeters: (json['lengthMeters'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

extension ScanStepPresentation on ScanStep {
  String get subtitle {
    switch (this) {
      case ScanStep.leftBoundary:
        return 'Mark the left edge of the rally zone.';
      case ScanStep.rightBoundary:
        return 'Capture the right edge to finish the width scan.';
      case ScanStep.forwardLength:
        return 'Measure the forward depth of the play area.';
      case ScanStep.confirm:
        return 'Review the generated court before calibration.';
    }
  }

  String get progressLabel {
    switch (this) {
      case ScanStep.leftBoundary:
      case ScanStep.rightBoundary:
        return 'Scanning width...';
      case ScanStep.forwardLength:
        return 'Scanning length...';
      case ScanStep.confirm:
        return 'Play area ready';
    }
  }

  String get previewLabel {
    switch (this) {
      case ScanStep.leftBoundary:
        return 'Scanning width: left boundary';
      case ScanStep.rightBoundary:
        return 'Scanning width: right boundary';
      case ScanStep.forwardLength:
        return 'Scanning length: forward boundary';
      case ScanStep.confirm:
        return 'Play area ready';
    }
  }

  static ScanStep fromName(String value) {
    return ScanStep.values.firstWhere(
      (step) => step.name == value,
      orElse: () => ScanStep.leftBoundary,
    );
  }
}
