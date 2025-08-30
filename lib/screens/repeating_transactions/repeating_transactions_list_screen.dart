import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/repeating_transaction_repository.dart';
import 'package:sage_wallet_reborn/models/currency_model.dart';
import 'package:sage_wallet_reborn/models/repeating_transaction_model.dart';
import 'package:sage_wallet_reborn/models/transaction.dart';
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/screens/repeating_transactions/add_edit_repeating_transaction_screen.dart';
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/utils/fade_page_route.dart';
import 'package:sage_wallet_reborn/widgets/scaffold/patterned_scaffold.dart';
import 'package:shimmer/shimmer.dart';

class RepeatingTransactionsListScreen extends StatefulWidget {
  const RepeatingTransactionsListScreen({super.key});

  @override
  State<RepeatingTransactionsListScreen> createState() =>
      _RepeatingTransactionsListScreenState();
}

class _RepeatingTransactionsListScreenState
    extends State<RepeatingTransactionsListScreen> {
  final RepeatingTransactionRepository _repeatingTransactionRepository =
      getIt<RepeatingTransactionRepository>();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();

  List<RepeatingTransaction> _repeatingTransactions = [];
  Map<int, String> _categoryNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!_isLoading) setState(() => _isLoading = true);

    final categoriesEither =
        await _categoryRepository.getAllCategories(currentWalletId);
    if (!mounted) return;

    final categoryMap = categoriesEither.fold(
      (failure) => <int, String>{},
      (categories) => {
        for (final cat in categories)
          if (cat.id != null) cat.id!: cat.name,
      },
    );
    _categoryNames = categoryMap;

    final templatesEither = await _repeatingTransactionRepository
        .getAllRepeatingTransactions(currentWalletId);
    if (!mounted) return;

    templatesEither.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _repeatingTransactions = [];
            _isLoading = false;
          });
        }
      },
      (templates) {
        if (mounted) {
          setState(() {
            _repeatingTransactions = templates;
            _isLoading = false;
          });
        }
      },
    );
  }

  String _getFrequencyDetails(RepeatingTransaction template) {
    final frequencyStr = frequencyToString(template.frequency);
    final intervalStr =
        template.interval > 1 ? 'РєРѕР¶РЅС– ${template.interval}' : '';
    var details = '';

    switch (template.frequency) {
      case Frequency.daily:
        details = intervalStr.isEmpty
            ? frequencyStr
            : '$frequencyStr ($intervalStr РґРЅС–)';
      case Frequency.weekly:
        details = intervalStr.isEmpty
            ? frequencyStr
            : '$frequencyStr ($intervalStr С‚РёР¶РЅС–)';
        if (template.weekDays?.isNotEmpty ?? false) {
          final dayNames = <String>[];
          const weekDayMap = <int, String>{
            1: 'РџРЅ',
            2: 'Р’С‚',
            3: 'РЎСЂ',
            4: 'Р§С‚',
            5: 'РџС‚',
            6: 'РЎР±',
            7: 'РќРґ',
          };
          for (final dayIndex in template.weekDays!) {
            if (weekDayMap.containsKey(dayIndex)) {
              dayNames.add(weekDayMap[dayIndex]!);
            }
          }
          if (dayNames.isNotEmpty) details += ' РїРѕ: ${dayNames.join(', ')}';
        }
      case Frequency.monthly:
        details = intervalStr.isEmpty
            ? frequencyStr
            : '$frequencyStr ($intervalStr РјС–СЃСЏС†С–)';
        if (template.monthDay?.isNotEmpty ?? false) {
          details += template.monthDay == 'last'
              ? ' (РѕСЃС‚. РґРµРЅСЊ)'
              : ' (${template.monthDay} С‡РёСЃР»Р°)';
        }
      case Frequency.yearly:
        details = intervalStr.isEmpty
            ? frequencyStr
            : '$frequencyStr ($intervalStr СЂРѕРєРё)';
        if (template.yearMonth != null && template.yearDay != null) {
          details +=
              ' (${DateFormat('d MMMM', 'uk_UA').format(DateTime(2000, template.yearMonth!, template.yearDay!))})';
        }
    }
    return details;
  }

  Future<void> _navigateToEditScreen(RepeatingTransaction template) async {
    final result = await Navigator.push<bool>(
      context,
      FadePageRoute(
        builder: (context) =>
            AddEditRepeatingTransactionScreen(template: template),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteTemplate(int id) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Р’РёРґР°Р»РёС‚Рё С€Р°Р±Р»РѕРЅ?'),
          content: const Text(
            'Р¦РµР№ С€Р°Р±Р»РѕРЅ РїРѕРІС‚РѕСЂСЋРІР°РЅРѕС— С‚СЂР°РЅР·Р°РєС†С–С— Р±СѓРґРµ РІРёРґР°Р»РµРЅРѕ. Р’Р¶Рµ СЃС‚РІРѕСЂРµРЅС– РЅР° Р№РѕРіРѕ РѕСЃРЅРѕРІС– С‚СЂР°РЅР·Р°РєС†С–С— Р·Р°Р»РёС€Р°С‚СЊСЃСЏ. Р—Р°РїР»Р°РЅРѕРІР°РЅРµ РЅР°РіР°РґСѓРІР°РЅРЅСЏ РґР»СЏ С†СЊРѕРіРѕ С€Р°Р±Р»РѕРЅСѓ С‚Р°РєРѕР¶ Р±СѓРґРµ СЃРєР°СЃРѕРІР°РЅРѕ.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('РЎРєР°СЃСѓРІР°С‚Рё'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Р’РёРґР°Р»РёС‚Рё'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _repeatingTransactionRepository.deleteRepeatingTransaction(id);
      await _notificationService.cancelNotification(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('РЁР°Р±Р»РѕРЅ РІРёРґР°Р»РµРЅРѕ')),
        );
      }
    }
  }

  Widget _buildSkeletonListItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 14,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 12,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 12,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 4),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 24, height: 24, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[350]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonListItem(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternedScaffold(
      appBar: AppBar(
        title: const Text('РџРѕРІС‚РѕСЂСЋРІР°РЅС– С‚СЂР°РЅР·Р°РєС†С–С—'),
      ),
      body: _isLoading
          ? _buildShimmerLoadingList()
          : _repeatingTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.repeat_on_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'РќРµРјР°С” С€Р°Р±Р»РѕРЅС–РІ РїРѕРІС‚РѕСЂСЋРІР°РЅРёС… С‚СЂР°РЅР·Р°РєС†С–Р№.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'РќР°С‚РёСЃРЅС–С‚СЊ "+", С‰РѕР± СЃС‚РІРѕСЂРёС‚Рё РЅРѕРІРёР№ С€Р°Р±Р»РѕРЅ.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _repeatingTransactions.length,
                  itemBuilder: (context, index) {
                    final template = _repeatingTransactions[index];
                    final categoryName = _categoryNames[template.categoryId] ??
                        'РљР°С‚РµРіРѕСЂС–СЏ РЅРµ Р·РЅР°Р№РґРµРЅР°';
                    final currency = appCurrencies.firstWhere(
                      (c) => c.code == template.originalCurrencyCode,
                      orElse: () => Currency(
                        code: template.originalCurrencyCode,
                        symbol: template.originalCurrencyCode,
                        name: '',
                        locale: '',
                      ),
                    );
                    final formattedAmount = NumberFormat.currency(
                      locale: currency.locale,
                      symbol: currency.symbol,
                      decimalDigits: 2,
                    ).format(template.originalAmount);
                    final typeColor = template.type == TransactionType.income
                        ? Colors.green.shade700
                        : Colors.red.shade700;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          template.type == TransactionType.income
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: typeColor,
                          size: 30,
                        ),
                        title: Text(
                          template.description,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$formattedAmount ($categoryName)'),
                            Text(
                              'Р§Р°СЃС‚РѕС‚Р°: ${_getFrequencyDetails(template)}',
                            ),
                            Text(
                              'РќР°СЃС‚СѓРїРЅРµ СЃРїСЂР°С†СЋРІР°РЅРЅСЏ: ${DateFormat('dd.MM.yyyy HH:mm').format(template.nextDueDate)}',
                            ),
                            if (template.endDate != null)
                              Text(
                                'Р—Р°РєС–РЅС‡СѓС”С‚СЊСЃСЏ: ${DateFormat('dd.MM.yyyy').format(template.endDate!)}',
                              ),
                            Text(
                              'РЎС‚Р°С‚СѓСЃ: ${template.isActive ? 'РђРєС‚РёРІРЅРёР№' : 'РќРµР°РєС‚РёРІРЅРёР№'}',
                              style: TextStyle(
                                color: template.isActive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEditScreen(template);
                            } else if (value == 'delete') {
                              if (template.id != null) {
                                _deleteTemplate(template.id!);
                              }
                            }
                          },
                          itemBuilder: (context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Р РµРґР°РіСѓРІР°С‚Рё'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Р’РёРґР°Р»РёС‚Рё'),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToEditScreen(template),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'РЎС‚РІРѕСЂРёС‚Рё С€Р°Р±Р»РѕРЅ',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            FadePageRoute(
              builder: (context) => const AddEditRepeatingTransactionScreen(),
            ),
          );
          if (result == true && mounted) {
            await _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
