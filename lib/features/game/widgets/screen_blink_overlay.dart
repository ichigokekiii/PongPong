import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../theme/mario_theme.dart';
import '../models/game_state_models.dart';

/// Full play-zone blink layer that intensifies as the incoming ball speeds up.
class ScreenBlinkOverlay extends StatefulWidget {
  const ScreenBlinkOverlay({
    super.key,
    required this.state,
    required this.speed,
    required this.a11y,
  });

  final BallState state;
  final BallSpeed speed;
  final A11yController a11y;

  @override
  State<ScreenBlinkOverlay> createState() => _ScreenBlinkOverlayState();
}

class _ScreenBlinkOverlayState extends State<ScreenBlinkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: _periodFor(widget.state, widget.speed),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant ScreenBlinkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.speed != widget.speed) {
      _c.duration = _periodFor(widget.state, widget.speed);
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.a11y.reducedMotion) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final isOn = _c.value < _dutyCycle(widget.state);
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 24),
            opacity: isOn ? 1 : 0,
            child: ColoredBox(
              color: _blinkColor(widget.state)
                  .withValues(alpha: _opacityFor(widget.state)),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }

  static Duration _periodFor(BallState state, BallSpeed speed) {
    final baseMs = switch (state) {
      BallState.far => 920,
      BallState.near => 520,
      BallState.ready => 220,
    };
    final multiplier = switch (speed) {
      BallSpeed.slow => 1.25,
      BallSpeed.normal => 1.0,
      BallSpeed.fast => 0.68,
      BallSpeed.urgent => 0.42,
    };
    return Duration(
        milliseconds: (baseMs * multiplier).round().clamp(90, 1400));
  }

  static double _dutyCycle(BallState state) => switch (state) {
        BallState.far => 0.22,
        BallState.near => 0.34,
        BallState.ready => 0.52,
      };

  static double _opacityFor(BallState state) => switch (state) {
        BallState.far => 0.16,
        BallState.near => 0.18,
        BallState.ready => 0.26,
      };

  static Color _blinkColor(BallState state) => switch (state) {
        BallState.far => MarioColors.bowserBlack,
        BallState.near => MarioColors.cloudWhite,
        BallState.ready => MarioColors.cloudWhite,
      };
}
