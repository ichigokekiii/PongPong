import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'models/game_state_models.dart';

/// Tiny arcade audio engine for gameplay feedback.
///
/// Sounds are generated as short WAV buffers at runtime, which keeps the MVP
/// self-contained while still allowing distinct hit / smash / miss / approach
/// cues without shipping external audio assets.
class GameAudioService {
  GameAudioService() {
    unawaited(_eventPlayer.setReleaseMode(ReleaseMode.stop));
    unawaited(_approachPlayer.setReleaseMode(ReleaseMode.stop));
  }

  static const int _sampleRate = 22050;

  final AudioPlayer _eventPlayer = AudioPlayer(playerId: 'game_event');
  final AudioPlayer _approachPlayer = AudioPlayer(playerId: 'game_approach');
  final Map<String, Uint8List> _toneCache = <String, Uint8List>{};

  Timer? _approachTimer;
  BallState _state = BallState.far;
  BallSpeed _speed = BallSpeed.slow;
  GameStatus _status = GameStatus.playing;

  void configureApproach({
    required BallState state,
    required BallSpeed speed,
    required GameStatus status,
    bool immediate = false,
  }) {
    final changed = state != _state || speed != _speed || status != _status;
    _state = state;
    _speed = speed;
    _status = status;

    if (!changed && !immediate) return;
    _approachTimer?.cancel();

    if (_status != GameStatus.playing) {
      unawaited(_approachPlayer.stop());
      return;
    }

    if (immediate) _playApproachTick();
    _scheduleApproachTick();
  }

  void playEvent(SwingEvent event, BallSpeed speed) {
    if (event == SwingEvent.none) return;

    final bytes = switch (event) {
      SwingEvent.hit => _tone(
          key: 'hit-${speed.name}',
          startHz: _pitchForSpeed(720, speed),
          endHz: _pitchForSpeed(940, speed),
          durationMs: 110,
          square: false,
        ),
      SwingEvent.smash => _tone(
          key: 'smash-${speed.name}',
          startHz: _pitchForSpeed(1240, speed),
          endHz: _pitchForSpeed(520, speed),
          durationMs: 190,
          square: true,
        ),
      SwingEvent.miss => _tone(
          key: 'miss-${speed.name}',
          startHz: _pitchForSpeed(320, speed),
          endHz: _pitchForSpeed(120, speed),
          durationMs: 220,
          square: false,
        ),
      SwingEvent.none => Uint8List(0),
    };

    _play(_eventPlayer, bytes, volume: event == SwingEvent.smash ? 0.82 : 0.68);
  }

  void dispose() {
    _approachTimer?.cancel();
    unawaited(_eventPlayer.dispose());
    unawaited(_approachPlayer.dispose());
  }

  void _scheduleApproachTick() {
    _approachTimer = Timer(_approachPeriod(_state, _speed), () {
      if (_status != GameStatus.playing) return;
      _playApproachTick();
      _scheduleApproachTick();
    });
  }

  void _playApproachTick() {
    final baseHz = switch (_state) {
      BallState.far => 260.0,
      BallState.near => 520.0,
      BallState.ready => 780.0,
    };
    final volume = switch (_state) {
      BallState.far => 0.22,
      BallState.near => 0.34,
      BallState.ready => 0.46,
    };
    final hz = _pitchForSpeed(baseHz, _speed);
    final bytes = _tone(
      key: 'approach-${_state.name}-${_speed.name}',
      startHz: hz,
      endHz: hz * 1.12,
      durationMs: 64,
      square: _state == BallState.ready,
    );
    _play(_approachPlayer, bytes, volume: volume);
  }

  static Duration _approachPeriod(BallState state, BallSpeed speed) {
    final baseMs = switch (state) {
      BallState.far => 1150,
      BallState.near => 620,
      BallState.ready => 280,
    };
    final multiplier = switch (speed) {
      BallSpeed.slow => 1.25,
      BallSpeed.normal => 1.0,
      BallSpeed.fast => 0.68,
      BallSpeed.urgent => 0.42,
    };
    return Duration(milliseconds: math.max(95, (baseMs * multiplier).round()));
  }

  static double _pitchForSpeed(double baseHz, BallSpeed speed) {
    final multiplier = switch (speed) {
      BallSpeed.slow => 0.92,
      BallSpeed.normal => 1.0,
      BallSpeed.fast => 1.14,
      BallSpeed.urgent => 1.28,
    };
    return baseHz * multiplier;
  }

  Uint8List _tone({
    required String key,
    required double startHz,
    required double endHz,
    required int durationMs,
    required bool square,
  }) {
    return _toneCache.putIfAbsent(
      key,
      () => _buildWavTone(
        startHz: startHz,
        endHz: endHz,
        durationMs: durationMs,
        square: square,
      ),
    );
  }

  void _play(AudioPlayer player, Uint8List bytes, {required double volume}) {
    unawaited(
      player
          .stop()
          .then(
            (_) => player.play(
              BytesSource(bytes),
              mode: PlayerMode.lowLatency,
              volume: volume,
            ),
          )
          .catchError((Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('Game audio failed: $error');
        }
      }),
    );
  }

  static Uint8List _buildWavTone({
    required double startHz,
    required double endHz,
    required int durationMs,
    required bool square,
  }) {
    final sampleCount = (_sampleRate * durationMs / 1000).round();
    final dataBytes = sampleCount * 2;
    final buffer = ByteData(44 + dataBytes);

    void writeAscii(int offset, String text) {
      for (var i = 0; i < text.length; i += 1) {
        buffer.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataBytes, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, _sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    buffer.setUint32(40, dataBytes, Endian.little);

    var phase = 0.0;
    for (var i = 0; i < sampleCount; i += 1) {
      final t = i / math.max(1, sampleCount - 1);
      final hz = startHz + (endHz - startHz) * t;
      phase += 2 * math.pi * hz / _sampleRate;

      final attack = math.min(1.0, i / (_sampleRate * 0.006));
      final release = math.min(1.0, (sampleCount - i) / (_sampleRate * 0.035));
      final envelope = attack * release;
      final raw =
          square ? (math.sin(phase) >= 0 ? 1.0 : -1.0) : math.sin(phase);
      final sample = (raw * envelope * 0.72 * 32767).round();
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
