import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Ping-pong ball with a bold Mario outline + cross-hatch stitch line.
class BallPainter extends CustomPainter {
  const BallPainter({
    this.color = MarioColors.cloudWhite,
    this.outlineColor = MarioColors.bowserBlack,
    this.outlineWidth = 2.5,
  });

  final Color color;
  final Color outlineColor;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - outlineWidth;
    final center = size.center(Offset.zero);

    canvas.drawCircle(center, radius, Paint()..color = color);

    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth;
    canvas.drawCircle(center, radius, outline);

    // Cross stitch line for "ping pong ball" affordance.
    final stitch = Paint()
      ..color = outlineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth * 0.7;
    canvas.drawLine(
      Offset(center.dx - radius * 0.85, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      stitch,
    );
  }

  @override
  bool shouldRepaint(covariant BallPainter old) =>
      old.color != color ||
      old.outlineColor != outlineColor ||
      old.outlineWidth != outlineWidth;
}

class BallIcon extends StatelessWidget {
  const BallIcon(
      {super.key, this.size = 24, this.color = MarioColors.cloudWhite});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: BallPainter(color: color)),
    );
  }
}
