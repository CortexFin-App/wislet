import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/budget_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/budget_models.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:wislet/services/notification_service.dart';
import 'package:wislet/utils/database_helper.dart';

class LocalBudgetRepositoryImpl implements BudgetRepository {
  LocalBudgetRepositoryImpl(
    this._dbHelper,
    this._transactionRepository,
    this._notificationService,
  );

  final DatabaseHelper _dbHelper;
  final TransactionRepository _transactionRepository;
  final NotificationService _notificationService;

  @override
  Stream<List<Budget>> watchAllBudgets(int walletId) {
    return Stream.fromFuture(getAllBudgets(walletId))
        .map((either) => either.getOrElse((_) => []));
  }

  @override
  Future<Either<AppFailure, int>> createBudget(
    Budget budget,
    int walletId,
  ) async {
    try {
      final db = await _dbHelper.database;
      var newId = -1;
      await db.transaction((txn) async {
        final map = budget.toMap();
        map[DatabaseHelper.colBudgetWalletId] = walletId;
        newId = await txn.insert(DatabaseHelper.tableBudgets, map);
      });
      return Right(newId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateBudget(Budget budget) async {
    try {
      final db = await _dbHelper.database;
      var updatedRows = 0;
      await db.transaction((txn) async {
        final map = budget.toMap();
        updatedRows = await txn.update(
          DatabaseHelper.tableBudgets,
          map,
          where: '${DatabaseHelper.colBudgetId} = ?',
          whereArgs: [budget.id],
        );
      });
      return Right(updatedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteBudget(int budgetId) async {
    try {
      final db = await _dbHelper.database;
      var deletedRows = 0;
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        deletedRows = await txn.update(
          DatabaseHelper.tableBudgets,
          {
            DatabaseHelper.colBudgetIsDeleted: 1,
            DatabaseHelper.colBudgetUpdatedAt: now,
          },
          where: '${DatabaseHelper.colBudgetId} = ?',
          whereArgs: [budgetId],
        );
      });
      return Right(deletedRows);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Budget>>> getAllBudgets(int walletId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableBudgets,
        where:
            '${DatabaseHelper.colBudgetWalletId} = ? AND ${DatabaseHelper.colBudgetIsDeleted} = 0',
        whereArgs: [walletId],
        orderBy: '${DatabaseHelper.colBudgetStartDate} DESC',
      );
      return Right(maps.map(Budget.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Budget?>> getActiveBudgetForDate(
    int walletId,
    DateTime date,
  ) async {
    try {
      final db = await _dbHelper.database;
      final dateString = date.toIso8601String().substring(0, 10);
      final maps = await db.query(
        DatabaseHelper.tableBudgets,
        where:
            '${DatabaseHelper.colBudgetWalletId} = ? AND ${DatabaseHelper.colBudgetIsActive} = 1 AND date(${DatabaseHelper.colBudgetStartDate}) <= ? AND date(${DatabaseHelper.colBudgetEndDate}) >= ? AND ${DatabaseHelper.colBudgetIsDeleted} = 0',
        whereArgs: [walletId, dateString, dateString],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Right(Budget.fromMap(maps.first));
      }
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createBudgetEnvelope(
    BudgetEnvelope envelope,
  ) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableBudgetEnvelopes,
        envelope.toMap(),
      );
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateBudgetEnvelope(
    BudgetEnvelope envelope,
  ) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.update(
        DatabaseHelper.tableBudgetEnvelopes,
        envelope.toMap(),
        where: '${DatabaseHelper.colEnvelopeId} = ?',
        whereArgs: [envelope.id],
      );
      return Right(id);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteBudgetEnvelope(int id) async {
    try {
      final db = await _dbHelper.database;
      final resultId = await db.delete(
        DatabaseHelper.tableBudgetEnvelopes,
        where: '${DatabaseHelper.colEnvelopeId} = ?',
        whereArgs: [id],
      );
      return Right(resultId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<BudgetEnvelope>>> getEnvelopesForBudget(
    int budgetId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableBudgetEnvelopes,
        where: '${DatabaseHelper.colEnvelopeBudgetId} = ?',
        whereArgs: [budgetId],
      );
      return Right(maps.map(BudgetEnvelope.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, BudgetEnvelope?>> getEnvelopeForCategory(
    int budgetId,
    int categoryId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableBudgetEnvelopes,
        where:
            '${DatabaseHelper.colEnvelopeBudgetId} = ? AND ${DatabaseHelper.colEnvelopeCategoryId} = ?',
        whereArgs: [budgetId, categoryId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Right(BudgetEnvelope.fromMap(maps.first));
      }
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> checkAndNotifyEnvelopeLimits(
    fin_transaction.Transaction transaction,
    int walletId,
  ) async {
    try {
      if (transaction.type != fin_transaction.TransactionType.expense ||
          transaction.categoryId < 1) {
        return const Right(null);
      }

      final activeBudgetResult =
          await getActiveBudgetForDate(walletId, transaction.date);
      await activeBudgetResult.fold(
        (l) async => null,
        (activeBudget) async {
          if (activeBudget == null ||
              (activeBudget.strategyType != BudgetStrategyType.envelope &&
                  activeBudget.strategyType != BudgetStrategyType.zeroBased)) {
            return;
          }

          final envelopeResult = await getEnvelopeForCategory(
            activeBudget.id!,
            transaction.categoryId,
          );
          await envelopeResult.fold(
            (l) async => null,
            (envelope) async {
              if (envelope == null ||
                  envelope.plannedAmountInBaseCurrency <= 0) {
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final totalSpentResult =
                  await _transactionRepository.getTotalAmount(
                walletId: walletId,
                startDate: activeBudget.startDate,
                endDate: activeBudget.endDate,
                transactionType: fin_transaction.TransactionType.expense,
                categoryId: envelope.categoryId,
              );

              await totalSpentResult.fold(
                (l) async => null,
                (totalSpentInBase) async {
                  final percentageSpent = (totalSpentInBase /
                          envelope.plannedAmountInBaseCurrency) *
                      100;

                  const double warningThreshold = 90;
                  const double exceededThreshold = 100;
                  final warningKey = 'envelope_notif_${envelope.id}_warn_sent';
                  final exceededKey =
                      'envelope_notif_${envelope.id}_exceed_sent';
                  final warningSent = prefs.getBool(warningKey) ?? false;
                  final exceededSent = prefs.getBool(exceededKey) ?? false;
                  final notificationIdBase = envelope.id! * 30000;

                  if (percentageSpent >= exceededThreshold && !exceededSent) {
                    await _notificationService.showNotification(
                      id: notificationIdBase + 2,
                      title: 'Бюджет конверта перевищено!',
                      body:
                          'Витрати в конверті "${envelope.name}" перевищили запланований ліміт.',
                      payload: 'budget/${activeBudget.id}',
                    );
                    await prefs.setBool(exceededKey, true);
                    await prefs.setBool(warningKey, true);
                  } else if (percentageSpent >= warningThreshold &&
                      !warningSent &&
                      !exceededSent) {
                    await _notificationService.showNotification(
                      id: notificationIdBase + 1,
                      title: 'Увага: Бюджет конверта',
                      body:
                          'Витрати в конверті "${envelope.name}" досягли ${percentageSpent.toStringAsFixed(0)}% від ліміту.',
                      payload: 'budget/${activeBudget.id}',
                    );
                    await prefs.setBool(warningKey, true);
                  } else if (percentageSpent < warningThreshold &&
                      (warningSent || exceededSent)) {
                    await prefs.setBool(warningKey, false);
                    await prefs.setBool(exceededKey, false);
                  }
                },
              );
            },
          );
        },
      );
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }
}
