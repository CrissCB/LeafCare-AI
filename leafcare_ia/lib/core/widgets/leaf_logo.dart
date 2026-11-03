import 'package:flutter/material.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';

/// Logo de hoja de LeafCare AI dibujado con [CustomPainter] (viewBox 0 0 40 40).
class LeafLogo extends StatelessWidget {
  const LeafLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _LeafPainter());
  }
}

class _LeafPainter extends CustomPainter {
  static const double _viewBox = 40;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox);

    final leaf = Path()
      ..moveTo(20, 5)
      ..cubicTo(20, 5, 9, 12, 9, 23)
      ..cubicTo(9, 29.08, 13.92, 34, 20, 34)
      ..cubicTo(26.08, 34, 31, 29.08, 31, 23)
      ..cubicTo(31, 12, 20, 5, 20, 5)
      ..close();
    canvas.drawPath(leaf, Paint()..color = AppColors.neon);

    final stem = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(20, 15), const Offset(20, 28), stem);

    final veins = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(15, 22)
        ..cubicTo(17, 18, 18, 17, 20, 15),
      veins,
    );
    canvas.drawPath(
      Path()
        ..moveTo(25, 22)
        ..cubicTo(23, 18, 22, 17, 20, 15),
      veins,
    );
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) => false;
}
