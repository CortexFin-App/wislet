import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/invitation_repository.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';
import 'package:sage_wallet_reborn/utils/app_palette.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({this.invitationToken, super.key});
  final String? invitationToken;

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('РћРЅР»Р°Р№РЅ-Р°РєР°СѓРЅС‚'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.darkAccent,
          tabs: const [
            Tab(text: 'Р’С…С–Рґ'),
            Tab(text: 'Р РµС”СЃС‚СЂР°С†С–СЏ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AuthForm(
            isLogin: true,
            tabController: _tabController,
            invitationToken: widget.invitationToken,
          ),
          _AuthForm(
            isLogin: false,
            tabController: _tabController,
            invitationToken: widget.invitationToken,
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({
    required this.isLogin,
    required this.tabController,
    this.invitationToken,
  });
  final bool isLogin;
  final TabController tabController;
  final String? invitationToken;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showConfirmationMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _processInvitation() async {
    if (widget.invitationToken != null) {
      final messenger = ScaffoldMessenger.of(context);
      final walletProvider = context.read<WalletProvider>();
      try {
        await _invitationRepo.acceptInvitation(widget.invitationToken!);
        await walletProvider.loadWallets();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Р—Р°РїСЂРѕС€РµРЅРЅСЏ РїСЂРёР№РЅСЏС‚Рѕ!'),
          ),
        );
      } on Exception catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'РќРµ РІРґР°Р»РѕСЃСЏ РїСЂРёР№РЅСЏС‚Рё Р·Р°РїСЂРѕС€РµРЅРЅСЏ: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final navigator = Navigator.of(context);
      if (widget.isLogin) {
        await authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        await _processInvitation();
        if (mounted) navigator.popUntil((route) => route.isFirst);
      } else {
        final result = await authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          if (result == RegistrationResult.needsConfirmation) {
            setState(() => _showConfirmationMessage = true);
          } else if (result == RegistrationResult.success) {
            await _processInvitation();
            navigator.popUntil((route) => route.isFirst);
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showConfirmationMessage) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              size: 80,
              color: AppPalette.darkPositive,
            ),
            const SizedBox(height: 24),
            Text(
              'Р РµС”СЃС‚СЂР°С†С–СЏ РјР°Р№Р¶Рµ Р·Р°РІРµСЂС€РµРЅР°!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'РњРё РЅР°РґС–СЃР»Р°Р»Рё Р»РёСЃС‚ РЅР° ${_emailController.text} РґР»СЏ РїС–РґС‚РІРµСЂРґР¶РµРЅРЅСЏ РІР°С€РѕС— РїРѕС€С‚Рё. Р‘СѓРґСЊ Р»Р°СЃРєР°, РїРµСЂРµР№РґС–С‚СЊ Р·Р° РїРѕСЃРёР»Р°РЅРЅСЏРј Сѓ Р»РёСЃС‚С–, С‰РѕР± Р°РєС‚РёРІСѓРІР°С‚Рё Р°РєР°СѓРЅС‚.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => widget.tabController.animateTo(0),
              child:
                  const Text('РџРµСЂРµР№С‚Рё РЅР° РІРєР»Р°РґРєСѓ "Р’С…С–Рґ"'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || !value.contains('@')
                ? 'Р’РІРµРґС–С‚СЊ РєРѕСЂРµРєС‚РЅРёР№ email'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'РџР°СЂРѕР»СЊ',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) => value == null || value.length < 6
                ? 'РџР°СЂРѕР»СЊ РјР°С” Р±СѓС‚Рё РЅРµ РјРµРЅС€Рµ 6 СЃРёРјРІРѕР»С–РІ'
                : null,
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.isLogin
                        ? 'РЈРІС–Р№С‚Рё'
                        : 'Р—Р°СЂРµС”СЃС‚СЂСѓРІР°С‚РёСЃСЏ',
                  ),
          ),
        ],
      ),
    );
  }
}
