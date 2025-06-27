import 'package:flutter/material.dart';
import '../../core/di/injector.dart';
import '../../models/invitation_model.dart';
import '../../data/repositories/invitation_repository.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});
  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>();
  late Future<List<Invitation>> _invitationsFuture;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  void _loadInvitations() {
    setState(() {
      _invitationsFuture = _invitationRepo.getMyPendingInvitations();
    });
  }

  Future<void> _respondToInvitation(
      String invitationId, InvitationStatus status) async {
    await _invitationRepo.respondToInvitation(invitationId, status);
    _loadInvitations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ваші запрошення')),
      body: FutureBuilder<List<Invitation>>(
        future: _invitationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Помилка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('У вас немає активних запрошень.'));
          }
          final invitations = snapshot.data!;
          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final inv = invitations[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Запрошення в гаманець "${inv.walletName}"'),
                  subtitle: Text('Від: ${inv.inviterName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _respondToInvitation(
                            inv.id, InvitationStatus.accepted),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _respondToInvitation(
                            inv.id, InvitationStatus.declined),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}