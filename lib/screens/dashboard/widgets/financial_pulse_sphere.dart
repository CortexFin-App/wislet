import 'package:flutter/material.dart';

class FinancialPulseSphere extends StatefulWidget {
  final Color color;
  final double pulseRate;

  const FinancialPulseSphere({
    super.key,
    required this.color,
    required this.pulseRate,
  });

  @override
  State<FinancialPulseSphere> createState() => _FinancialPulseSphereState();
}

class _FinancialPulseSphereState extends State<FinancialPulseSphere> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.pulseRate).round()),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(FinancialPulseSphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseRate != widget.pulseRate) {
      _animationController.duration = Duration(milliseconds: (2000 / widget.pulseRate).round());
      if (_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = 1.0 + (_animationController.value * 0.02);
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            painter: _SpherePainter(
              color: widget.color,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SpherePainter extends CustomPainter {
  final Color color;

  _SpherePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha(128),
          color,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(51),
          Colors.white.withAlpha(0),
        ],
        center: const Alignment(-0.3, -0.3),
        radius: 0.5,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      
    final outerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withAlpha(77),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.1));

    canvas.drawCircle(center, radius * 1.1, outerGlowPaint);
    canvas.drawCircle(center, radius, basePaint);
    canvas.drawCircle(center, radius, innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}