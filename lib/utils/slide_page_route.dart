import 'package:flutter/material.dart';

enum SlideDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  final SlideDirection direction;

  SlidePageRoute({required this.builder, this.direction = SlideDirection.leftToRight, super.settings})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              builder(context),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: _getBeginOffset(direction),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
          },
        );

  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.leftToRight:
        return const Offset(-1.0, 0.0);
      case SlideDirection.rightToLeft:
        return const Offset(1.0, 0.0);
      case SlideDirection.topToBottom:
        return const Offset(0.0, -1.0);
      case SlideDirection.bottomToTop:
        return const Offset(0.0, 1.0);
    }
  }
}