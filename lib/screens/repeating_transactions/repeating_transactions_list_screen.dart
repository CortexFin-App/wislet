import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/di/injector.dart';
import '../../models/repeating_transaction_model.dart';
import '../../models/currency_model.dart';
import '../../models/transaction.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/repeating_transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import 'add_edit_repeating_transaction_screen.dart';
import '../../services/notification_service.dart';
import '../../utils/fade_page_route.dart';

class RepeatingTransactionsListScreen extends StatefulWidget {
  const RepeatingTransactionsListScreen({super.key});

  @override
  State<RepeatingTransactionsListScreen> createState() =>
      _RepeatingTransactionsListScreenState();
}

class _RepeatingTransactionsListScreenState
    extends State<RepeatingTransactionsListScreen> {
  final RepeatingTransactionRepository _repeatingTransactionRepository = getIt<RepeatingTransactionRepository>();
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
    
    final categoriesEither = await _categoryRepository.getAllCategories(currentWalletId);
    if (!mounted) return;

    final categoryMap = categoriesEither.fold(
      (failure) => <int, String>{},
      (categories) => {
        for (var cat in categories)
          if (cat.id != null) cat.id!: cat.name
      },
    );
    _categoryNames = categoryMap;

    final templatesEither = await _repeatingTransactionRepository.getAllRepeatingTransactions(currentWalletId);
    if (!mounted) return;
    
    templatesEither.fold(
      (failure) {
        if(mounted){
          setState(() {
            _repeatingTransactions = [];
            _isLoading = false;
          });
        }
      },
      (templates) {
        if(mounted){
          setState(() {
            _repeatingTransactions = templates;
            _isLoading = false;
          });
        }
      },
    );
  }

  String _getFrequencyDetails(RepeatingTransaction template) {
    String frequencyStr = frequencyToString(template.frequency);
    String intervalStr = template.interval > 1 ? "кожні ${template.interval}" : "";
    String details = "";

    switch (template.frequency) {
      case Frequency.daily:
        details = intervalStr.isEmpty ? frequencyStr : "$frequencyStr ($intervalStr дні)";
        break;
      case Frequency.weekly:
        details = intervalStr.isEmpty ? frequencyStr : "$frequencyStr ($intervalStr тижні)";
        if (template.weekDays != null && template.weekDays!.isNotEmpty) {
          List<String> dayNames = [];
          const Map<int, String> weekDayMap = {1: 'Пн', 2: 'Вт', 3: 'Ср', 4: 'Чт', 5: 'Пт', 6: 'Сб', 7: 'Нд'};
          for (var dayIndex in template.weekDays!) {
            if(weekDayMap.containsKey(dayIndex)) dayNames.add(weekDayMap[dayIndex]!);
          }
          if(dayNames.isNotEmpty) details += " по: ${dayNames.join(', ')}";
        }
        break;
      case Frequency.monthly:
        details = intervalStr.isEmpty ? frequencyStr : "$frequencyStr ($intervalStr місяці)";
        if(template.monthDay != null && template.monthDay!.isNotEmpty) {
          details += template.monthDay == 'last' ? " (ост. день)" : " (${template.monthDay} числа)";
        }
        break;
      case Frequency.yearly:
        details = intervalStr.isEmpty ? frequencyStr : "$frequencyStr ($intervalStr роки)";
        if (template.yearMonth != null && template.yearDay != null) {
          details += " (${DateFormat('d MMMM', 'uk_UA').format(DateTime(2000,template.yearMonth!, template.yearDay!))})";
        }
        break;
    }
    return details;
  }

  Future<void> _navigateToEditScreen(RepeatingTransaction template) async {
    final result = await Navigator.push(
      context,
      FadePageRoute(builder: (context) => AddEditRepeatingTransactionScreen(template: template)),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _deleteTemplate(int id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Видалити шаблон?'),
          content: const Text('Цей шаблон повторюваної транзакції буде видалено. Вже створені на його основі транзакції залишаться. Заплановане нагадування для цього шаблону також буде скасовано.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Видалити'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _repeatingTransactionRepository.deleteRepeatingTransaction(id);
      await _notificationService.cancelNotification(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Шаблон видалено')),
        );
      }
    }
  }

  Widget _buildSkeletonListItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey[300]!)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30, 
              height: 30,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: MediaQuery.of(context).size.width * 0.5, height: 14, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
                  Container(width: MediaQuery.of(context).size.width * 0.4, height: 12, color: Colors.white, margin: const EdgeInsets.only(bottom: 4)),
                  Container(width: MediaQuery.of(context).size.width * 0.6, height: 12, color: Colors.white, margin: const EdgeInsets.only(bottom: 4)),
                  Container(width: MediaQuery.of(context).size.width * 0.3, height: 12, color: Colors.white),
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
        padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonListItem(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Повторювані транзакції'),
      ),
      body: _isLoading
          ? _buildShimmerLoadingList()
          : _repeatingTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.repeat_on_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Немає шаблонів повторюваних транзакцій.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Натисніть "+", щоб створити новий шаблон.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  itemCount: _repeatingTransactions.length,
                  itemBuilder: (context, index) {
                    final template = _repeatingTransactions[index];
                    final categoryName = _categoryNames[template.categoryId] ?? 'Категорія не знайдена';
                    final currency = appCurrencies.firstWhere(
                        (c) => c.code == template.originalCurrencyCode,
                        orElse: () => Currency(code: template.originalCurrencyCode, symbol: template.originalCurrencyCode, name: '', locale: ''));
                    final formattedAmount = NumberFormat.currency(
                            locale: currency.locale, symbol: currency.symbol, decimalDigits: 2)
                        .format(template.originalAmount);
                    final typeColor = template.type == TransactionType.income
                        ? Colors.green.shade700
                        : Colors.red.shade700;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: ListTile(
                        leading: Icon(
                          template.type == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: typeColor,
                          size: 30,
                        ),
                        title: Text(template.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$formattedAmount ($categoryName)'),
                            Text('Частота: ${_getFrequencyDetails(template)}'),
                            Text('Наступне спрацювання: ${DateFormat('dd.MM.yyyy HH:mm').format(template.nextDueDate)}'),
                            if (template.endDate != null)
                              Text('Закінчується: ${DateFormat('dd.MM.yyyy').format(template.endDate!)}'),
                            Text('Статус: ${template.isActive ? "Активний" : "Неактивний"}', style: TextStyle(color: template.isActive ? Colors.green : Colors.grey)),
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
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Редагувати'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Видалити'),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToEditScreen(template),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Створити шаблон',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            FadePageRoute(builder: (context) => const AddEditRepeatingTransactionScreen()),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}