import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/routes.dart';
import '../calibration/swing_profile_model.dart';
import '../results/result_screen.dart';
import '../scan/scanned_area_model.dart';
import 'game_models.dart';

class GameScreenArgs {
  const GameScreenArgs({required this.playArea, required this.swingProfile});

  final ScannedArea playArea;
  final SwingProfile swingProfile;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.args});

  final GameScreenArgs args;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _matchLengthSeconds = 45;

  Timer? _sessionTimer;
  Timer? _ballTimer;
  Timer? _resultTimer;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  int _secondsRemaining = _matchLengthSeconds;
  int _score = 0;
  int _hits = 0;
  int _smashes = 0;
  int _attempts = 0;
  int _rally = 0;
  int _bestRally = 0;

  double _ballSpeed = 1;
  double _peakBallSpeed = 1;
  double _liveAcceleration = 0;
  double _liveGyro = 0;

  BallState _ballState = BallState.far;
  GameStatus _status = GameStatus.ready;
  BallLane _ballLane = BallLane.left;
  bool _canSwing = false;
  bool _finished = false;
  bool _motionAvailable = false;
  String _lastEvent = 'Ready to serve';
  String _motionStatus = 'Connecting motion sensors';
  DateTime _lastDetectedSwing = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _startSession();
    _initializeMotionSensors();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _ballTimer?.cancel();
    _resultTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMotionSensors() async {
    try {
      _accelerometerSubscription = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          if (!mounted) {
            return;
          }

          setState(() {
            _liveAcceleration = _vectorMagnitude(event.x, event.y, event.z);
          });

          _maybeRegisterSensorSwing();
        },
        onError: _handleMotionError,
      );

      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (event) {
          if (!mounted) {
            return;
          }

          setState(() {
            _liveGyro = _vectorMagnitude(event.x, event.y, event.z);
          });

          _maybeRegisterSensorSwing();
        },
        onError: _handleMotionError,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _motionAvailable = true;
        _motionStatus = 'Live accelerometer + gyroscope feed';
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }

      setState(() {
        _motionStatus = 'Motion sensors are unavailable in this environment';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _motionStatus = 'Unable to connect to motion sensors';
      });
    }
  }

  void _handleMotionError(Object _) {
    if (!mounted) {
      return;
    }

    setState(() {
      _motionAvailable = false;
      _motionStatus = 'Unable to read motion sensor data';
    });
  }

  double _vectorMagnitude(double x, double y, double z) {
    return math.sqrt((x * x) + (y * y) + (z * z));
  }

  void _maybeRegisterSensorSwing() {
    if (!_motionAvailable || _finished || _ballState != BallState.ready) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastDetectedSwing) < const Duration(milliseconds: 800)) {
      return;
    }

    final accelerationThreshold = widget.args.swingProfile.hitThreshold;
    final smashThreshold = widget.args.swingProfile.smashThreshold;

    if (_liveAcceleration < accelerationThreshold || _liveGyro < 2.2) {
      return;
    }

    _lastDetectedSwing = now;
    _registerSwing(
      smash: _liveAcceleration >= smashThreshold || _liveGyro >= 6,
    );
  }

  void _startSession() {
    _status = GameStatus.playing;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finished) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        _finishGame(missed: false, event: 'Match timer expired');
        return;
      }

      setState(() {
        _secondsRemaining -= 1;
      });
    });

    _scheduleBallPhase();
  }

  Duration _phaseDuration(BallState state) {
    final multiplier = 1 / _ballSpeed;
    switch (state) {
      case BallState.far:
        return Duration(
          milliseconds: math.max((1500 * multiplier).round(), 450),
        );
      case BallState.near:
        return Duration(
          milliseconds: math.max((950 * multiplier).round(), 320),
        );
      case BallState.ready:
        return Duration(
          milliseconds: math.max((850 * multiplier).round(), 280),
        );
      case BallState.hit:
      case BallState.smash:
      case BallState.missed:
        return const Duration(milliseconds: 700);
    }
  }

  void _scheduleBallPhase() {
    _ballTimer?.cancel();
    if (_finished) {
      return;
    }

    _ballTimer = Timer(_phaseDuration(_ballState), _advanceBallState);
  }

  void _advanceBallState() {
    if (!mounted || _finished) {
      return;
    }

    switch (_ballState) {
      case BallState.far:
        setState(() {
          _ballState = BallState.near;
          _ballLane =
              BallLane.values[(_attempts + _hits + _smashes + 1) %
                  BallLane.values.length];
          _lastEvent = 'Ball approaching from ${_laneLabel(_ballLane)}';
        });
        _scheduleBallPhase();
      case BallState.near:
        setState(() {
          _ballState = BallState.ready;
          _canSwing = true;
          _attempts += 1;
          _lastEvent = 'Hit window open';
        });
        _scheduleBallPhase();
      case BallState.ready:
        _finishGame(missed: true, event: 'Missed the ready window');
      case BallState.hit:
      case BallState.smash:
      case BallState.missed:
        setState(() {
          _ballState = BallState.far;
          _status = GameStatus.playing;
          _lastEvent = 'Return ball launched';
        });
        _scheduleBallPhase();
    }
  }

  void _registerSwing({required bool smash}) {
    if (_finished) {
      return;
    }

    if (!_canSwing || _ballState != BallState.ready) {
      _finishGame(
        missed: true,
        event: 'Swing timing was outside the hit window',
      );
      return;
    }

    setState(() {
      _canSwing = false;
      _hits += 1;
      _rally += 1;
      _bestRally = math.max(_bestRally, _rally);
      _ballSpeed = (_ballSpeed + (smash ? 0.45 : 0.18)).clamp(1, 3.5);
      _peakBallSpeed = math.max(_peakBallSpeed, _ballSpeed);

      if (smash) {
        _smashes += 1;
        _score += 3;
        _status = GameStatus.smash;
        _ballState = BallState.smash;
        _lastEvent = 'Smash connected';
      } else {
        _score += 1;
        _status = GameStatus.hit;
        _ballState = BallState.hit;
        _lastEvent = 'Clean hit';
      }

      if (_rally > 0 && _rally % 5 == 0) {
        _score += 2;
        _lastEvent = 'Streak bonus activated';
      }
    });

    _scheduleBallPhase();
  }

  void _finishGame({required bool missed, required String event}) {
    if (_finished) {
      return;
    }

    _sessionTimer?.cancel();
    _ballTimer?.cancel();

    setState(() {
      _finished = true;
      _canSwing = false;
      _status = missed ? GameStatus.missed : GameStatus.gameOver;
      _ballState = missed ? BallState.missed : _ballState;
      _lastEvent = event;
    });

    _resultTimer = Timer(const Duration(milliseconds: 900), _goToResults);
  }

  void _goToResults() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.results,
      arguments: ResultScreenArgs(
        result: GameResult(
          score: _score,
          hits: _hits,
          smashes: _smashes,
          longestRally: _bestRally,
          durationSeconds: _matchLengthSeconds - _secondsRemaining,
          accuracy: _attempts == 0 ? 0 : _hits / _attempts,
          peakBallSpeed: _peakBallSpeed,
        ),
        playArea: widget.args.playArea,
        swingProfile: widget.args.swingProfile,
      ),
    );
  }

  String _laneLabel(BallLane lane) {
    switch (lane) {
      case BallLane.left:
        return 'left';
      case BallLane.right:
        return 'right';
      case BallLane.center:
        return 'center';
    }
  }

  Color _ballColor() {
    switch (_ballState) {
      case BallState.far:
        return const Color(0xFFE76F51);
      case BallState.near:
        return const Color(0xFFF4A261);
      case BallState.ready:
        return const Color(0xFF2A9D8F);
      case BallState.hit:
        return const Color(0xFF3D5A80);
      case BallState.smash:
        return const Color(0xFFE63946);
      case BallState.missed:
        return const Color(0xFF7D8597);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _attempts == 0 ? 0.0 : _hits / _attempts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                '${_secondsRemaining}s',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ScoreCard(label: 'Score', value: _score.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreCard(label: 'Rally', value: _rally.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreCard(label: 'State', value: _status.name),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _FeedbackArena(
                      color: _ballColor(),
                      state: _ballState,
                      lane: _ballLane,
                      ballSpeed: _ballSpeed,
                      lastEvent: _lastEvent,
                    ),
                    const SizedBox(height: 16),
                    _IntegrationPanel(
                      title: 'Spatial scan integration',
                      subtitle: 'Member 2 handoff',
                      metrics: [
                        'Width ${widget.args.playArea.widthLabel}',
                        'Length ${widget.args.playArea.lengthLabel}',
                        'Hit zone ${widget.args.playArea.hitZone.toStringAsFixed(2)} m',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _IntegrationPanel(
                      title: 'Motion paddle integration',
                      subtitle: _motionStatus,
                      metrics: [
                        'Hand ${widget.args.swingProfile.handLabel}',
                        'Accel ${_liveAcceleration.toStringAsFixed(1)} m/s²',
                        'Gyro ${_liveGyro.toStringAsFixed(1)} rad/s',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _IntegrationPanel(
                      title: 'Feedback system integration',
                      subtitle: 'Member 4 handoff',
                      metrics: [
                        'Ball ${_ballState.name}',
                        'Cue speed ${_ballSpeed.toStringAsFixed(2)}x',
                        'Accuracy ${(accuracy * 100).toStringAsFixed(0)}%',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _registerSwing(smash: false),
                    child: Text(
                      _motionAvailable ? 'Manual Hit Override' : 'Hit Swing',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _registerSwing(smash: true),
                    child: Text(
                      _motionAvailable
                          ? 'Manual Smash Override'
                          : 'Smash Swing',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _FeedbackArena extends StatelessWidget {
  const _FeedbackArena({
    required this.color,
    required this.state,
    required this.lane,
    required this.ballSpeed,
    required this.lastEvent,
  });

  final Color color;
  final BallState state;
  final BallLane lane;
  final double ballSpeed;
  final String lastEvent;

  @override
  Widget build(BuildContext context) {
    final edgeGlow = color.withValues(alpha: 0.75);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.5)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ball ${state.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                '${ballSpeed.toStringAsFixed(2)}x speed',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: _EdgePulse(
                    active: state == BallState.far,
                    color: edgeGlow,
                    horizontal: true,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _EdgePulse(
                    active: state == BallState.near,
                    color: edgeGlow,
                    horizontal: true,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _EdgePulse(
                    active: lane == BallLane.left,
                    color: edgeGlow,
                    horizontal: false,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _EdgePulse(
                    active: lane == BallLane.right,
                    color: edgeGlow,
                    horizontal: false,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    width: state == BallState.ready ? 116 : 88,
                    height: state == BallState.ready ? 116 : 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: state == BallState.ready ? 0.9 : 0.3,
                      ),
                    ),
                    child: Icon(
                      state == BallState.ready
                          ? Icons.sports_tennis
                          : Icons.motion_photos_on_outlined,
                      color: state == BallState.ready ? color : Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lastEvent,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EdgePulse extends StatelessWidget {
  const _EdgePulse({
    required this.active,
    required this.color,
    required this.horizontal,
  });

  final bool active;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: horizontal ? 170 : 14,
      height: horizontal ? 14 : 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active ? color : Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

class _IntegrationPanel extends StatelessWidget {
  const _IntegrationPanel({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<String> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics.map((item) => Chip(label: Text(item))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
