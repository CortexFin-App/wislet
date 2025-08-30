import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sage_wallet_reborn/utils/app_palette.dart';

class PinPadWidget extends StatelessWidget {
  const PinPadWidget({
    required this.onNumberPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
    super.key,
  });

  final void Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onBiometricPressed;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return _buildActionButton(
            context,
            Icons.fingerprint,
            onBiometricPressed,
          );
        }
        if (index == 10) {
          return _buildNumberButton(context, '0');
        }
        if (index == 11) {
          return _buildActionButton(
            context,
            Icons.backspace_outlined,
            onBackspacePressed,
          );
        }
        return _buildNumberButton(context, (index + 1).toString());
      },
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return TextButton(
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        foregroundColor: AppPalette.darkPrimaryText,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onNumberPressed(number);
      },
      child: Text(
        number,
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    if (onPressed == null) return const SizedBox.shrink();
    return IconButton(
      iconSize: 32,
      icon: Icon(icon, color: AppPalette.darkSecondaryText),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}
