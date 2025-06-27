import 'package:flutter/material.dart';
import '../../core/di/injector.dart';
import '../../data/repositories/invitation_repository.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String? invitationToken;

  const AcceptInvitationScreen({super.key, this.invitationToken});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final _invitationRepo = getIt<InvitationRepository>();
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get _isDeepLink => widget.invitationToken != null;

  @override
  void initState() {
    super.initState();
    if (_isDeepLink) {
      _linkController.text = 'токен отримано з посилання';
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvite() async {
    if (_formKey.currentState?.validate() == false || _isLoading) return;

    setState(() => _isLoading = true);

    final token = _isDeepLink
        ? widget.invitationToken!
        : _linkController.text.trim().split('/').last;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _invitationRepo.acceptInvitation(token);
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Запрошення успішно прийнято! Гаманець додано до вашого списку.')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Помилка: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Прийняти запрошення')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isDeepLink)
                _buildDeepLinkInfo()
              else
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Посилання-запрошення або код',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Вставте посилання' : null,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Прийняти'),
                onPressed: _isLoading ? null : _acceptInvite,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeepLinkInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Запрошення отримано з посилання. Натисніть "Прийняти", щоб продовжити.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}