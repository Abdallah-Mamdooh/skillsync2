import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Stylized brain + lightbulb logo. Add assets/images/logo.png to use your Figma asset.
class LogoBrainLightbulb extends StatelessWidget {
  const LogoBrainLightbulb({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrainLightbulbPainter(),
      ),
    );
  }
}

class _BrainLightbulbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final whitePaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final orangePaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final orangeFill = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFE85D04)
      ..style = PaintingStyle.fill;

    final r = size.width * 0.2;

    // Decorative wavy rings around the icon (organic star-like shape)
    for (int ring = 0; ring < 2; ring++) {
      final radius = size.width * (0.38 + ring * 0.08);
      final path = Path();
      for (int i = 0; i <= 12; i++) {
        final angle = (i / 12) * 2 * 3.14159;
        final x = center.dx + radius * (0.95 + 0.1 * (i % 2)) * math.cos(angle);
        final y = center.dy + radius * 0.85 * (0.95 + 0.1 * (i % 2)) * math.sin(angle);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, ring == 0 ? whitePaint : orangePaint);
    }

    // Brain (oval outline)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 1.7, height: r * 1.35),
      whitePaint,
    );

    // Lightbulb base (trapezoid)
    final baseTop = center.dy + r * 0.55;
    final basePath = Path()
      ..moveTo(center.dx - r * 0.4, baseTop)
      ..lineTo(center.dx - r * 0.55, baseTop + r * 0.5)
      ..lineTo(center.dx, baseTop + r * 0.58)
      ..lineTo(center.dx + r * 0.55, baseTop + r * 0.5)
      ..lineTo(center.dx + r * 0.4, baseTop)
      ..close();
    canvas.drawPath(basePath, orangeFill);
    canvas.drawPath(basePath, whitePaint);

    // Glow dot at bottom
    canvas.drawCircle(Offset(center.dx, baseTop + r * 0.54), 5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
