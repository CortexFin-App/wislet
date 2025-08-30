// widgets/scaffold/patterned_scaffold.dart
import 'package:flutter/material.dart';

class PatternedScaffold extends StatelessWidget {
  const PatternedScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
            ],
          ),
          image: const DecorationImage(
            image: AssetImage('assets/patterns/background_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.075,
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}
