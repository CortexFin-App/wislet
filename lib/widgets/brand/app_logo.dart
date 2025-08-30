// lib/widgets/brand/app_logo.dart
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (!showWordmark) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
        const SizedBox(width: 10),
        Text(
          'CortexFin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
