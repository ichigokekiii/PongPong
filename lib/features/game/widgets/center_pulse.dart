import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../core/painters/ball_painter.dart';
import '../../../theme/mario_theme.dart';
import '../models/game_state_models.dart';

/// Big rhythmic ball + pulse ring shown in the center of the play zone.
///
/// In `BallState.ready` the ring snaps fully open / closed (sharp arcade) at
/// 80 ms intervals. In `far` / `near` it scales slowly to telegraph distance.
class CenterPulse extends StatefulWidget {
  const CenterPulse({
    super.key,
    required this.state,
    required this.speed,
    required this.a11y,
  });

  final BallState state;
  final BallSpeed speed;
  final A11yController a11y;

  @override
  State<CenterPulse> createState() => _CenterPulseState();
}

class _CenterPulseState extends State<CenterPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: _periodFor(widget.state, widget.speed),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CenterPulse old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state || old.speed != widget.speed) {
      _c.duration = _periodFor(widget.state, widget.speed);
      _c.repeat(reverse: true);
    }
  }

  static Duration _periodFor(BallState st, BallSpeed sp) {
    final base = switch (st) {
      BallState.far => 900,
      BallState.near => 500,
      BallState.ready => 160,
    };
    final mult = switch (sp) {
      BallSpeed.slow => 1.3,
      BallSpeed.normal => 1.0,
      BallSpeed.fast => 0.75,
      BallSpeed.urgent => 0.55,
    };
    return Duration(milliseconds: (base * mult).round());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Sharp arcade in ready state, smooth pulse otherwise. Reduced motion
        // freezes the ring at its midpoint.
        double ringScale;
        if (widget.a11y.reducedMotion) {
          ringScale = 1.0;
        } else if (widget.state == BallState.ready) {
          ringScale = _c.value < 0.5 ? 0.95 : 1.35;
        } else {
          ringScale = 0.95 + _c.value * 0.30;
        }

        final ringColor = switch (widget.state) {
          BallState.far => MarioColors.marioRed,
          BallState.near => MarioColors.coin,
          BallState.ready => MarioColors.pipe,
        };

        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring.
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ringColor,
                      width: 10,
                    ),
                  ),
                ),
              ),
              // Inner ball.
              const BallIcon(size: 92),
            ],
          ),
        );
      },
    );
  }
}
