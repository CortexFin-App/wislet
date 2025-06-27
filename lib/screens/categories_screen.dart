import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/di/injector.dart';
import '../data/repositories/category_repository.dart';
import '../models/category.dart';
import '../providers/wallet_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  late TabController _tabController;
  Future<List<Category>>? _categoriesFuture;

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
      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId != null) {
        setState(() {
          _categoriesFuture = _categoryRepository.getAllCategories(walletId);
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    CategoryType selectedType = category?.type ?? CategoryType.expense;
    Bucket? selectedBucket = category?.bucket;

    await showDialog(
      context: context,
      builder: (context) {
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
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Скасувати')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final walletId = Provider.of<WalletProvider>(context, listen: false).currentWallet!.id!;
                      final newCategory = Category(
                        id: category?.id,
                        name: nameController.text.trim(),
                        type: selectedType,
                        bucket: selectedBucket,
                      );
                      if (category == null) {
                        await _categoryRepository.createCategory(newCategory, walletId);
                      } else {
                        await _categoryRepository.updateCategory(newCategory);
                      }
                      _loadCategories();
                      if(mounted) Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категорії'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Витрати'),
            Tab(text: 'Доходи'),
          ],
        ),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Помилка: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Категорій ще немає.'));
          }
          final allCategories = snapshot.data!;
          final expenseCategories = allCategories.where((c) => c.type == CategoryType.expense).toList();
          final incomeCategories = allCategories.where((c) => c.type == CategoryType.income).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories),
              _buildCategoryList(incomeCategories),
            ],
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
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          title: Text(category.name),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showAddEditCategoryDialog(category: category),
          ),
        );
      },
    );
  }
}