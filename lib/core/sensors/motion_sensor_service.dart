import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../features/calibration/swing_profile_model.dart';
import '../../features/game/paddle_model.dart';

/// Live numeric telemetry that the UI can subscribe to for debug display.
class MotionTelemetry {
  const MotionTelemetry({required this.acceleration, required this.gyro});

  final double acceleration;
  final double gyro;

  factory MotionTelemetry.zero() =>
      const MotionTelemetry(acceleration: 0, gyro: 0);
}

/// Wraps the `sensors_plus` accelerometer + gyroscope streams and emits
/// classified [SwingResult] events when the player swings the phone.
class MotionSensorService {
  MotionSensorService({required SwingProfile profile}) : _profile = profile;

  SwingProfile _profile;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final StreamController<SwingResult> _swingController =
      StreamController<SwingResult>.broadcast();
  final StreamController<MotionTelemetry> _telemetryController =
      StreamController<MotionTelemetry>.broadcast();

  Stream<SwingResult> get onSwing => _swingController.stream;
  Stream<MotionTelemetry> get telemetry => _telemetryController.stream;

  double _lastAccel = 0;
  double _lastGyro = 0;
  DateTime _lastSwing = DateTime.fromMillisecondsSinceEpoch(0);

  bool _available = false;
  bool get isAvailable => _available;

  String _status = 'Connecting motion sensors';
  String get status => _status;

  void updateProfile(SwingProfile profile) {
    _profile = profile;
  }

  /// Initializes both sensor streams. Returns `true` when both feeds are live.
  Future<bool> start() async {
    try {
      _accelSub = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          _lastAccel = _magnitude(event.x, event.y, event.z);
          _emit();
          _maybeDetectSwing();
        },
        onError: _handleError,
      );

      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          _lastGyro = _magnitude(event.x, event.y, event.z);
          _emit();
          _maybeDetectSwing();
        },
        onError: _handleError,
      );

      _available = true;
      _status = 'Live accelerometer + gyroscope feed';
      return true;
    } on MissingPluginException {
      _available = false;
      _status = 'Motion sensors are unavailable in this environment';
      return false;
    } catch (_) {
      _available = false;
      _status = 'Unable to connect to motion sensors';
      return false;
    }
  }

  Future<void> dispose() async {
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _swingController.close();
    await _telemetryController.close();
  }

  void _emit() {
    if (_telemetryController.isClosed) return;
    _telemetryController.add(
      MotionTelemetry(acceleration: _lastAccel, gyro: _lastGyro),
    );
  }

  void _handleError(Object _) {
    _available = false;
    _status = 'Unable to read motion sensor data';
  }

  double _magnitude(double x, double y, double z) =>
      math.sqrt((x * x) + (y * y) + (z * z));

  void _maybeDetectSwing() {
    final now = DateTime.now();
    if (now.difference(_lastSwing) < const Duration(milliseconds: 700)) {
      return;
    }

    // Sensitivity (0.2 - 1.0) lowers the thresholds so a more sensitive
    // calibration triggers a swing at lower force.
    final s = _profile.sensitivity.clamp(0.2, 1.0);
    final hitT = _profile.hitThreshold * (1.4 - s);
    final smashT = _profile.smashThreshold * (1.4 - s);
    final weakT = hitT * 0.55;

    SwingStrength strength = SwingStrength.none;
    if (_lastAccel >= smashT || _lastGyro >= 6) {
      strength = SwingStrength.smash;
    } else if (_lastAccel >= hitT && _lastGyro >= 2.2) {
      strength = SwingStrength.normal;
    } else if (_lastAccel >= weakT && _lastGyro >= 1.4) {
      strength = SwingStrength.weak;
    }

    if (strength == SwingStrength.none) {
      return;
    }

    _lastSwing = now;
    if (_swingController.isClosed) return;
    _swingController.add(
      SwingResult(
        strength: strength,
        acceleration: _lastAccel,
        gyro: _lastGyro,
        timestamp: now,
      ),
    );
  }
}
