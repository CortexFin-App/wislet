import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../models/financial_goal.dart';
import '../../../services/error_monitoring_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/database_helper.dart';
import '../goal_repository.dart';
import '../transaction_repository.dart';

class LocalGoalRepositoryImpl implements GoalRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRepository _transactionRepository;
  final NotificationService _notificationService;

  LocalGoalRepositoryImpl(this._dbHelper, this._transactionRepository, this._notificationService);

  @override
  Future<Either<AppFailure, int>> createFinancialGoal(FinancialGoal goal, int walletId) async {
    try {
      final db = await _dbHelper.database;
      int newId = -1;
      await db.transaction((txn) async {
        final map = goal.toMap();
        map[DatabaseHelper.colGoalWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableFinancialGoals, map);

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'financial_goal',
          DatabaseHelper.colSyncEntityId: newId.toString(),
          DatabaseHelper.colSyncActionType: 'create',
          DatabaseHelper.colSyncPayload: jsonEncode(map..['id'] = newId),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(newId);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, FinancialGoal?>> getFinancialGoal(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFinancialGoals,
        where: '${DatabaseHelper.colGoalId} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Right(FinancialGoal.fromMap(maps.first));
      }
      return const Right(null);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<FinancialGoal>>> getAllFinancialGoals(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableFinancialGoals,
        where: '${DatabaseHelper.colGoalWalletId} = ? AND ${DatabaseHelper.colGoalIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colGoalCreationDate} DESC',
      );
      return Right(maps.map((map) => FinancialGoal.fromMap(map)).toList());
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateFinancialGoal(FinancialGoal goal) async {
    try {
      final db = await _dbHelper.database;
      int updatedRows = 0;
      await db.transaction((txn) async {
        final map = goal.toMap();
        updatedRows = await txn.update(
          DatabaseHelper.tableFinancialGoals,
          map,
          where: '${DatabaseHelper.colGoalId} = ?',
          whereArgs: [goal.id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'financial_goal',
          DatabaseHelper.colSyncEntityId: goal.id.toString(),
          DatabaseHelper.colSyncActionType: 'update',
          DatabaseHelper.colSyncPayload: jsonEncode(map),
          DatabaseHelper.colSyncTimestamp: DateTime.now().toIso8601String(),
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(updatedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteFinancialGoal(int id) async {
    try {
      final db = await _dbHelper.database;
      int deletedRows = 0;
       await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableFinancialGoals,
          { 'is_deleted': 1, 'updated_at': now },
          where: '${DatabaseHelper.colGoalId} = ?',
          whereArgs: [id],
        );

        await txn.insert(DatabaseHelper.tableSyncQueue, {
          DatabaseHelper.colSyncEntityType: 'financial_goal',
          DatabaseHelper.colSyncEntityId: id.toString(),
          DatabaseHelper.colSyncActionType: 'delete',
          DatabaseHelper.colSyncPayload: jsonEncode({'id': id}),
          DatabaseHelper.colSyncTimestamp: now,
          DatabaseHelper.colSyncStatus: 'pending'
        });
      });
      return Right(deletedRows);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> updateFinancialGoalProgress(int goalId) async {
    try {
      final goalResult = await getFinancialGoal(goalId);

      return await goalResult.fold<Future<Either<AppFailure, void>>>(
        (l) async => Left(l),
        (goal) async {
          if (goal == null) return const Right(null);

          final transactionsResult = await _transactionRepository.getTransactionsForGoal(goalId);

          return await transactionsResult.fold<Future<Either<AppFailure, void>>>(
            (l) async => Left(l),
            (linkedTransactions) async {
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
              return const Right(null);
            },
          );
        },
      );
    } catch (e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}