// lib/screens/settings/language_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wislet/providers/locale_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocaleProvider>();
    final current = lp.locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Мова')),
      body: ListView(
        children: lp.supportedLocales
            .map(
              (l) => RadioListTile<String>(
                value: l.languageCode,
                groupValue: current,
                title: Text(l.languageCode == 'uk' ? 'Українська' : 'English'),
                onChanged: (_) => lp.setLocale(l),
              ),
            )
            .toList(),
      ),
    );
  }
}
