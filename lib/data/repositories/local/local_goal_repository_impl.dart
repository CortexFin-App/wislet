import 'package:sage_wallet_reborn/models/financial_goal.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransactionModel;
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/goal_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';

class LocalGoalRepositoryImpl implements GoalRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRepository _transactionRepository;
  final NotificationService _notificationService;

  LocalGoalRepositoryImpl(this._dbHelper, this._transactionRepository, this._notificationService);

  @override
  Future<int> createFinancialGoal(FinancialGoal goal, int walletId) async {
    final db = await _dbHelper.database;
    final map = goal.toMap();
    map[DatabaseHelper.colGoalWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableFinancialGoals, map);
  }

  @override
  Future<FinancialGoal?> getFinancialGoal(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFinancialGoals,
      where: '${DatabaseHelper.colGoalId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return FinancialGoal.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<FinancialGoal>> getAllFinancialGoals(int walletId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableFinancialGoals,
      where: '${DatabaseHelper.colGoalWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseHelper.colGoalCreationDate} DESC',
    );
    return maps.map((map) => FinancialGoal.fromMap(map)).toList();
  }

  @override
  Future<int> updateFinancialGoal(FinancialGoal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableFinancialGoals,
      goal.toMap(),
      where: '${DatabaseHelper.colGoalId} = ?',
      whereArgs: [goal.id],
    );
  }

  @override
  Future<int> deleteFinancialGoal(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableFinancialGoals,
      where: '${DatabaseHelper.colGoalId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateFinancialGoalProgress(int goalId) async {
    final FinancialGoal? goal = await getFinancialGoal(goalId);
    if (goal == null) {
      return;
    }
    final List<FinTransactionModel.Transaction> linkedTransactions = await _transactionRepository.getTransactionsForGoal(goalId);
    double newCurrentAmountInBaseCurrency = 0.0;
    for (var transaction in linkedTransactions) {
      newCurrentAmountInBaseCurrency += transaction.amountInBaseCurrency;
    }
    double newOriginalCurrentAmount;
    if (goal.currencyCode == "UAH" || goal.exchangeRateUsed == null || goal.exchangeRateUsed! <= 0) {
      newOriginalCurrentAmount = newCurrentAmountInBaseCurrency;
    } else {
      newOriginalCurrentAmount = newCurrentAmountInBaseCurrency / goal.exchangeRateUsed!;
    }
    newOriginalCurrentAmount = double.parse(newOriginalCurrentAmount.toStringAsFixed(2));
    bool newIsAchieved = newOriginalCurrentAmount >= goal.originalTargetAmount;
    FinancialGoal updatedGoal = FinancialGoal(
      id: goal.id,
      name: goal.name,
      originalTargetAmount: goal.originalTargetAmount,
      originalCurrentAmount: newOriginalCurrentAmount,
      currencyCode: goal.currencyCode,
      exchangeRateUsed: goal.exchangeRateUsed,
      targetAmountInBaseCurrency: goal.targetAmountInBaseCurrency,
      currentAmountInBaseCurrency: newCurrentAmountInBaseCurrency,
      targetDate: goal.targetDate,
      creationDate: goal.creationDate,
      iconName: goal.iconName,
      notes: goal.notes,
      isAchieved: newIsAchieved,
    );
    await updateFinancialGoal(updatedGoal);

    if (newIsAchieved && !goal.isAchieved) {
      String notificationTitle = "Ціль Досягнуто!  🎉 ";
      String notificationBody = "Вітаємо! Ви досягли фінансової цілі \"${goal.name}\".";
      int achievementNotificationId = goal.id! * 10000 + 2;
      await _notificationService.showNotification(
        achievementNotificationId,
        notificationTitle,
        notificationBody,
        payload: 'goal/${goal.id}',
        channelId: NotificationService.goalNotificationChannelId,
      );
      if (goal.targetDate != null) {
        int targetDateReminderId = goal.id! * 10000 + 1;
        await _notificationService.cancelNotification(targetDateReminderId);
      }
    }
  }
}