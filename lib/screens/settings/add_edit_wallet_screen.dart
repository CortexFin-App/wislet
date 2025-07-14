import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';

class AddEditWalletScreen extends StatefulWidget {
  final Wallet? walletToEdit;
  final bool isFirstWallet;
  const AddEditWalletScreen({super.key, this.walletToEdit, this.isFirstWallet = false});

  @override
  State<AddEditWalletScreen> createState() => _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends State<AddEditWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool get _isEditing => widget.walletToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.walletToEdit?.name ?? 'Особистий');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final walletProvider = context.read<WalletProvider>();
    final name = _nameController.text.trim();
    try {
      if (_isEditing) {
        final updatedWallet = Wallet(
          id: widget.walletToEdit!.id,
          name: name,
          isDefault: widget.walletToEdit!.isDefault,
          ownerUserId: widget.walletToEdit!.ownerUserId,
        );
        await walletProvider.updateWallet(updatedWallet);
      } else {
        await walletProvider.createWallet(name: name);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isFirstWallet ? 'Створимо ваш перший гаманець' : (_isEditing ? 'Редагувати гаманець' : 'Новий гаманець')),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Назва гаманця',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Назва не може бути порожньою';
            }
            return null;
          },
        ),
      ),
      actions: [
        if (!widget.isFirstWallet)
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Скасувати'),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveWallet,
          child: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_isEditing ? 'Зберегти' : (widget.isFirstWallet ? 'Створити' : 'Створити')),
        ),
      ],
    );
  }
}