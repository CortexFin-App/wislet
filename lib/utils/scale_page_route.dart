import 'package:flutter/material.dart';

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  ScalePageRoute({
    required this.builder,
    this.transitionDurationMs = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.curve = Curves.easeOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) =>
              builder(context),
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );
            return ScaleTransition(
              scale: curvedAnimation,
              alignment: alignment,
              child: FadeTransition(
                opacity: curvedAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: transitionDurationMs,
        );
  final WidgetBuilder builder;
  final Duration transitionDurationMs;
  final Alignment alignment;
  final Curve curve;
}
