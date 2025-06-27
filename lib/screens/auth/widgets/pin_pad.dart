import 'package:flutter/material.dart';

class PinPadWidget extends StatelessWidget {
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onBiometricPressed;

  const PinPadWidget({
    super.key,
    required this.onNumberPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return onBiometricPressed != null
              ? _buildActionButton(context, Icons.fingerprint, onBiometricPressed!)
              : const SizedBox.shrink();
        }
        if (index == 10) {
          return _buildNumberButton(context, '0');
        }
        if (index == 11) {
          return _buildActionButton(context, Icons.backspace_outlined, onBackspacePressed);
        }
        return _buildNumberButton(context, (index + 1).toString());
      },
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return TextButton(
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () => onNumberPressed(number),
      child: Text(
        number,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      iconSize: 32,
      icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      onPressed: onPressed,
    );
  }
}