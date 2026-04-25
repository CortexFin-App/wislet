import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/screens/onboarding/simple_onboarding.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({required this.child, super.key});
  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

enum _Stage { loading, onboarding, done }

class _OnboardingGateState extends State<OnboardingGate> {
  _Stage _stage = _Stage.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final done = p.getBool('simple_onboarding_done') ?? false;
    setState(() => _stage = done ? _Stage.done : _Stage.onboarding);
  }

  Future<void> _onDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('simple_onboarding_done', true);
    await p.setBool('interactive_onboarding_done', true);
    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.loading:
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      case _Stage.onboarding:
        return SimpleOnboarding(onFinished: _onDone);
      case _Stage.done:
        return widget.child;
    }
  }
}
