import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wislet/core/constants/app_constants.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction_model;
import 'package:wislet/models/transaction_view_data.dart';
import 'package:wislet/models/wallet.dart';
import 'package:wislet/services/error_monitoring_service.dart';
import 'package:wislet/services/exchange_rate_service.dart';
import 'package:wislet/utils/database_helper.dart';

double _asDouble(dynamic x) =>
    x == null ? 0.0 : (x is num ? x.toDouble() : double.parse(x.toString()));

class LocalTransactionRepositoryImpl implements TransactionRepository {
  LocalTransactionRepositoryImpl(this._dbHelper, this._exchangeRateService);

  final DatabaseHelper _dbHelper;
  final ExchangeRateService _exchangeRateService;

  Future<int> _getOrCreateTransferCategoryId(
    Transaction txn,
    int walletId,
    fin_transaction_model.TransactionType type,
    String userId,
  ) async {
    final categoryType = type.name;
    const transferCategoryName = 'Перекази';

    final existing = await txn.query(
      DatabaseHelper.tableCategories,
      where:
          '${DatabaseHelper.colCategoryName} = ? AND ${DatabaseHelper.colCategoryType} = ? AND ${DatabaseHelper.colCategoryWalletId} = ?',
      whereArgs: [transferCategoryName, categoryType, walletId],
    );

    if (existing.isNotEmpty) {
      return existing.first[DatabaseHelper.colCategoryId]! as int;
    } else {
      final newCategory = {
        DatabaseHelper.colCategoryName: transferCategoryName,
        DatabaseHelper.colCategoryType: categoryType,
        DatabaseHelper.colCategoryWalletId: walletId,
        DatabaseHelper.colCategoryUserId: userId,
      };
      return txn.insert(DatabaseHelper.tableCategories, newCategory);
    }
  }

  @override
  Stream<List<TransactionViewData>> watchTransactionsWithDetails({
    required int walletId,
  }) {
    final future = getTransactionsWithDetails(walletId: walletId);
    return Stream.fromFuture(future)
        .map((either) => either.getOrElse((_) => []));
  }

  @override
  Future<Either<AppFailure, void>> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  }) async {
    try {
      final db = await _dbHelper.database;
      final fromWalletOwnerId = fromWallet.ownerUserId;

      var exchangeRate = 1.0;
      if (currencyCode != AppConstants.baseCurrencyCode) {
        final rateInfo = await _exchangeRateService.getConversionRate(
          currencyCode,
          AppConstants.baseCurrencyCode,
          date: date,
        );
        exchangeRate = _asDouble(rateInfo.rate);
      }

      final amountInBaseCurrency = amount * exchangeRate;

      await db.transaction((txn) async {
        final expenseCategoryId = await _getOrCreateTransferCategoryId(
          txn,
          fromWallet.id!,
          fin_transaction_model.TransactionType.expense,
          fromWalletOwnerId,
        );
        final incomeCategoryId = await _getOrCreateTransferCategoryId(
          txn,
          toWallet.id!,
          fin_transaction_model.TransactionType.income,
          fromWalletOwnerId,
        );

        final expenseTransaction = fin_transaction_model.Transaction(
          type: fin_transaction_model.TransactionType.expense,
          originalAmount: amount,
          originalCurrencyCode: currencyCode,
          amountInBaseCurrency: amountInBaseCurrency,
          exchangeRateUsed: exchangeRate,
          categoryId: expenseCategoryId,
          date: date,
          description: description ?? 'Переказ до ${toWallet.name}',
        );

        final expenseMap = expenseTransaction.toMap();
        expenseMap[DatabaseHelper.colTransactionWalletId] = fromWallet.id;
        expenseMap[DatabaseHelper.colTransactionUserId] = fromWalletOwnerId;
        final expenseId = await txn.insert(
          DatabaseHelper.tableTransactions,
          expenseMap,
        );

        final incomeTransaction = fin_transaction_model.Transaction(
          type: fin_transaction_model.TransactionType.income,
          originalAmount: amount,
          originalCurrencyCode: currencyCode,
          amountInBaseCurrency: amountInBaseCurrency,
          exchangeRateUsed: exchangeRate,
          categoryId: incomeCategoryId,
          date: date,
          description: description ?? 'Переказ від ${fromWallet.name}',
          linkedTransferId: expenseId,
        );

        final incomeMap = incomeTransaction.toMap();
        incomeMap[DatabaseHelper.colTransactionWalletId] = toWallet.id;
        incomeMap[DatabaseHelper.colTransactionUserId] = fromWalletOwnerId;
        final incomeId = await txn.insert(
          DatabaseHelper.tableTransactions,
          incomeMap,
        );

        await txn.update(
          DatabaseHelper.tableTransactions,
          {DatabaseHelper.colTransactionLinkedTransferId: incomeId},
          where: '${DatabaseHelper.colTransactionId} = ?',
          whereArgs: [expenseId],
        );
      });
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, fin_transaction_model.Transaction?>> getTransaction(
    int transactionId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTransactions,
        where: '${DatabaseHelper.colTransactionId} = ?',
        whereArgs: [transactionId],
      );
      if (maps.isNotEmpty) {
        return Right(fin_transaction_model.Transaction.fromMap(maps.first));
      }
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>>
      getTransactionsForGoal(int goalId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTransactions,
        where: '${DatabaseHelper.colTransactionLinkedGoalId} = ?',
        whereArgs: [goalId],
        orderBy: '${DatabaseHelper.colTransactionDate} ASC',
      );
      return Right(
        maps.map(fin_transaction_model.Transaction.fromMap).toList(),
      );
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createTransaction(
    fin_transaction_model.Transaction transaction,
    int walletId,
    String userId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final map = transaction.toMap();
      map[DatabaseHelper.colTransactionWalletId] = walletId;
      map[DatabaseHelper.colTransactionUserId] = userId;
      final newId = await db.insert(DatabaseHelper.tableTransactions, map);
      return Right(newId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateTransaction(
    fin_transaction_model.Transaction transaction,
    int walletId,
    String userId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final map = transaction.toMap();
      map[DatabaseHelper.colTransactionWalletId] = walletId;
      map[DatabaseHelper.colTransactionUserId] = userId;
      final updatedId = await db.update(
        DatabaseHelper.tableTransactions,
        map,
        where: '${DatabaseHelper.colTransactionId} = ?',
        whereArgs: [transaction.id],
      );
      return Right(updatedId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteTransaction(int transactionId) async {
    try {
      final db = await _dbHelper.database;
      final deletedId = await db.delete(
        DatabaseHelper.tableTransactions,
        where: '${DatabaseHelper.colTransactionId} = ?',
        whereArgs: [transactionId],
      );
      return Right(deletedId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<TransactionViewData>>>
      getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    fin_transaction_model.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  }) async {
    try {
      final db = await _dbHelper.database;
      const defaultOrderBy =
          't.${DatabaseHelper.colTransactionDate} DESC, t.${DatabaseHelper.colTransactionId} DESC';

      final whereClauses = <String>[
        't.${DatabaseHelper.colTransactionWalletId} = ?',
        't.${DatabaseHelper.colTransactionIsDeleted} = 0',
      ];
      final whereArgs = <dynamic>[walletId];

      if (startDate != null) {
        whereClauses
            .add('date(t.${DatabaseHelper.colTransactionDate}) >= date(?)');
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClauses
            .add('date(t.${DatabaseHelper.colTransactionDate}) <= date(?)');
        whereArgs.add(endDate.toIso8601String());
      }
      if (filterTransactionType != null) {
        whereClauses.add('t.${DatabaseHelper.colTransactionType} = ?');
        whereArgs.add(filterTransactionType.name);
      }
      if (filterCategoryId != null) {
        whereClauses.add('t.${DatabaseHelper.colTransactionCategoryId} = ?');
        whereArgs.add(filterCategoryId);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = '%${searchQuery.toLowerCase()}%';
        whereClauses.add(
          '(LOWER(t.${DatabaseHelper.colTransactionDescription}) LIKE ? OR LOWER(c.${DatabaseHelper.colCategoryName}) LIKE ?)',
        );
        whereArgs.addAll([searchTerm, searchTerm]);
      }

      final whereStatement = 'WHERE ${whereClauses.join(' AND ')}';
      final limitClause = limit != null ? 'LIMIT $limit' : '';

      final sql = '''
        SELECT
          t.*, c.${DatabaseHelper.colCategoryName} AS categoryName, c.${DatabaseHelper.colCategoryBucket}
        FROM ${DatabaseHelper.tableTransactions} t
        INNER JOIN ${DatabaseHelper.tableCategories} c ON t.${DatabaseHelper.colTransactionCategoryId} = c.${DatabaseHelper.colCategoryId}
        $whereStatement
        ORDER BY ${orderBy ?? defaultOrderBy}
        $limitClause
      ''';

      final maps = await db.rawQuery(sql, whereArgs);
      return Right(maps.map(TransactionViewData.fromMap).toList());
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, double>> getOverallBalance(int walletId) async {
    try {
      final db = await _dbHelper.database;

      var totalIncome = 0.0;
      final incomeResult = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total FROM ${DatabaseHelper.tableTransactions} WHERE ${DatabaseHelper.colTransactionType} = ? AND ${DatabaseHelper.colTransactionWalletId} = ?',
        [fin_transaction_model.TransactionType.income.name, walletId],
      );
      if (incomeResult.isNotEmpty && incomeResult.first['total'] != null) {
        totalIncome = _asDouble(incomeResult.first['total']);
      }

      var totalExpenses = 0.0;
      final expenseResult = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total FROM ${DatabaseHelper.tableTransactions} WHERE ${DatabaseHelper.colTransactionType} = ? AND ${DatabaseHelper.colTransactionWalletId} = ?',
        [fin_transaction_model.TransactionType.expense.name, walletId],
      );
      if (expenseResult.isNotEmpty && expenseResult.first['total'] != null) {
        totalExpenses = _asDouble(expenseResult.first['total']);
      }

      return Right(totalIncome - totalExpenses);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, double>> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required fin_transaction_model.TransactionType transactionType,
    int? categoryId,
  }) async {
    try {
      final db = await _dbHelper.database;
      final whereClauses = <String>[
        '${DatabaseHelper.colTransactionWalletId} = ?',
        '${DatabaseHelper.colTransactionType} = ?',
        'date(${DatabaseHelper.colTransactionDate}) >= date(?)',
        'date(${DatabaseHelper.colTransactionDate}) <= date(?)',
      ];
      final whereArgs = <dynamic>[
        walletId,
        transactionType.name,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ];
      if (categoryId != null) {
        whereClauses.add('${DatabaseHelper.colTransactionCategoryId} = ?');
        whereArgs.add(categoryId);
      }

      final result = await db.query(
        DatabaseHelper.tableTransactions,
        columns: [
          'SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total',
        ],
        where: whereClauses.join(' AND '),
        whereArgs: whereArgs,
      );

      if (result.isNotEmpty && result.first['total'] != null) {
        return Right(_asDouble(result.first['total']));
      }
      return const Right(0);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Map<String, dynamic>>>>
      getExpensesGroupedByCategory(
    int walletId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _dbHelper.database;
      const sql = '''
        SELECT
          c.${DatabaseHelper.colCategoryName} AS categoryName,
          SUM(t.${DatabaseHelper.colTransactionAmountInBaseCurrency}) AS totalAmount
        FROM ${DatabaseHelper.tableTransactions} t
        INNER JOIN ${DatabaseHelper.tableCategories} c ON t.${DatabaseHelper.colTransactionCategoryId} = c.${DatabaseHelper.colCategoryId}
        WHERE t.${DatabaseHelper.colTransactionWalletId} = ?
          AND t.${DatabaseHelper.colTransactionType} = ?
          AND date(t.${DatabaseHelper.colTransactionDate}) >= date(?)
          AND date(t.${DatabaseHelper.colTransactionDate}) <= date(?)
        GROUP BY c.${DatabaseHelper.colCategoryId}, c.${DatabaseHelper.colCategoryName}
        HAVING SUM(t.${DatabaseHelper.colTransactionAmountInBaseCurrency}) > 0
        ORDER BY totalAmount DESC
      ''';
      final maps = await db.rawQuery(
        sql,
        [
          walletId,
          fin_transaction_model.TransactionType.expense.name,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
      );
      return Right(maps);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(DatabaseFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<fin_transaction_model.Transaction>>>
      getTransactionsSince(
    int walletId,
    String? lastSyncTimestamp,
  ) async {
    return const Right([]);
  }
}
