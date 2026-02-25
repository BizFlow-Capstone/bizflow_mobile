import 'package:flutter/material.dart';

/// Inline Google "G" logo widget — no image asset required.
/// Uses the official Google brand colors.
class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Draw circle segments (Google colours: blue, red, yellow, green)
    final segments = [
      // [startAngle, sweepAngle, color]
      [-0.53, 1.05, const Color(0xFF4285F4)], // blue (top-right)
      [0.52, 1.05, const Color(0xFFEA4335)], // red (bottom-right)
      [1.57, 1.05, const Color(0xFFFBBC05)], // yellow (bottom-left)
      [2.62, 1.05, const Color(0xFF34A853)], // green (top-left → completes)
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.3;
    final innerR = r * 0.62;

    for (final seg in segments) {
      paint.color = seg[2] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
        seg[0] as double,
        seg[1] as double,
        false,
        paint,
      );
    }

    // White cutout rect & horizontal bar (the "G" opening + bar)
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // right opening — white wedge to create the "open" G shape
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.15, r * 0.9, r * 0.3),
      cutPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
