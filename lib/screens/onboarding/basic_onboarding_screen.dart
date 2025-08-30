import 'package:flutter/material.dart';

class BasicOnboardingScreen extends StatelessWidget {
  const BasicOnboardingScreen({
    required this.onFinished,
    super.key,
  });

  final Future<void> Function() onFinished;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await onFinished();
          },
          child: const Text('Продовжити'),
        ),
      ),
    );
  }
}
