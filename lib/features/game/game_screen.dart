import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/audio/game_audio_service.dart';
import '../../core/sensors/motion_sensor_service.dart';
import '../calibration/swing_profile_model.dart';
import '../results/result_screen.dart';
import '../scan/scanned_area_model.dart';
import 'ball_feedback_widget.dart';
import 'ball_model.dart';
import 'game_models.dart';
import 'hit_detection_service.dart';
import 'paddle_model.dart';

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

  // Services
  late final MotionSensorService _motion;
  final GameAudioService _audio = GameAudioService();
  final HitDetectionService _hitDetection = const HitDetectionService();

  // Timers
  Timer? _sessionTimer;
  Timer? _ballTimer;
  Timer? _resultTimer;

  // Subscriptions
  StreamSubscription<SwingResult>? _swingSub;
  StreamSubscription<MotionTelemetry>? _telemetrySub;

  // Match state
  int _secondsRemaining = _matchLengthSeconds;
  int _score = 0;
  int _hits = 0;
  int _smashes = 0;
  int _attempts = 0;
  int _rally = 0;
  int _bestRally = 0;

  final Ball _ball = Ball();
  double _peakBallSpeed = 1;

  GameStatus _status = GameStatus.ready;
  bool _finished = false;
  String _lastEvent = 'Ready to serve';
  String _swingStatusText = 'Waiting for green window';
  String _motionStatus = 'Connecting motion sensors';
  MotionTelemetry _telemetry = MotionTelemetry.zero();
  HitOutcome _lastOutcome = HitOutcome.noSwing;
  SwingStrength _lastSwingStrength = SwingStrength.none;

  @override
  void initState() {
    super.initState();
    _motion = MotionSensorService(profile: widget.args.swingProfile);
    _startSession();
    _initializeMotionSensors();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _ballTimer?.cancel();
    _resultTimer?.cancel();
    _swingSub?.cancel();
    _telemetrySub?.cancel();
    _motion.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _initializeMotionSensors() async {
    _swingSub = _motion.onSwing.listen(_onSwingDetected);
    _telemetrySub = _motion.telemetry.listen((value) {
      if (!mounted) return;
      setState(() => _telemetry = value);
    });

    final ok = await _motion.start();
    if (!mounted) return;
    setState(() {
      _motionStatus = _motion.status;
    });
    if (!ok) {
      _audio.setMuted(false);
    }
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
    final multiplier = 1 / _ball.speed;
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
    if (_finished) return;
    _ballTimer = Timer(_phaseDuration(_ball.state), _advanceBallState);
  }

  void _advanceBallState() {
    if (!mounted || _finished) return;

    switch (_ball.state) {
      case BallState.far:
        setState(() {
          _ball.state = BallState.near;
          _ball.lane = BallLane.values[(_attempts + _hits + _smashes + 1) %
              BallLane.values.length];
          _lastEvent = 'Ball approaching from ${_laneLabel(_ball.lane)}';
          _swingStatusText = 'Yellow · prepare to swing';
        });
        _audio.startApproachLoop(speedMultiplier: _ball.speed);
        _scheduleBallPhase();
      case BallState.near:
        setState(() {
          _ball.state = BallState.ready;
          _attempts += 1;
          _lastEvent = 'Hit window OPEN — swing now!';
          _swingStatusText = 'Green · swing now';
        });
        _audio.startApproachLoop(speedMultiplier: _ball.speed, urgent: true);
        _scheduleBallPhase();
      case BallState.ready:
        _audio.stopApproachLoop();
        _finishGame(missed: true, event: 'No swing during the green window');
      case BallState.hit:
      case BallState.smash:
      case BallState.missed:
        _audio.stopApproachLoop();
        setState(() {
          _ball.state = BallState.far;
          _status = GameStatus.playing;
          _lastEvent = 'Return ball launched';
          _swingStatusText = 'Red · ball is far';
        });
        _scheduleBallPhase();
    }
  }

  void _onSwingDetected(SwingResult swing) {
    _registerSwing(swing);
  }

  void _registerSwing(SwingResult swing) {
    if (_finished) return;

    final outcome = _hitDetection.evaluate(
      ballState: _ball.state,
      swing: swing,
    );

    _lastOutcome = outcome;
    _lastSwingStrength = swing.strength;

    if (outcome.isMiss) {
      _audio.stopApproachLoop();
      _audio.playMiss();
      _finishGame(missed: true, event: outcome.readable);
      return;
    }

    final isSmash = outcome == HitOutcome.smash;

    setState(() {
      _hits += 1;
      _rally += 1;
      _bestRally = math.max(_bestRally, _rally);
      _ball.speed = (_ball.speed + (isSmash ? 0.45 : 0.18)).clamp(1, 3.5);
      _peakBallSpeed = math.max(_peakBallSpeed, _ball.speed);

      if (isSmash) {
        _smashes += 1;
        _score += 3;
        _status = GameStatus.smash;
        _ball.state = BallState.smash;
        _lastEvent = 'SMASH connected (+3)';
      } else {
        _score += 1;
        _status = GameStatus.hit;
        _ball.state = BallState.hit;
        _lastEvent = 'Clean HIT (+1)';
      }

      if (_rally > 0 && _rally % 5 == 0) {
        _score += 2;
        _lastEvent = '$_lastEvent · streak bonus +2';
      }
      _swingStatusText =
          'Last swing: ${swing.label} · ${swing.acceleration.toStringAsFixed(1)} m/s²';
    });

    _audio.stopApproachLoop();
    if (isSmash) {
      _audio.playSmash();
    } else {
      _audio.playHit();
    }

    _scheduleBallPhase();
  }

  // Manual override button used as a fallback when motion sensors are not
  // available (e.g. desktop / web preview).
  void _manualSwing({required bool smash}) {
    final strength = smash ? SwingStrength.smash : SwingStrength.normal;
    _registerSwing(
      SwingResult(
        strength: strength,
        acceleration: smash ? 9.0 : 5.0,
        gyro: smash ? 6.5 : 3.0,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _finishGame({required bool missed, required String event}) {
    if (_finished) return;

    _sessionTimer?.cancel();
    _ballTimer?.cancel();
    _audio.stopApproachLoop();

    setState(() {
      _finished = true;
      _status = missed ? GameStatus.missed : GameStatus.gameOver;
      _ball.state = missed ? BallState.missed : _ball.state;
      _lastEvent = event;
    });

    _resultTimer = Timer(const Duration(milliseconds: 900), _goToResults);
  }

  void _goToResults() {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final accuracy = _attempts == 0 ? 0.0 : _hits / _attempts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PhonePong'),
        actions: [
          IconButton(
            icon: Icon(_audio.isMuted ? Icons.volume_off : Icons.volume_up),
            tooltip: _audio.isMuted ? 'Unmute cues' : 'Mute cues',
            onPressed: () {
              setState(() => _audio.toggleMute());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ScoreCard(label: 'Score', value: _score.toString()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreCard(label: 'Rally', value: _rally.toString()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ScoreCard(label: 'State', value: _status.name),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BallStateLegend(currentState: _ball.state),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    BallFeedbackArena(
                      ball: _ball,
                      lastEvent: _lastEvent,
                      swingStatusText: _swingStatusText,
                    ),
                    const SizedBox(height: 12),
                    _IntegrationPanel(
                      title: 'Spatial scan (HART)',
                      subtitle: 'Play area data wired from scan screen',
                      metrics: [
                        'Width ${widget.args.playArea.widthLabel}',
                        'Length ${widget.args.playArea.lengthLabel}',
                        'Hit zone ${widget.args.playArea.hitZone.toStringAsFixed(2)} m',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _IntegrationPanel(
                      title: 'Motion paddle (SETH)',
                      subtitle: _motionStatus,
                      metrics: [
                        'Hand ${widget.args.swingProfile.handLabel}',
                        'Accel ${_telemetry.acceleration.toStringAsFixed(1)} m/s²',
                        'Gyro ${_telemetry.gyro.toStringAsFixed(1)} rad/s',
                        'Last ${_lastSwingStrength.name}',
                        'Outcome ${_lastOutcome.readable}',
                      ],
                    ),
                    const SizedBox(height: 10),
                    _IntegrationPanel(
                      title: 'Sound + light (JOHN)',
                      subtitle: _audio.isMuted
                          ? 'Cues muted'
                          : 'Cues speed up with ball speed',
                      metrics: [
                        'Ball ${_ball.state.name}',
                        'Cue speed ${_ball.speed.toStringAsFixed(2)}x',
                        'Blink ${_ball.blinkIntervalMs}ms',
                        'Accuracy ${(accuracy * 100).toStringAsFixed(0)}%',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _manualSwing(smash: false),
                    child: Text(
                      _motion.isAvailable ? 'Manual Hit Override' : 'Hit Swing',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _manualSwing(smash: true),
                    child: Text(
                      _motion.isAvailable
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
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
