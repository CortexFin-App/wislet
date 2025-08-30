import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/features/invitations/ui/invite_actions_row.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';

class InviteActionsSection extends StatelessWidget {
  const InviteActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final walletId = context.watch<WalletProvider>().currentWallet?.id;
    if (walletId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InviteActionsRow(walletId: walletId),
    );
  }
}
