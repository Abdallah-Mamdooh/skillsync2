import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Subtle geometric pattern of rounded rectangular outlines over the teal background.
class PatternBackground extends StatelessWidget {
  const PatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(),
      size: Size.infinite,
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 48.0;
    const strokeWidth = 1.2;
    const cornerRadius = 8.0;

    final orangePaint = Paint()
      ..color = AppColors.patternOrange.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final lightPaint = Paint()
      ..color = AppColors.patternLight.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final random = math.Random(42);
    for (double y = -50; y < size.height + 80; y += spacing) {
      for (double x = -50; x < size.width + 80; x += spacing) {
        final offset = Offset(
          x + (random.nextDouble() * 20 - 10),
          y + (random.nextDouble() * 20 - 10),
        );
        final rect = Rect.fromCenter(
          center: offset,
          width: 36 + random.nextDouble() * 24,
          height: 28 + random.nextDouble() * 20,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
        canvas.drawRRect(rrect, random.nextBool() ? orangePaint : lightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
