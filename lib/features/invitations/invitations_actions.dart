import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:wislet/features/invitations/invitations_repository.dart';

Future<void> onCreateInvitePressed(BuildContext context, int walletId) async {
  final repo = context.read<InvitationsRepository>();
  final token = await repo.generateInvitation(walletId);
  await Clipboard.setData(ClipboardData(text: token));
}

Future<void> onAcceptInvitePressed(BuildContext context, String token) async {
  final repo = context.read<InvitationsRepository>();
  await repo.acceptInvitation(token);
}
