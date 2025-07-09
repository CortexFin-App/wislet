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
import '../../utils/fade_page_route.dart';
import 'add_edit_financial_goal_screen.dart';
import '../../services/notification_service.dart';

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
  bool _isLoading = true;
  int? _highlightedGoalId;

  @override
  void initState() {
    super.initState();
    _highlightedGoalId = widget.goalIdToHighlight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoals();
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

  Future<void> _loadGoals() async {
    if (!mounted) return;
    final walletProvider = context.read<WalletProvider>();
    final currentWalletId = walletProvider.currentWallet?.id;
    if (currentWalletId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!_isLoading) {
      setState(() { _isLoading = true;});
    }

    setState(() {
      _goalsFuture = _goalRepository.getAllFinancialGoals(currentWalletId);
    });

    _goalsFuture!.then((_) {
        if (mounted) {
            setState(() {
                _isLoading = false;
            });
        }
    });
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _highlightedGoalId = null;
    });
    await _loadGoals();
  }

  void _navigateToAddGoal() async {
    if(mounted) setState(() => _highlightedGoalId = null);
    final result = await Navigator.push(
      context,
      FadePageRoute(builder: (context) => const AddEditFinancialGoalScreen())
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  void _navigateToEditGoal(FinancialGoal goal) async {
    if(mounted) setState(() => _highlightedGoalId = null);
    final result = await Navigator.push(
      context,
      FadePageRoute(builder: (context) => AddEditFinancialGoalScreen(goalToEdit: goal))
    );
    if (result == true && mounted) {
      refreshData();
    }
  }

  Future<void> _deleteGoal(FinancialGoal goalToDelete) async {
    final messenger = ScaffoldMessenger.of(context);
    bool? confirmDelete = await showDialog<bool>(
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

    if (confirmDelete == true && mounted) {
      if (goalToDelete.id == null) return;
      final int goalId = goalToDelete.id!;
      await _goalRepository.deleteFinancialGoal(goalId);

      final int targetDateReminderId = goalId * 10000 + 1;
      await _notificationService.cancelNotification(targetDateReminderId);

      if (mounted && goalId == _highlightedGoalId) {
          setState(() { _highlightedGoalId = null; });
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Фінансову ціль "${goalToDelete.name}" видалено')),
      );
      refreshData();
    }
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.flag_outlined, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128)),
            const SizedBox(height: 24),
            Text(
              'Фінансових цілей ще немає',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Створюйте цілі, щоб відстежувати свій прогрес у накопиченнях!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Створити першу ціль'),
              onPressed: _navigateToAddGoal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGoalListItem() {
    final Color itemColor = Theme.of(context).cardColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 16, color: itemColor)),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: MediaQuery.of(context).size.width * 0.7, height: 12, color: itemColor, margin: const EdgeInsets.only(bottom: 8)),
            Container(width: double.infinity, height: 8, color: itemColor, margin: const EdgeInsets.only(bottom: 8)),
            Container(width: MediaQuery.of(context).size.width * 0.4, height: 12, color: itemColor),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoadingList() {
    final Color baseShimmerColor = Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!;
    final Color highlightShimmerColor = Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[500]!;

    return Shimmer.fromColors(
      baseColor: baseShimmerColor,
      highlightColor: highlightShimmerColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonGoalListItem(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<Either<AppFailure, List<FinancialGoal>>>(
          future: _goalsFuture,
          builder: (context, snapshot) {
            if (_isLoading || snapshot.connectionState == ConnectionState.waiting || _goalsFuture == null) {
              return _buildShimmerLoadingList();
            }
            if (!snapshot.hasData) {
              return _buildEmptyState(context);
            }

            return snapshot.data!.fold(
              (failure) => Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Помилка завантаження цілей: ${failure.userMessage}'),
              )),
              (goals) {
                if (goals.isEmpty) {
                  return _buildEmptyState(context);
                }
                return SafeArea(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
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
                      final IconData leadingIconData = goal.isAchieved ? Icons.check_circle_outline_rounded : (goal.iconName != null ? Icons.star_outline_rounded : Icons.flag_outlined);
                      final Color leadingIconColor = goal.isAchieved ? Colors.green.shade700 : Theme.of(context).colorScheme.secondary;

                      return Card(
                        elevation: isHighlighted ? 4.0 : 1.0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: isHighlighted ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5) : BorderSide.none,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: leadingIconColor.withAlpha(38),
                            child: Icon(leadingIconData, size: 26, color: leadingIconColor),
                          ),
                          title: Text(goal.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(progressText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: progressColor.withAlpha(51),
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("${(progress * 100).toStringAsFixed(0)}%", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: progressColor)),
                                ],
                              ),
                              if (daysRemainingText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(daysRemainingText, style: goal.isAchieved ? Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green.shade800) : Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(204))),
                              ]
                            ],
                          ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 24),
                            color: Theme.of(context).colorScheme.error.withAlpha(204),
                            tooltip: 'Видалити ціль',
                            onPressed: () => _deleteGoal(goal),
                          ),
                          onTap: () => _navigateToEditGoal(goal),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
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
}