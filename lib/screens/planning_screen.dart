import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/di/injector.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/plan_view_data.dart';
import '../models/transaction.dart' as fin_transaction;
import '../providers/currency_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/fade_page_route.dart';
import 'planning/add_edit_plan_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final PlanRepository _planRepository = getIt<PlanRepository>();
  final TransactionRepository _transactionRepository = getIt<TransactionRepository>();
  late DateTime _selectedMonth;
  Future<List<Map<String, dynamic>>>? _plansFuture;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlans();
    });
  }

  void _loadPlans() {
    if (mounted) {
      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId != null) {
        setState(() {
          _plansFuture = _fetchPlansAndActuals(walletId);
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlansAndActuals(int walletId) async {
    final plansEither = await _planRepository.getPlansWithCategoryDetails(walletId);
    return plansEither.fold(
      (failure) => throw failure,
      (plansForMonth) async {
        final List<Map<String, dynamic>> result = [];
        for (var planData in plansForMonth) {
          if ((planData.startDate.month == _selectedMonth.month && planData.startDate.year == _selectedMonth.year) ||
              (planData.endDate.month == _selectedMonth.month && planData.endDate.year == _selectedMonth.year)) {
            
            final actualAmountEither = await _transactionRepository.getTotalAmount(
              walletId: walletId,
              startDate: planData.startDate,
              endDate: planData.endDate,
              transactionType: fin_transaction.TransactionType.expense,
              categoryId: planData.categoryId,
            );
            
            final actualAmount = actualAmountEither.getOrElse((l) => 0.0);

            result.add({
              'plan': planData,
              'actual': actualAmount,
            });
          }
        }
        return result;
      }
    );
  }
  
  void _changeMonth(int monthIncrement) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + monthIncrement);
      _loadPlans();
    });
  }

  void _navigateToAddPlan() async {
    final result = await Navigator.push(
        context, FadePageRoute(builder: (context) => AddEditPlanScreen(initialDate: _selectedMonth)));
    if (result == true && mounted) {
      _loadPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планування'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToAddPlan,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _plansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Помилка: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Планів на цей місяць немає.'));
                }
                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final planData = items[index]['plan'] as PlanViewData;
                    final actualAmount = items[index]['actual'] as double;
                    return _buildPlanItem(planData, actualAmount);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
          Text(
            DateFormat.yMMMM('uk_UA').format(_selectedMonth),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildPlanItem(PlanViewData plan, double actualAmount) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final plannedFormatted = currencyProvider.currencyFormatter.format(plan.plannedAmountInBaseCurrency);
    final actualFormatted = currencyProvider.currencyFormatter.format(actualAmount);
    final difference = plan.plannedAmountInBaseCurrency - actualAmount;
    final differenceFormatted = currencyProvider.currencyFormatter.format(difference);
    final progress = plan.plannedAmountInBaseCurrency > 0 ? (actualAmount / plan.plannedAmountInBaseCurrency).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor = Colors.green.shade600;
    if (progress > 0.8) progressColor = Colors.orange.shade600;
    if (progress >= 1.0) progressColor = Colors.red.shade700;
    
    return Card(
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(context, FadePageRoute(builder: (context) => AddEditPlanScreen(planToEdit: plan.toPlanModel())));
          if(result == true && mounted){
            _loadPlans();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.categoryName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('План:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(plannedFormatted, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Факт:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(actualFormatted, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: progressColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Залишок:', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    differenceFormatted,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: difference >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: progressColor.withAlpha(51),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}