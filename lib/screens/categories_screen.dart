import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:provider/provider.dart';
import '../core/error/failures.dart';
import '../models/category.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_palette.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Either<AppFailure, List<Category>>>? _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadCategories();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }
  
  void _loadCategories() {
    if (mounted) {
      final walletProvider = context.read<WalletProvider>();
      final walletId = walletProvider.currentWallet?.id;
      if (walletId != null) {
         setState(() {
           _categoriesFuture = walletProvider.categoryRepository.getAllCategories(walletId);
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _showAddEditCategoryDialog({Category? category}) async {
    final walletProvider = context.read<WalletProvider>();
    final walletId = walletProvider.currentWallet?.id;
    if (walletId == null) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка: неможливо визначити активний гаманець.'))
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    CategoryType selectedType = category?.type ?? (_tabController.index == 0 ? CategoryType.expense : CategoryType.income);
    Bucket? selectedBucket = category?.bucket;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? 'Нова категорія' : 'Редагувати категорію'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Назва'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Введіть назву' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CategoryType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Тип'),
                      items: const [
                         DropdownMenuItem(value: CategoryType.expense, child: Text('Витрата')),
                         DropdownMenuItem(value: CategoryType.income, child: Text('Дохід')),
                      ],
                      onChanged: (value) {
                         setDialogState(() {
                          selectedType = value!;
                          if (selectedType == CategoryType.income) {
                            selectedBucket = null;
                          }
                        });
                      },
                    ),
                    if (selectedType == CategoryType.expense)
                      DropdownButtonFormField<Bucket?>(
                        value: selectedBucket,
                        decoration: const InputDecoration(labelText: 'Група (для бюджету 50/30/20)'),
                        hint: const Text('Не вказано'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Не вказано')),
                          DropdownMenuItem(value: Bucket.needs, child: Text('Базові потреби')),
                          DropdownMenuItem(value: Bucket.wants, child: Text('Бажання')),
                          DropdownMenuItem(value: Bucket.savings, child: Text('Заощадження/Інвестиції')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                             selectedBucket = value;
                          });
                        },
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Скасувати')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                       final newCategory = Category(
                        id: category?.id,
                        name: nameController.text.trim(),
                        type: selectedType,
                        bucket: selectedBucket,
                      );
                      
                      final navigator = Navigator.of(context);
                      if (category == null) {
                        await walletProvider.categoryRepository.createCategory(newCategory, walletId);
                      } else {
                        await walletProvider.categoryRepository.updateCategory(newCategory);
                      }
              
                      if(navigator.canPop()) navigator.pop(true);
                    }
                  },
                  child: const Text('Зберегти'),
                )
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категорії'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.darkAccent,
          tabs: const [
            Tab(text: 'Витрати'),
            Tab(text: 'Доходи'),
          ],
        ),
      ),
      body: FutureBuilder<Either<AppFailure, List<Category>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Завантаження...'));
          }

          return snapshot.data!.fold(
            (failure) => Center(child: Text('Помилка: ${failure.userMessage}')),
            (allCategories) {
              final expenseCategories = allCategories.where((c) => c.type == CategoryType.expense).toList();
              final incomeCategories = allCategories.where((c) => c.type == CategoryType.income).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(expenseCategories),
                  _buildCategoryList(incomeCategories),
                ],
              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('Немає категорій цього типу.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(category.name),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppPalette.darkSecondaryText),
              onPressed: () => _showAddEditCategoryDialog(category: category),
            ),
          ),
        );
      },
    );
  }
}