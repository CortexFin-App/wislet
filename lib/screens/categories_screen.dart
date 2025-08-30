import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/error/failures.dart';
import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/utils/app_palette.dart';
import 'package:sage_wallet_reborn/widgets/scaffold/patterned_scaffold.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
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
          _categoriesFuture =
              walletProvider.categoryRepository.getAllCategories(walletId);
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'РџРѕРјРёР»РєР°: РЅРµРјРѕР¶Р»РёРІРѕ РІРёР·РЅР°С‡РёС‚Рё Р°РєС‚РёРІРЅРёР№ РіР°РјР°РЅРµС†СЊ.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    var selectedType = category?.type ??
        (_tabController.index == 0
            ? CategoryType.expense
            : CategoryType.income);
    var selectedBucket = category?.bucket;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                category == null
                    ? 'РќРѕРІР° РєР°С‚РµРіРѕСЂС–СЏ'
                    : 'Р РµРґР°РіСѓРІР°С‚Рё РєР°С‚РµРіРѕСЂС–СЋ',
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'РќР°Р·РІР°'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Р’РІРµРґС–С‚СЊ РЅР°Р·РІСѓ'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CategoryType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'РўРёРї'),
                      items: const [
                        DropdownMenuItem(
                          value: CategoryType.expense,
                          child: Text('Р’РёС‚СЂР°С‚Р°'),
                        ),
                        DropdownMenuItem(
                          value: CategoryType.income,
                          child: Text('Р”РѕС…С–Рґ'),
                        ),
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
                        decoration: const InputDecoration(
                          labelText:
                              'Р“СЂСѓРїР° (РґР»СЏ Р±СЋРґР¶РµС‚Сѓ 50/30/20)',
                        ),
                        hint: const Text('РќРµ РІРєР°Р·Р°РЅРѕ'),
                        items: const [
                          DropdownMenuItem(child: Text('РќРµ РІРєР°Р·Р°РЅРѕ')),
                          DropdownMenuItem(
                            value: Bucket.needs,
                            child: Text('Р‘Р°Р·РѕРІС– РїРѕС‚СЂРµР±Рё'),
                          ),
                          DropdownMenuItem(
                            value: Bucket.wants,
                            child: Text('Р‘Р°Р¶Р°РЅРЅСЏ'),
                          ),
                          DropdownMenuItem(
                            value: Bucket.savings,
                            child: Text(
                              'Р—Р°РѕС‰Р°РґР¶РµРЅРЅСЏ/Р†РЅРІРµСЃС‚РёС†С–С—',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedBucket = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('РЎРєР°СЃСѓРІР°С‚Рё'),
                ),
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
                        await walletProvider.categoryRepository
                            .createCategory(newCategory, walletId);
                      } else {
                        await walletProvider.categoryRepository
                            .updateCategory(newCategory);
                      }

                      if (navigator.canPop()) navigator.pop(true);
                    }
                  },
                  child: const Text('Р—Р±РµСЂРµРіС‚Рё'),
                ),
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
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('РљР°С‚РµРіРѕСЂС–С—'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.darkAccent,
          tabs: const [
            Tab(text: 'Р’РёС‚СЂР°С‚Рё'),
            Tab(text: 'Р”РѕС…РѕРґРё'),
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
            return const Center(child: Text('Р—Р°РІР°РЅС‚Р°Р¶РµРЅРЅСЏ...'));
          }

          return snapshot.data!.fold(
              (failure) =>
                  Center(child: Text('РџРѕРјРёР»РєР°: ${failure.userMessage}')),
              (allCategories) {
            final expenseCategories = allCategories
                .where((c) => c.type == CategoryType.expense)
                .toList();
            final incomeCategories = allCategories
                .where((c) => c.type == CategoryType.income)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(expenseCategories),
                _buildCategoryList(incomeCategories),
              ],
            );
          });
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
      return const Center(
        child: Text('РќРµРјР°С” РєР°С‚РµРіРѕСЂС–Р№ С†СЊРѕРіРѕ С‚РёРїСѓ.'),
      );
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
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppPalette.darkSecondaryText,
              ),
              onPressed: () => _showAddEditCategoryDialog(category: category),
            ),
          ),
        );
      },
    );
  }
}
