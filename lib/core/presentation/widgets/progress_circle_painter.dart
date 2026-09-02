import 'package:flutter/material.dart';

class ProgressCirclePainter extends CustomPainter {
  final BuildContext context;
  final double progressPercent;
  final Color progressColor;

  const ProgressCirclePainter({
    required this.context,
    required this.progressPercent,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Theme.of(context).colorScheme.outline
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    Paint progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, backgroundPaint);

    double angle = 2 * 3.1415926535 * progressPercent;
    canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2),
        -3.1415926535 / 2, // Começar no topo
        angle,
        false,
        progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}