import 'package:flutter/material.dart';

import '../../../core/accessibility/a11y_controller.dart';
import '../../../theme/mario_theme.dart';
import '../models/game_state_models.dart';

/// Hard-cut blinking bar overlay anchored to a screen edge.
///
/// "Sharp arcade" feel — value alternates between 0 and 1 with no smoothing.
/// Period scales with [speed]; toggles instantly off when [edge] doesn't
/// match this strip OR the user enabled reduced-motion.
class EdgeBlinkIndicator extends StatefulWidget {
  const EdgeBlinkIndicator({
    super.key,
    required this.position,
    required this.activeEdge,
    required this.speed,
    required this.a11y,
    this.color,
  });

  /// Which edge this widget draws on.
  final BallEdge position;

  /// The currently-active ball edge from the controller.
  final BallEdge activeEdge;

  final BallSpeed speed;
  final A11yController a11y;
  final Color? color;

  @override
  State<EdgeBlinkIndicator> createState() => _EdgeBlinkIndicatorState();
}

class _EdgeBlinkIndicatorState extends State<EdgeBlinkIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _periodFor(widget.speed))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant EdgeBlinkIndicator old) {
    super.didUpdateWidget(old);
    if (old.speed != widget.speed) {
      _c.duration = _periodFor(widget.speed);
      _c.repeat();
    }
  }

  static Duration _periodFor(BallSpeed s) {
    return switch (s) {
      BallSpeed.slow => const Duration(milliseconds: 520),
      BallSpeed.normal => const Duration(milliseconds: 320),
      BallSpeed.fast => const Duration(milliseconds: 200),
      BallSpeed.urgent => const Duration(milliseconds: 120),
    };
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.activeEdge == widget.position;
    final color = widget.color ?? MarioColors.coin;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Sharp-arcade: hard step at 0.5. Always-on under reduced-motion.
        final on = !isActive
            ? false
            : widget.a11y.reducedMotion
                ? true
                : _c.value < 0.5;

        return IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 30),
            opacity: on ? 1.0 : 0.0,
            child: _EdgeBar(position: widget.position, color: color),
          ),
        );
      },
    );
  }
}

/// Renders a solid bar of the right shape for the given edge.
class _EdgeBar extends StatelessWidget {
  const _EdgeBar({required this.position, required this.color});
  final BallEdge position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const thickness = 18.0;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: MarioColors.bowserBlack, width: 2),
          ),
        );

    return switch (position) {
      BallEdge.top => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: bar(double.infinity, thickness),
        ),
      BallEdge.bottom => Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: bar(double.infinity, thickness),
        ),
      BallEdge.left => Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: bar(thickness, double.infinity),
        ),
      BallEdge.right => Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: bar(thickness, double.infinity),
        ),
      BallEdge.center => const SizedBox.shrink(),
    };
  }
}
