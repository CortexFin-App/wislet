import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../providers/wallet_provider.dart';
import '../../services/auth_service.dart';
import 'login_register_screen.dart';

class InvitationHandlerScreen extends StatefulWidget {
  final String invitationToken;
  const InvitationHandlerScreen({super.key, required this.invitationToken});

  @override
  State<InvitationHandlerScreen> createState() => _InvitationHandlerScreenState();
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
        messenger.showSnackBar(const SnackBar(content: Text('Запрошення прийнято!')));
        navigator.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    } else {
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => LoginRegisterScreen(
          invitationToken: widget.invitationToken,
        ),
      ));
    }

    if(mounted) {
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
          padding: const EdgeInsets.all(24.0),
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
                      onPressed: () => Navigator.of(context).pop(),
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