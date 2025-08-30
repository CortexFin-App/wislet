import 'package:flutter/material.dart';

enum SlideDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required this.builder,
    this.direction = SlideDirection.leftToRight,
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

  final WidgetBuilder builder;
  final SlideDirection direction;

  static Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.leftToRight:
        return const Offset(-1, 0);
      case SlideDirection.rightToLeft:
        return const Offset(1, 0);
      case SlideDirection.topToBottom:
        return const Offset(0, -1);
      case SlideDirection.bottomToTop:
        return const Offset(0, 1);
    }
  }
}
