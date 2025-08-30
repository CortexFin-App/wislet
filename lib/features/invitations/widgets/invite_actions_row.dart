import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/features/invitations/invitations_repository.dart';

class InviteActionsRow extends StatelessWidget {
  const InviteActionsRow({required this.walletId, super.key});
  final int walletId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InvitationsRepository>();
    final messenger = ScaffoldMessenger.of(context);

    return Row(
      children: [
        FilledButton(
          onPressed: () async {
            final token = await repo.generateInvitation(walletId);
            await Clipboard.setData(ClipboardData(text: token));
            messenger.showSnackBar(
              SnackBar(content: Text('Токен скопійовано: $token')),
            );
          },
          child: const Text('Створити інвайт'),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: () async {
            final token = await showDialog<String>(
              context: context,
              builder: (ctx) => const _AskTokenDialog(),
            );
            if (token == null || token.isEmpty) return;
            await repo.acceptInvitation(token);
            messenger.showSnackBar(
              const SnackBar(content: Text('Інвайт прийнято')),
            );
          },
          child: const Text('Прийняти інвайт'),
        ),
      ],
    );
  }
}

class _AskTokenDialog extends StatefulWidget {
  const _AskTokenDialog();

  @override
  State<_AskTokenDialog> createState() => _AskTokenDialogState();
}

class _AskTokenDialogState extends State<_AskTokenDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Введіть токен інвайту'),
      content: TextField(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Ок'),
        ),
      ],
    );
  }
}
