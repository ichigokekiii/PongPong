import 'package:flutter/material.dart';

import 'ball_model.dart';
import 'game_models.dart';

/// Color palette used across the feedback system.
///   red    -> ball is far
///   yellow -> ball is approaching
///   green  -> hit window is open
///   plus distinct hit / smash / miss colors
class FeedbackPalette {
  static const red = Color(0xFFE63946);
  static const yellow = Color(0xFFF4A261);
  static const green = Color(0xFF2A9D8F);
  static const hit = Color(0xFF3D5A80);
  static const smash = Color(0xFFB5179E);
  static const miss = Color(0xFF7D8597);

  static Color forState(BallState state) {
    switch (state) {
      case BallState.far:
        return red;
      case BallState.near:
        return yellow;
      case BallState.ready:
        return green;
      case BallState.hit:
        return hit;
      case BallState.smash:
        return smash;
      case BallState.missed:
        return miss;
    }
  }

  static String labelForState(BallState state) {
    switch (state) {
      case BallState.far:
        return 'RED · ball is far';
      case BallState.near:
        return 'YELLOW · ball is near';
      case BallState.ready:
        return 'GREEN · swing now';
      case BallState.hit:
        return 'HIT';
      case BallState.smash:
        return 'SMASH';
      case BallState.missed:
        return 'MISS';
    }
  }
}

/// Big visual cue arena that blinks faster as the ball speed increases.
/// Renders:
///  * the color "screen tint" (red / yellow / green)
///  * a center pulse when the ball is in the hit zone
///  * edge indicators showing the ball direction (left/right/top/bottom)
///  * a small text describing the latest event
class BallFeedbackArena extends StatefulWidget {
  const BallFeedbackArena({
    super.key,
    required this.ball,
    required this.lastEvent,
    required this.swingStatusText,
  });

  final Ball ball;
  final String lastEvent;
  final String swingStatusText;

  @override
  State<BallFeedbackArena> createState() => _BallFeedbackArenaState();
}

class _BallFeedbackArenaState extends State<BallFeedbackArena>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.ball.blinkIntervalMs),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BallFeedbackArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newDuration = Duration(milliseconds: widget.ball.blinkIntervalMs);
    if (newDuration != _blinkController.duration) {
      _blinkController.duration = newDuration;
      _blinkController
        ..stop()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ball = widget.ball;
    final color = FeedbackPalette.forState(ball.state);
    final stateLabel = FeedbackPalette.labelForState(ball.state);

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, _) {
        final blink = _blinkController.value; // 0..1
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.85 + 0.15 * blink),
                color.withValues(alpha: 0.35 + 0.25 * blink),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: ball.state == BallState.ready ? 0.6 * blink : 0.0,
                ),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stateLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${ball.speed.toStringAsFixed(2)}x speed',
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
                          color: Colors.black.withValues(
                            alpha: 0.22 + 0.18 * blink,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _EdgeBar(
                        active: ball.state == BallState.far,
                        blink: blink,
                        color: color,
                        horizontal: true,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _EdgeBar(
                        active: ball.state == BallState.near ||
                            ball.state == BallState.ready,
                        blink: blink,
                        color: color,
                        horizontal: true,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _EdgeBar(
                        active: ball.lane == BallLane.left,
                        blink: blink,
                        color: color,
                        horizontal: false,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _EdgeBar(
                        active: ball.lane == BallLane.right,
                        blink: blink,
                        color: color,
                        horizontal: false,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width:
                            ball.state == BallState.ready ? 116 + 24 * blink : 88,
                        height:
                            ball.state == BallState.ready ? 116 + 24 * blink : 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: ball.state == BallState.ready
                                ? 0.7 + 0.3 * blink
                                : 0.28,
                          ),
                          boxShadow: ball.state == BallState.ready
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha: 0.45 * blink,
                                    ),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          ball.state == BallState.ready
                              ? Icons.sports_tennis
                              : Icons.motion_photos_on_outlined,
                          color:
                              ball.state == BallState.ready ? color : Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.lastEvent,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                widget.swingStatusText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EdgeBar extends StatelessWidget {
  const _EdgeBar({
    required this.active,
    required this.blink,
    required this.color,
    required this.horizontal,
  });

  final bool active;
  final double blink;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final activeAlpha = 0.45 + 0.55 * blink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: horizontal ? 170 : 14,
      height: horizontal ? 14 : 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? color.withValues(alpha: activeAlpha)
            : Colors.white.withValues(alpha: 0.12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55 * blink),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Tri-color chip strip explaining the red/yellow/green mapping. Used in the
/// game screen to make the cue system obvious during the demo.
class BallStateLegend extends StatelessWidget {
  const BallStateLegend({super.key, required this.currentState});

  final BallState currentState;

  @override
  Widget build(BuildContext context) {
    final entries = const [
      _LegendEntry(state: BallState.far, label: 'Far'),
      _LegendEntry(state: BallState.near, label: 'Near'),
      _LegendEntry(state: BallState.ready, label: 'Hit'),
    ];
    return Row(
      children: [
        for (final entry in entries) ...[
          Expanded(
            child: _LegendChip(
              entry: entry,
              isActive: currentState == entry.state,
            ),
          ),
          if (entry != entries.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _LegendEntry {
  const _LegendEntry({required this.state, required this.label});
  final BallState state;
  final String label;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.entry, required this.isActive});

  final _LegendEntry entry;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = FeedbackPalette.forState(entry.state);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.9 : 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            entry.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}
