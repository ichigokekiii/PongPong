class ScannedArea {
  const ScannedArea({
    required this.width,
    required this.length,
    required this.nearZone,
    required this.hitZone,
  });

  final double width;
  final double length;
  final double nearZone;
  final double hitZone;

  bool get isReady => width > 0 && length > 0;

  String get widthLabel => '${width.toStringAsFixed(1)} m';
  String get lengthLabel => '${length.toStringAsFixed(1)} m';

  factory ScannedArea.empty() {
    return const ScannedArea(width: 0, length: 0, nearZone: 0.8, hitZone: 0.5);
  }

  factory ScannedArea.demo() {
    return const ScannedArea(
      width: 2.6,
      length: 3.2,
      nearZone: 1.0,
      hitZone: 0.55,
    );
  }

  ScannedArea copyWith({
    double? width,
    double? length,
    double? nearZone,
    double? hitZone,
  }) {
    return ScannedArea(
      width: width ?? this.width,
      length: length ?? this.length,
      nearZone: nearZone ?? this.nearZone,
      hitZone: hitZone ?? this.hitZone,
    );
  }
}
