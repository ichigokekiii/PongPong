import 'package:flutter/material.dart';

import '../../theme/mario_theme.dart';

/// Classic Mario coin — yellow disc with a darker inner ring and a "$" stamp.
class CoinPainter extends CustomPainter {
  const CoinPainter({this.color = MarioColors.coin});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);

    canvas.drawCircle(center, r - 2, Paint()..color = color);
    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = MarioColors.bowserBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      r * 0.68,
      Paint()
        ..color = const Color(0xFFE0A800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: const Color(0xFFB87C00),
          fontWeight: FontWeight.w900,
          fontSize: r * 0.95,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CoinPainter old) => old.color != color;
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: CoinPainter()),
    );
  }
}
