import 'package:flutter/material.dart';

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final Duration transitionDurationMs;
  final Alignment alignment;
  final Curve curve;

  ScalePageRoute({
    required this.builder,
    this.transitionDurationMs = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.curve = Curves.easeOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
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
}