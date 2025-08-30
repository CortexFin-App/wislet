import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage_wallet_reborn/screens/onboarding/interactive_onboarding_screen.dart';
import 'package:sage_wallet_reborn/screens/onboarding/simple_onboarding.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

enum _Stage { loading, simple, interactive, done }

class _OnboardingGateState extends State<OnboardingGate> {
  _Stage _stage = _Stage.loading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final simpleDone = p.getBool('simple_onboarding_done') ?? false;
    final interactiveDone = p.getBool('interactive_onboarding_done') ?? false;

    setState(() {
      if (!simpleDone) {
        _stage = _Stage.simple;
      } else if (!interactiveDone) {
        _stage = _Stage.interactive;
      } else {
        _stage = _Stage.done;
      }
    });
  }

  Future<void> _onSimpleDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('simple_onboarding_done', true);
    setState(() => _stage = _Stage.interactive);
  }

  Future<void> _onInteractiveDone() async {
    final p = await SharedPreferences.getInstance();
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
      case _Stage.simple:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: SimpleOnboarding(onFinished: _onSimpleDone),
        );
      case _Stage.interactive:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: InteractiveOnboardingScreen(
            onFinished: _onInteractiveDone,
          ),
        );
      case _Stage.done:
        return widget.child;
    }
  }
}
