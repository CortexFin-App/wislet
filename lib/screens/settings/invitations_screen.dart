import 'package:flutter/material.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запрошення')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Наразі запрошень немає'),
        ),
      ),
    );
  }
}
