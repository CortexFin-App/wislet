import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get _nav => navigatorKey.currentState;

  Future<T?> push<T>(Route<T> route) => _nav!.push(route);
  Future<T?> pushNamed<T extends Object?>(String route, {Object? arguments}) =>
      _nav!.pushNamed<T>(route, arguments: arguments);

  void pop<T extends Object?>([T? result]) => _nav?.pop(result);
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String route, {
    TO? result,
    Object? arguments,
  }) =>
      _nav!.pushReplacementNamed<T, TO>(
        route,
        result: result,
        arguments: arguments,
      );
}
