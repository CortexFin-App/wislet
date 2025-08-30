import 'package:flutter/material.dart';

class WalletSelector extends StatelessWidget {
  const WalletSelector({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Row(
        children: [
          Icon(Icons.account_balance_wallet),
          SizedBox(width: 8),
          Text('Wallet'),
        ],
      ),
    );
  }
}
