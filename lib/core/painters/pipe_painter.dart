import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Mario green-pipe motif used as a decorative frame around hero content.
///
/// Paints two stacked sections: the wide "lip" on top and the slimmer body
/// below. Suitable as a section header or empty-state mascot.
class PipePainter extends CustomPainter {
  const PipePainter({
    this.pipeColor = MarioColors.pipe,
    this.darkShade = const Color(0xFF036B33),
    this.outlineColor = MarioColors.bowserBlack,
  });

  final Color pipeColor;
  final Color darkShade;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Pipe body (lower 65%).
    final body = Rect.fromLTWH(w * 0.12, h * 0.35, w * 0.76, h * 0.65);
    fill.color = pipeColor;
    canvas.drawRect(body, fill);

    // Body inner shadow stripe.
    fill.color = darkShade;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.62, h * 0.35, w * 0.18, h * 0.65),
      fill,
    );

    canvas.drawRect(body, outline);

    // Lip.
    final lip = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * 0.0, w, h * 0.38),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    fill.color = pipeColor;
    canvas.drawRRect(lip, fill);
    // Lip inner shadow.
    fill.color = darkShade;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.70, h * 0.04, w * 0.20, h * 0.30),
      fill,
    );
    canvas.drawRRect(lip, outline);
  }

  @override
  bool shouldRepaint(covariant PipePainter old) =>
      old.pipeColor != pipeColor ||
      old.darkShade != darkShade ||
      old.outlineColor != outlineColor;
}

class PipeMascot extends StatelessWidget {
  const PipeMascot({super.key, this.width = 96, this.height = 96});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(painter: PipePainter()),
    );
  }
}
