import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/invitation_repository.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/screens/auth/login_register_screen.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';

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
            content: Text('Р—Р°РїСЂРѕС€РµРЅРЅСЏ РїСЂРёР№РЅСЏС‚Рѕ!'),
          ),
        );
        navigator.pop();
      } on Exception catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('РџРѕРјРёР»РєР°: $e')));
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
        title: const Text('Р—Р°РїСЂРѕС€РµРЅРЅСЏ РґРѕ РіР°РјР°РЅС†СЏ'),
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
                'Р’Р°СЃ Р·Р°РїСЂРѕСЃРёР»Рё РґРѕ СЃРїС–Р»СЊРЅРѕРіРѕ РіР°РјР°РЅС†СЏ',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'РџСЂРёР№РјС–С‚СЊ Р·Р°РїСЂРѕС€РµРЅРЅСЏ, С‰РѕР± РѕС‚СЂРёРјР°С‚Рё РґРѕСЃС‚СѓРї, Р°Р±Рѕ РІС–РґС…РёР»С–С‚СЊ, СЏРєС‰Рѕ РІРё РЅРµ РѕС‡С–РєСѓРІР°Р»Рё РЅР° С†Рµ.',
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
                      child: const Text('Р’С–РґС…РёР»РёС‚Рё'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _handleInvitation,
                      child: const Text('РџСЂРёР№РЅСЏС‚Рё'),
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
