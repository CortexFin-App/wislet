import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/providers/app_mode_provider.dart';
import 'package:sage_wallet_reborn/services/auth_service.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

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
        title: const Text('Онлайн-акаунт'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Вхід'),
            Tab(text: 'Реєстрація'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AuthForm(isLogin: true, tabController: _tabController),
          _AuthForm(isLogin: false, tabController: _tabController),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  final bool isLogin;
  final TabController tabController;
  const _AuthForm({required this.isLogin, required this.tabController});

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = getIt<AuthService>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showConfirmationMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isLogin) {
        await _authService.login(
            _emailController.text.trim(), _passwordController.text.trim());
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final result = await _authService.register(
            _emailController.text.trim(), _passwordController.text.trim());
        if (mounted) {
          if (result == RegistrationResult.needsConfirmation) {
            setState(() {
              _showConfirmationMessage = true;
            });
          } else if (result == RegistrationResult.success) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _errorMessage =
                  'Не вдалося зареєструватися. Можливо, користувач вже існує.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showConfirmationMessage) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined,
                size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Реєстрація майже завершена!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ми надіслали лист на ${_emailController.text} для підтвердження вашої пошти. Будь ласка, перейдіть за посиланням у листі, щоб активувати акаунт.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => widget.tabController.animateTo(0),
              child: const Text('Перейти на вкладку "Вхід"'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value == null || !value.contains('@') ? 'Введіть коректний email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Пароль'),
            obscureText: true,
            validator: (value) => value == null || value.length < 6
                ? 'Пароль має бути не менше 6 символів'
                : null,
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.isLogin ? 'Увійти' : 'Зареєструватися'),
          ),
        ],
      ),
    );
  }
}