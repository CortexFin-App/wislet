import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/invitation_repository.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/auth/login_register_screen.dart';
import 'package:wislet/services/auth_service.dart';

class InvitationHandlerScreen extends StatefulWidget {
  const InvitationHandlerScreen({required this.invitationToken, super.key});
  final String invitationToken;

  @override
  State<InvitationHandlerScreen> createState() =>
      _InvitationHandlerScreenState();
}

class _InvitationHandlerScreenState extends State<InvitationHandlerScreen> {
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>();
  bool _isLoading = false;

  Future<void> _handleInvitation() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final walletProvider = context.read<WalletProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (authService.currentUser != null) {
      try {
        await _invitationRepo.acceptInvitation(widget.invitationToken);
        await walletProvider.loadWallets();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Запрошення прийнято!'),
          ),
        );
        navigator.pop();
      } on Exception catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    } else {
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LoginRegisterScreen(
            invitationToken: widget.invitationToken,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запрошення до гаманця'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Вас запросили до спільного гаманця',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Прийміть запрошення, щоб отримати доступ, або відхиліть, якщо ви не очікували на це.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Відхилити'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _handleInvitation,
                      child: const Text('Прийняти'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
