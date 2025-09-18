import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wislet/features/invitations/invitations_repository.dart';

class AcceptInviteScreen extends StatefulWidget {
  const AcceptInviteScreen({super.key});
  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final controller = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Прийняти інвайт')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Токен інвайту'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        final repo = context.read<InvitationsRepository>();
                        await repo.acceptInvitation(controller.text.trim());
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Інвайт прийнято')),
                        );
                        Navigator.pop(context, true);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: const Text('Прийняти'),
            ),
          ],
        ),
      ),
    );
  }
}
