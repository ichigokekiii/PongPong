import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../core/accessibility/a11y_controller.dart';
import '../../core/painters/ball_painter.dart';
import '../../theme/mario_theme.dart';
import '../multiplayer/multiplayer_session_controller.dart';
import '../results/result_screen.dart';
import '../scan/scanned_area_model.dart';
import 'game_controller.dart';
import 'models/game_state_models.dart';
import 'widgets/center_pulse.dart';
import 'widgets/demo_controls.dart';
import 'widgets/edge_blink_indicator.dart';
import 'widgets/flash_overlay.dart';
import 'widgets/pause_overlay.dart';
import 'widgets/score_hud.dart';
import 'widgets/screen_blink_overlay.dart';

/// Main gameplay surface.
///
/// Layout follows the user's "top-anchored HUD" preference: the play zone
/// occupies the top ~60% of the screen (color, indicators, blinks, pulse,
/// HUD chips) because the bottom is obscured by the user's gripping hand
/// during play. The bottom area is a dim "grip pad" that hosts only the
/// slide-up demo controls trigger.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.a11y,
    this.playArea,
    this.sessionController,
  });
  final A11yController a11y;
  final ScannedAreaModel? playArea;
  final MultiplayerSessionController? sessionController;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(playArea: widget.playArea);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDemoControls() {
    HapticFeedback
        .selectionClick(); // TODO(member-4): route via haptic service.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DemoControls(
        controller: _controller,
        a11y: widget.a11y,
        onEndRally: _endRally,
      ),
    );
  }

  void _endRally() {
    // Auto-dismiss the demo sheet then route to result screen.
    Navigator.maybePop(context);
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Routes.result,
        arguments: ResultArgs(
          score: _controller.score.value,
          longestRally: _controller.longestRally.value,
          hits: _controller.hits.value,
          smashes: _controller.smashes.value,
          accuracy: _controller.accuracy,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarioColors.bowserBlack,
      body: AnimatedBuilder(
        animation: widget.a11y,
        builder: (context, _) {
          return Stack(
            children: [
              // === TOP-ANCHORED PLAY ZONE (60% of height) ===================
              Positioned.fill(
                child: _PlayZone(
                  controller: _controller,
                  a11y: widget.a11y,
                  playArea: widget.playArea,
                ),
              ),

              // === BOTTOM "GRIP PAD" ========================================
              _GripPad(a11y: widget.a11y),

              // === TOP HUD (over the play zone) =============================
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MarioSpacing.sm,
                    MarioSpacing.xs,
                    MarioSpacing.sm,
                    0,
                  ),
                  child: ScoreHud(
                    controller: _controller,
                    a11y: widget.a11y,
                    onPause: _controller.pause,
                    onOpenDemo: _openDemoControls,
                  ),
                ),
              ),

              if (widget.sessionController != null)
                Positioned(
                  left: MarioSpacing.sm,
                  right: MarioSpacing.sm,
                  bottom: 96,
                  child: AnimatedBuilder(
                    animation: widget.sessionController!,
                    builder: (context, _) {
                      final state = widget.sessionController!.state;
                      return IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MarioSpacing.sm,
                            vertical: MarioSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                MarioColors.cloudWhite.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(MarioRadius.md),
                            border: Border.all(
                              color: MarioColors.bowserBlack,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            'MULTIPLAYER · ${state.role?.name.toUpperCase() ?? 'PLAYER'} · '
                            '${state.isConnected ? 'CONNECTED' : state.disconnectReason ?? 'DISCONNECTED'}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // === FLASH OVERLAY (hit / smash / miss) =======================
              ValueListenableBuilder<SwingEvent>(
                valueListenable: _controller.lastEvent,
                builder: (context, e, _) =>
                    FlashOverlay(event: e, a11y: widget.a11y),
              ),

              // === PAUSE OVERLAY ============================================
              ValueListenableBuilder<GameStatus>(
                valueListenable: _controller.status,
                builder: (context, s, _) {
                  if (s != GameStatus.paused) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: PauseOverlay(
                      a11y: widget.a11y,
                      onResume: _controller.resume,
                      onQuit: _controller.resume,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The colored, blink-animated play zone occupying the top 60% of the screen.
///
/// Background tracks [BallState] color. Inside lives the center pulse, the
/// four edge blink indicators, and the big "STATE" label.
class _PlayZone extends StatelessWidget {
  const _PlayZone({
    required this.controller,
    required this.a11y,
    required this.playArea,
  });
  final GameController controller;
  final A11yController a11y;
  final ScannedAreaModel? playArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final zoneHeight =
            (constraints.maxHeight - mq.padding.top) * 0.60 + mq.padding.top;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: zoneHeight,
            width: double.infinity,
            child: ValueListenableBuilder<BallState>(
              valueListenable: controller.ballState,
              builder: (context, ballState, _) {
                final stateColor = _colorForState(ballState);
                return AnimatedContainer(
                  duration:
                      a11y.reducedMotion ? Duration.zero : MarioMotion.stateCut,
                  curve: Curves.linear,
                  color: stateColor,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Decorative grid backdrop (subtle Mario-block vibe).
                        const _BlockGrid(),

                        if (playArea != null)
                          SafeArea(
                            bottom: false,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 68),
                                child: _PlayAreaHud(area: playArea!),
                              ),
                            ),
                          ),

                        // Full-zone blink intensity follows ball speed.
                        ValueListenableBuilder<BallSpeed>(
                          valueListenable: controller.speed,
                          builder: (context, speed, __) {
                            return ScreenBlinkOverlay(
                              state: ballState,
                              speed: speed,
                              a11y: a11y,
                            );
                          },
                        ),

                        // Edge blinks (each builds its own controller).
                        ValueListenableBuilder<BallEdge>(
                          valueListenable: controller.ballEdge,
                          builder: (context, edge, __) {
                            return ValueListenableBuilder<BallSpeed>(
                              valueListenable: controller.speed,
                              builder: (context, speed, ___) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    for (final p in [
                                      BallEdge.top,
                                      BallEdge.bottom,
                                      BallEdge.left,
                                      BallEdge.right,
                                    ])
                                      EdgeBlinkIndicator(
                                        position: p,
                                        activeEdge: edge,
                                        speed: speed,
                                        a11y: a11y,
                                        color: _edgeColor(ballState),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),

                        // Center pulse + state label.
                        Align(
                          alignment: const Alignment(0, -0.05),
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: mq.padding.top + 56,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BallReadinessIndicators(state: ballState),
                                const SizedBox(height: MarioSpacing.sm),
                                ValueListenableBuilder<BallSpeed>(
                                  valueListenable: controller.speed,
                                  builder: (context, speed, __) {
                                    return CenterPulse(
                                      state: ballState,
                                      speed: speed,
                                      a11y: a11y,
                                    );
                                  },
                                ),
                                const SizedBox(height: MarioSpacing.sm),
                                _StateLabel(state: ballState),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Color _colorForState(BallState s) => switch (s) {
        BallState.far => MarioColors.stateFar,
        BallState.near => MarioColors.stateNear,
        BallState.ready => MarioColors.stateReady,
      };

  /// Edge blink color contrasts against the background state color so it
  /// remains visible on every backdrop.
  static Color _edgeColor(BallState s) => switch (s) {
        BallState.far => MarioColors.cloudWhite,
        BallState.near => MarioColors.bowserBlack,
        BallState.ready => MarioColors.cloudWhite,
      };
}

class _PlayAreaHud extends StatelessWidget {
  const _PlayAreaHud({required this.area});

  final ScannedAreaModel area;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MarioSpacing.sm,
        vertical: MarioSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: MarioColors.bowserBlack.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(MarioRadius.pill),
        border: Border.all(color: MarioColors.cloudWhite, width: 2),
      ),
      child: Text(
        'AREA ${area.widthMeters.toStringAsFixed(1)}m x '
        '${area.lengthMeters.toStringAsFixed(1)}m',
        style: t.labelMedium?.copyWith(
          color: MarioColors.cloudWhite,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _BallReadinessIndicators extends StatelessWidget {
  const _BallReadinessIndicators({required this.state});

  final BallState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel(state),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MarioSpacing.sm,
          vertical: MarioSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: MarioColors.bowserBlack.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(MarioRadius.pill),
          border: Border.all(color: MarioColors.cloudWhite, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ReadinessBall(
              label: 'FAR',
              color: MarioColors.marioRed,
              active: state == BallState.far,
            ),
            const SizedBox(width: MarioSpacing.sm),
            _ReadinessBall(
              label: 'NEAR',
              color: MarioColors.coin,
              active: state == BallState.near,
            ),
            const SizedBox(width: MarioSpacing.sm),
            _ReadinessBall(
              label: 'HIT',
              color: MarioColors.pipe,
              active: state == BallState.ready,
            ),
          ],
        ),
      ),
    );
  }

  static String _semanticLabel(BallState state) => switch (state) {
        BallState.far => 'Ball is far. Red indicator active.',
        BallState.near => 'Ball is near. Yellow indicator active.',
        BallState.ready => 'Ball is ready to hit. Green indicator active.',
      };
}

class _ReadinessBall extends StatelessWidget {
  const _ReadinessBall({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = active ? 42.0 : 28.0;
    return AnimatedScale(
      duration: MarioMotion.stateCut,
      scale: active ? 1.0 : 0.88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: MarioMotion.stateCut,
            padding: EdgeInsets.all(active ? 4 : 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    active ? MarioColors.cloudWhite : MarioColors.bowserBlack,
                width: active ? 3 : 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.65),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: BallIcon(size: size, color: color),
          ),
          const SizedBox(height: MarioSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? color : MarioColors.cloudWhite,
                  fontSize: active ? 12 : 10,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _StateLabel extends StatelessWidget {
  const _StateLabel({required this.state});
  final BallState state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      BallState.far => 'STAND BY',
      BallState.near => 'GET READY',
      BallState.ready => 'SWING NOW!',
    };
    final fg = switch (state) {
      BallState.far => MarioColors.cloudWhite,
      BallState.near => MarioColors.bowserBlack,
      BallState.ready => MarioColors.cloudWhite,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MarioSpacing.md,
        vertical: MarioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: MarioColors.bowserBlack.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(MarioRadius.pill),
        border: Border.all(color: fg, width: 2),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: fg,
              fontSize: 20,
              letterSpacing: 2,
            ),
      ),
    );
  }
}

/// Subtle Mario-block grid drawn inside the play zone.
class _BlockGrid extends StatelessWidget {
  const _BlockGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlockGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BlockGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MarioColors.bowserBlack.withValues(alpha: 0.08)
      ..strokeWidth = 1.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dim bottom strip representing the area covered by the user's grip hand.
///
/// Holds nothing visually heavy — just a faint pattern + the "Open demo
/// controls" affordance for hackathon judges.
class _GripPad extends StatelessWidget {
  const _GripPad({required this.a11y});
  final A11yController a11y;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.30,
          color: MarioColors.bowserBlack,
          padding: const EdgeInsets.symmetric(
            horizontal: MarioSpacing.md,
            vertical: MarioSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: a11y.mirrorForLeftHand
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Subtle dashed line indicating "hand grip starts here" — the
              // bottom edge blink overlays this seam during play.
              const _DashedDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MarioSpacing.xs),
                child: Text(
                  'HOLD PHONE LIKE A PADDLE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: MarioColors.cloudWhite.withValues(alpha: 0.5),
                        letterSpacing: 1.4,
                      ),
                ),
              ),
              Row(
                mainAxisAlignment: a11y.mirrorForLeftHand
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.swipe_up_rounded,
                    color: MarioColors.cloudWhite.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: MarioSpacing.xxs),
                  Text(
                    'Tap demo button on top HUD to mock states',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MarioColors.cloudWhite.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 8,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MarioColors.cloudWhite.withValues(alpha: 0.35)
      ..strokeWidth = 3;
    const dash = 10.0;
    const gap = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset((x + dash).clamp(0, size.width), size.height / 2), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
