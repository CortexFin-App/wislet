import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/goal_repository.dart';
import 'package:wislet/models/currency_model.dart';
import 'package:wislet/models/financial_goal.dart';
import 'package:wislet/providers/wallet_provider.dart';
import 'package:wislet/screens/financial_goals/add_edit_financial_goal_screen.dart';
import 'package:wislet/services/notification_service.dart';

class FinancialGoalsListScreen extends StatefulWidget {
  const FinancialGoalsListScreen({this.goalIdToHighlight, super.key});
  final int? goalIdToHighlight;

  @override
  FinancialGoalsListScreenState createState() =>
      FinancialGoalsListScreenState();
}

class FinancialGoalsListScreenState extends State<FinancialGoalsListScreen> {
  final GoalRepository _goalRepository = getIt<GoalRepository>();
  final NotificationService _notificationService = getIt<NotificationService>();
  Stream<List<FinancialGoal>>? _goalsStream;
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

  void refreshData() {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      setState(() {
        _goalsStream = Stream.value([]);
      });
      return;
    }
    setState(() {
      _goalsStream = _goalRepository.watchAllFinancialGoals(currentWalletId);
    });
  }

  Future<void> _navigateToAddGoal() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditFinancialGoalScreen(),
      ),
    );
  }

  Future<void> _navigateToEditGoal(FinancialGoal goal) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditFinancialGoalScreen(goalToEdit: goal),
      ),
    );
  }

  Future<void> _deleteGoal(FinancialGoal goalToDelete) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Видалити ціль?'),
          content: Text(
            'Фінансову ціль "${goalToDelete.name}" буде видалено. Цю дію неможливо скасувати.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Видалити'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true || !mounted || goalToDelete.id == null) return;

    final goalId = goalToDelete.id!;
    await _goalRepository.deleteFinancialGoal(goalId);
    await _notificationService.cancelNotification(goalId * 10000 + 1);

    if (mounted && goalId == _highlightedGoalId) {
      setState(() {
        _highlightedGoalId = null;
      });
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Фінансову ціль "${goalToDelete.name}" видалено',
        ),
      ),
    );
  }

  String _getDaysRemainingText(DateTime? targetDate, bool isAchieved) {
    if (targetDate == null || isAchieved) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay =
        DateTime(targetDate.year, targetDate.month, targetDate.day);

    if (targetDay.isBefore(today)) {
      return 'Термін вийшов';
    }
    final difference = targetDay.difference(today).inDays;
    if (difference == 0) return 'Сьогодні!';
    if (difference == 1) return 'Залишився 1 день';
    if (difference > 1 && difference < 5) {
      return 'Залишилось $difference дні';
    }
    return 'Залишилось $difference днів';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<FinancialGoal>>(
        stream: _goalsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildShimmerList();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Помилка завантаження цілей: ${snapshot.error}',
                ),
              ),
            );
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(goal);
            },
          );
        },
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
    double progress = 0;
    if (goal.originalTargetAmount > 0) {
      progress = (goal.originalCurrentAmount / goal.originalTargetAmount)
          .clamp(0.0, 1.0);
    }

    final goalCurrencyDetails = appCurrencies.firstWhere(
      (c) => c.code == goal.currencyCode,
      orElse: () => Currency(
        code: goal.currencyCode,
        symbol: goal.currencyCode,
        name: '',
        locale: 'uk_UA',
      ),
    );
    final currencyFormatter = NumberFormat.currency(
      locale: goalCurrencyDetails.locale,
      symbol: goalCurrencyDetails.symbol,
      decimalDigits: 2,
    );

    var progressText =
        '${currencyFormatter.format(goal.originalCurrentAmount)} / ${currencyFormatter.format(goal.originalTargetAmount)}';
    if (goal.isAchieved) {
      progressText =
          'Досягнуто! ${currencyFormatter.format(goal.originalTargetAmount)}';
    }

    final isHighlighted = goal.id == _highlightedGoalId;
    final daysRemainingText =
        _getDaysRemainingText(goal.targetDate, goal.isAchieved);
    final progressColor = goal.isAchieved
        ? Colors.green.shade600
        : Theme.of(context).colorScheme.primary;
    final leadingIconData = goal.isAchieved
        ? Icons.check_circle_outline_rounded
        : Icons.flag_outlined;
    final leadingIconColor = goal.isAchieved
        ? Colors.green.shade600
        : Theme.of(context).colorScheme.secondary;

    return Card(
      elevation: isHighlighted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlighted
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              )
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEditGoal(goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: leadingIconColor.withAlpha(26),
                    child: Icon(
                      leadingIconData,
                      size: 22,
                      color: leadingIconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditGoal(goal);
                      } else if (value == 'delete') {
                        _deleteGoal(goal);
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
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
              Text(
                progressText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
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
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                  ),
                ],
              ),
              if (daysRemainingText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  daysRemainingText,
                  style: goal.isAchieved
                      ? Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.green.shade800)
                      : Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withAlpha(179),
                          ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 24),
            Text(
              'Фінансових цілей ще немає',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Створюйте цілі, щоб відстежувати свій прогрес у накопиченнях!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Container(height: 140, color: Colors.white),
          );
        },
      ),
    );
  }
}
