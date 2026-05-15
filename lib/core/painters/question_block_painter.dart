import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Mario "?" question block — yellow square with rivets and a centered "?".
///
/// Used for tappable secondary actions (How to Play, Settings, Calibration).
class QuestionBlockPainter extends CustomPainter {
  const QuestionBlockPainter({
    this.blockColor = MarioColors.coin,
    this.markColor = MarioColors.bowserBlack,
  });

  final Color blockColor;
  final Color markColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );

    canvas.drawRRect(r, Paint()..color = blockColor);
    canvas.drawRRect(
      r,
      Paint()
        ..color = markColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 4 corner rivets.
    final rivet = Paint()..color = markColor;
    const pad = 8.0;
    canvas.drawCircle(const Offset(pad, pad), 2.5, rivet);
    canvas.drawCircle(Offset(size.width - pad, pad), 2.5, rivet);
    canvas.drawCircle(Offset(pad, size.height - pad), 2.5, rivet);
    canvas.drawCircle(
      Offset(size.width - pad, size.height - pad),
      2.5,
      rivet,
    );

    // Centered "?" stamp.
    final tp = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: markColor,
          fontWeight: FontWeight.w900,
          fontSize: size.shortestSide * 0.62,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        size.width / 2 - tp.width / 2,
        size.height / 2 - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant QuestionBlockPainter old) =>
      old.blockColor != blockColor || old.markColor != markColor;
}

class QuestionBlockIcon extends StatelessWidget {
  const QuestionBlockIcon({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: QuestionBlockPainter()),
    );
  }
}
