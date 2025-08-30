import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/features/invitations/invitations_repository.dart';

class CreateInviteScreen extends StatefulWidget {
  const CreateInviteScreen({required this.walletId, super.key});
  final int walletId;

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  String? token;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Створити інвайт')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final repo = context.read<InvitationsRepository>();
                        final t =
                            await repo.generateInvitation(widget.walletId);
                        setState(() => token = t);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: const Text('Згенерувати токен'),
            ),
            const SizedBox(height: 12),
            if (token != null) SelectableText(token!),
          ],
        ),
      ),
    );
  }
}
