import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/providers/dashboard_provider.dart';

class OrbitalPainter extends CustomPainter {
  final Animation<double> repaint;
  final double balance;
  final List<SpendingCategory> categories;
  final double goalProgress;
  final int? activeCategoryIndex;
  final Function(int) onCategoryTap;

  OrbitalPainter({
    required this.repaint,
    required this.balance,
    required this.categories,
    required this.goalProgress,
    this.activeCategoryIndex,
    required this.onCategoryTap,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.7, backgroundPaint);
    canvas.drawCircle(center, radius, backgroundPaint);

    double startAngle = -pi / 2;
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = 2 * pi * category.percentage;
      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = activeCategoryIndex == i ? 24 : 16;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    if (goalProgress > 0) {
      final goalPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * goalProgress,
        false,
        goalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) {
    const center = Offset(100.0, 100.0);
    const radius = 100.0;
    final distance = (position - center).distance;

    if (distance > radius * 0.6 && distance < radius * 0.8) {
      double angle = (position - center).direction;
      if (angle < -pi / 2) {
        angle += 2 * pi;
      }

      double startAngle = -pi / 2;
      for (int i = 0; i < categories.length; i++) {
        final sweepAngle = 2 * pi * categories[i].percentage;
        if (angle >= startAngle && angle <= startAngle + sweepAngle) {
          onCategoryTap(i);
          return true;
        }
        startAngle += sweepAngle;
      }
    } else if (distance < radius * 0.6) {
      onCategoryTap(-1);
    }

    return super.hitTest(position);
  }
}