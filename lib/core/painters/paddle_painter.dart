import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Mario-styled ping-pong paddle (red blade, brown handle, bold black outline).
///
/// Sized to fit the [CustomPaint] container; honors the widget's `size`.
class PaddlePainter extends CustomPainter {
  const PaddlePainter({
    this.bladeColor = MarioColors.marioRed,
    this.handleColor = MarioColors.brick,
    this.outlineColor = MarioColors.bowserBlack,
    this.outlineWidth = 3,
  });

  final Color bladeColor;
  final Color handleColor;
  final Color outlineColor;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()..style = PaintingStyle.fill;

    // Handle (lower third) drawn first so blade overlaps cleanly.
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, h * 0.55, w * 0.16, h * 0.42),
      const Radius.circular(4),
    );
    fill.color = handleColor;
    canvas.drawRRect(handleRect, fill);
    canvas.drawRRect(handleRect, outline);

    // Blade (circular head).
    final bladeCenter = Offset(w * 0.5, h * 0.38);
    final bladeRadius = w * 0.36;
    fill.color = bladeColor;
    canvas.drawCircle(bladeCenter, bladeRadius, fill);
    canvas.drawCircle(bladeCenter, bladeRadius, outline);

    // White star highlight (Mario-style shine).
    final highlightPath = Path();
    final hx = w * 0.36;
    final hy = h * 0.28;
    final r = bladeRadius * 0.25;
    highlightPath.addOval(Rect.fromCircle(center: Offset(hx, hy), radius: r));
    canvas.drawPath(
      highlightPath,
      Paint()..color = MarioColors.cloudWhite.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant PaddlePainter old) =>
      old.bladeColor != bladeColor ||
      old.handleColor != handleColor ||
      old.outlineColor != outlineColor ||
      old.outlineWidth != outlineWidth;
}

/// Convenience widget — square paddle icon with safe defaults.
class PaddleIcon extends StatelessWidget {
  const PaddleIcon({
    super.key,
    this.size = 64,
    this.bladeColor = MarioColors.marioRed,
    this.handleColor = MarioColors.brick,
  });

  final double size;
  final Color bladeColor;
  final Color handleColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PaddlePainter(
          bladeColor: bladeColor,
          handleColor: handleColor,
        ),
      ),
    );
  }
}
