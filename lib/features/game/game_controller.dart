import 'package:flutter/foundation.dart';

import '../scan/scanned_area_model.dart';
import 'game_audio_service.dart';
import 'models/game_state_models.dart';

/// Reactive game state holder.
///
/// Each gameplay sub-system (sensors, audio, haptics, scoring) will be wired
/// into this controller by the other hackathon team members. Today everything
/// is exposed as a `ValueNotifier<T>` so the UI can rebuild surgically per
/// signal instead of one giant ChangeNotifier.
///
/// Stub methods used by the DEMO CONTROLS sheet on [GameScreen] simulate
/// real sensor / ball-logic input so reviewers can see every visual state.
class GameController {
  GameController({this.playArea}) {
    _refreshApproachFeedback(immediate: true);
  }

  final GameAudioService _audio = GameAudioService();
  final ScannedAreaModel? playArea;

  // --- Reactive signals -----------------------------------------------------
  final ValueNotifier<BallState> ballState = ValueNotifier(BallState.far);
  final ValueNotifier<BallEdge> ballEdge = ValueNotifier(BallEdge.center);
  final ValueNotifier<BallSpeed> speed = ValueNotifier(BallSpeed.slow);
  final ValueNotifier<SwingEvent> lastEvent = ValueNotifier(SwingEvent.none);
  final ValueNotifier<GameStatus> status = ValueNotifier(GameStatus.playing);
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> rally = ValueNotifier(0);
  final ValueNotifier<int> longestRally = ValueNotifier(0);
  final ValueNotifier<int> hits = ValueNotifier(0);
  final ValueNotifier<int> smashes = ValueNotifier(0);
  final ValueNotifier<int> attempts = ValueNotifier(0);

  // --- Stub hooks (other team members wire these up) ------------------------

  /// TODO(member-3): replace with accelerometer/gyroscope swing classifier.
  void onSwingDetected({required double strength}) {
    // Not used yet — kept so the demo controls can call into the same surface.
  }

  void _emitFeedback(SwingEvent event) {
    _audio.playEvent(event, speed.value);
  }

  // --- Mock state transitions for the demo sheet ----------------------------

  void setBallState(BallState s) {
    if (ballState.value == s) return;
    ballState.value = s;
    _refreshApproachFeedback(immediate: true);
  }

  void setBallEdge(BallEdge e) => ballEdge.value = e;

  void setSpeed(BallSpeed s) {
    if (speed.value == s) return;
    speed.value = s;
    _refreshApproachFeedback(immediate: true);
  }

  void registerHit() {
    score.value += 1;
    rally.value += 1;
    hits.value += 1;
    attempts.value += 1;
    longestRally.value =
        rally.value > longestRally.value ? rally.value : longestRally.value;
    _setEvent(SwingEvent.hit);
    _emitFeedback(SwingEvent.hit);
  }

  void registerSmash() {
    score.value += 3;
    rally.value += 1;
    hits.value += 1;
    smashes.value += 1;
    attempts.value += 1;
    longestRally.value =
        rally.value > longestRally.value ? rally.value : longestRally.value;
    speed.value = BallSpeed.urgent;
    _refreshApproachFeedback(immediate: true);
    _setEvent(SwingEvent.smash);
    _emitFeedback(SwingEvent.smash);
  }

  void registerMiss() {
    attempts.value += 1;
    rally.value = 0;
    _setEvent(SwingEvent.miss);
    _emitFeedback(SwingEvent.miss);
  }

  void _setEvent(SwingEvent e) {
    lastEvent.value = e;
    // Auto-clear so the flash overlay reverts to "none" after ~250 ms.
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (lastEvent.value == e) lastEvent.value = SwingEvent.none;
    });
  }

  void pause() {
    status.value = GameStatus.paused;
    _refreshApproachFeedback();
  }

  void resume() {
    status.value = GameStatus.playing;
    _refreshApproachFeedback(immediate: true);
  }

  void _refreshApproachFeedback({bool immediate = false}) {
    _audio.configureApproach(
      state: ballState.value,
      speed: speed.value,
      status: status.value,
      immediate: immediate,
    );
  }

  /// Computed: hits / attempts as a 0..1 accuracy ratio.
  double get accuracy => attempts.value == 0 ? 0 : hits.value / attempts.value;

  void dispose() {
    _audio.dispose();
    ballState.dispose();
    ballEdge.dispose();
    speed.dispose();
    lastEvent.dispose();
    status.dispose();
    score.dispose();
    rally.dispose();
    longestRally.dispose();
    hits.dispose();
    smashes.dispose();
    attempts.dispose();
  }
}
