import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';

class AddEditWalletScreen extends StatefulWidget {
  final Wallet? walletToEdit;

  const AddEditWalletScreen({super.key, this.walletToEdit});

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
    _nameController = TextEditingController(text: widget.walletToEdit?.name ?? '');
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
        await walletProvider.createWallet(name);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати гаманець' : 'Новий гаманець'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _saveWallet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Назва гаманця',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Назва не може бути порожньою';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ))
                        : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Зберегти зміни' : 'Створити'),
                    onPressed: _isSaving ? null : _saveWallet,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}