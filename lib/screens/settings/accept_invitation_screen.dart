import 'package:flutter/material.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/invitation_repository.dart';
import 'package:wislet/utils/app_palette.dart';

class AcceptInvitationScreen extends StatefulWidget {
  const AcceptInvitationScreen({this.invitationToken, super.key});

  final String? invitationToken;

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
      _linkController.text =
          'С‚РѕРєРµРЅ РѕС‚СЂРёРјР°РЅРѕ Р· РїРѕСЃРёР»Р°РЅРЅСЏ';
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Р—Р°РїСЂРѕС€РµРЅРЅСЏ СѓСЃРїС–С€РЅРѕ РїСЂРёР№РЅСЏС‚Рѕ! Р“Р°РјР°РЅРµС†СЊ РґРѕРґР°РЅРѕ РґРѕ РІР°С€РѕРіРѕ СЃРїРёСЃРєСѓ.',
          ),
        ),
      );
      navigator.pop();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('РџРѕРјРёР»РєР°: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('РџСЂРёР№РЅСЏС‚Рё Р·Р°РїСЂРѕС€РµРЅРЅСЏ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                    labelText:
                        'РџРѕСЃРёР»Р°РЅРЅСЏ-Р·Р°РїСЂРѕС€РµРЅРЅСЏ Р°Р±Рѕ РєРѕРґ',
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Р’СЃС‚Р°РІС‚Рµ РїРѕСЃРёР»Р°РЅРЅСЏ'
                      : null,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('РџСЂРёР№РЅСЏС‚Рё'),
                onPressed: _isLoading ? null : _acceptInvite,
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
        color: AppPalette.darkPrimary.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.darkPrimary),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Р—Р°РїСЂРѕС€РµРЅРЅСЏ РѕС‚СЂРёРјР°РЅРѕ Р· РїРѕСЃРёР»Р°РЅРЅСЏ. РќР°С‚РёСЃРЅС–С‚СЊ "РџСЂРёР№РЅСЏС‚Рё", С‰РѕР± РїСЂРѕРґРѕРІР¶РёС‚Рё.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
