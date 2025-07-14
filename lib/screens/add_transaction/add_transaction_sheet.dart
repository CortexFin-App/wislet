import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/app_colors.dart';

class AddTransactionSheet extends StatelessWidget {
  const AddTransactionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: const _AddTransactionForm(),
          );
        },
      ),
    );
  }
}

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm();

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      context.read<TransactionProvider>().onDescriptionChanged(context, _descriptionController.text);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final suggestedCat = provider.suggestedCategory;
        if (suggestedCat != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategoryId != suggestedCat.id) {
              setState(() {
                _selectedCategoryId = suggestedCat.id;
              });
            }
          });
        }
        
        final frequentCategories = [
          Category(id: 1, name: 'Їжа', type: CategoryType.expense),
          Category(id: 2, name: 'Таксі', type: CategoryType.expense),
          Category(id: 3, name: 'Кафе', type: CategoryType.expense),
          Category(id: 4, name: 'Підписки', type: CategoryType.expense),
        ];

        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _amountController,
                style: const TextStyle(fontSize: 48, color: AppColors.primaryText, fontWeight: FontWeight.bold),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: frequentCategories.map((cat) {
                  return ActionChip(
                    label: Text(cat.name),
                    avatar: const Icon(Icons.label, size: 18),
                    backgroundColor: _selectedCategoryId == cat.id ? AppColors.accent.withAlpha(77) : AppColors.background,
                    labelStyle: const TextStyle(color: AppColors.primaryText),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryId = cat.id;
                      });
                      provider.clearSuggestion();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Опис або назва...',
                  hintStyle: const TextStyle(color: AppColors.secondaryText),
                  border: InputBorder.none,
                  prefixIcon: provider.isLoadingSuggestion
                      ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(strokeWidth: 2)))
                      : const Icon(Icons.edit_note, color: AppColors.secondaryText),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Деталі', style: TextStyle(color: AppColors.secondaryText)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Готово', style: TextStyle(fontSize: 18)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}