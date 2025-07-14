import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/di/injector.dart';
import '../../core/error/failures.dart';
import '../../models/financial_goal.dart';
import '../../models/currency_model.dart';
import '../../providers/wallet_provider.dart';
import '../../data/repositories/goal_repository.dart';
import '../../services/notification_service.dart';
import 'add_edit_financial_goal_screen.dart';

class FinancialGoalsListScreen extends StatefulWidget {
  final int? goalIdToHighlight;
  const FinancialGoalsListScreen({super.key, this.goalIdToHighlight});

  @override
  FinancialGoalsListScreenState createState() => FinancialGoalsListScreenState();
}

class FinancialGoalsListScreenState extends State<FinancialGoalsListScreen> {
  final GoalRepository _goalRepository = getIt<GoalRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();
  Future<Either<AppFailure, List<FinancialGoal>>>? _goalsFuture;
  int? _highlightedGoalId;

  @override
  void initState() {
    super.initState();
    _highlightedGoalId = widget.goalIdToHighlight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
  }

  @override
  void didUpdateWidget(covariant FinancialGoalsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.goalIdToHighlight != oldWidget.goalIdToHighlight && mounted) {
      setState(() {
        _highlightedGoalId = widget.goalIdToHighlight;
      });
    }
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      setState(() {
        _goalsFuture = Future.value(const Right([]));
      });
      return;
    }
    setState(() {
      _goalsFuture = _goalRepository.getAllFinancialGoals(currentWalletId);
    });
  }

  void _navigateToAddGoal() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditFinancialGoalScreen())
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  void _navigateToEditGoal(FinancialGoal goal) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddEditFinancialGoalScreen(goalToEdit: goal))
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  Future<void> _deleteGoal(FinancialGoal goalToDelete) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Видалити ціль?'),
            content: Text('Фінансову ціль "${goalToDelete.name}" буде видалено. Цю дію неможливо скасувати.'),
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
        });

    if (confirmDelete != true || !mounted || goalToDelete.id == null) return;

    final int goalId = goalToDelete.id!;
    await _goalRepository.deleteFinancialGoal(goalId);
    await _notificationService.cancelNotification(goalId * 10000 + 1);

    if (mounted && goalId == _highlightedGoalId) {
        setState(() { _highlightedGoalId = null; });
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Фінансову ціль "${goalToDelete.name}" видалено')),
    );
    refreshData();
  }

  String _getDaysRemainingText(DateTime? targetDate, bool isAchieved) {
    if (targetDate == null || isAchieved) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (targetDay.isBefore(today)) {
      return 'Термін вийшов';
    }
    final difference = targetDay.difference(today).inDays;
    if (difference == 0) return 'Сьогодні!';
    if (difference == 1) return 'Залишився 1 день';
    if (difference > 1 && difference < 5) return 'Залишилось $difference дні';
    return 'Залишилось $difference днів';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<Either<AppFailure, List<FinancialGoal>>>(
          future: _goalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _goalsFuture == null) {
              return _buildShimmerList();
            }

            return snapshot.data!.fold(
              (failure) => Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Помилка завантаження цілей: ${failure.userMessage}'),
              )),
              (goals) {
                if (goals.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalCard(goal);
                  },
                );
              }
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddGoal,
        tooltip: 'Додати нову фінансову ціль',
        icon: const Icon(Icons.add),
        label: const Text('Нова ціль'),
      ),
    );
  }

  Widget _buildGoalCard(FinancialGoal goal) {
    double progress = 0.0;
    if (goal.originalTargetAmount > 0) {
      progress = (goal.originalCurrentAmount / goal.originalTargetAmount).clamp(0.0, 1.0);
    }

    final goalCurrencyDetails = appCurrencies.firstWhere(
        (c) => c.code == goal.currencyCode,
        orElse: () => Currency(code: goal.currencyCode, symbol: goal.currencyCode, name: '', locale: 'uk_UA')
    );
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: goalCurrencyDetails.locale,
      symbol: goalCurrencyDetails.symbol,
      decimalDigits: 2
    );

    String progressText = "${currencyFormatter.format(goal.originalCurrentAmount)} / ${currencyFormatter.format(goal.originalTargetAmount)}";
    if (goal.isAchieved) {
      progressText = "Досягнуто! ${currencyFormatter.format(goal.originalTargetAmount)}";
    }

    final bool isHighlighted = goal.id == _highlightedGoalId;
    final String daysRemainingText = _getDaysRemainingText(goal.targetDate, goal.isAchieved);
    final Color progressColor = goal.isAchieved ? Colors.green.shade600 : Theme.of(context).colorScheme.primary;
    final IconData leadingIconData = goal.isAchieved ? Icons.check_circle_outline_rounded : Icons.flag_outlined;
    final Color leadingIconColor = goal.isAchieved ? Colors.green.shade600 : Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: isHighlighted ? 4.0 : 1.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: isHighlighted ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _navigateToEditGoal(goal),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: leadingIconColor.withAlpha(26),
                    child: Icon(leadingIconData, size: 22, color: leadingIconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(goal.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditGoal(goal);
                      } else if (value == 'delete') {
                        _deleteGoal(goal);
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
                ],
              ),
              const SizedBox(height: 16),
              Text(progressText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: progressColor.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("${(progress * 100).toStringAsFixed(0)}%", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: progressColor)),
                ],
              ),
              if (daysRemainingText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(daysRemainingText, style: goal.isAchieved ? Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green.shade800) : Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(179))),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.flag_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withAlpha(77)),
            const SizedBox(height: 24),
            Text(
              'Фінансових цілей ще немає',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Створюйте цілі, щоб відстежувати свій прогрес у накопиченнях!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Container(height: 140, color: Colors.white)
          );
        },
      ),
    );
  }
}