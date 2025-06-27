import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransactionModel;
import 'package:sage_wallet_reborn/models/transaction_view_data.dart';
import 'package:sage_wallet_reborn/models/wallet.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/services/exchange_rate_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sage_wallet_reborn/core/constants/app_constants.dart';

class LocalTransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper _dbHelper;
  final ExchangeRateService _exchangeRateService;

  LocalTransactionRepositoryImpl(this._dbHelper, this._exchangeRateService);

  Future<int> _getOrCreateTransferCategoryId(
    Transaction txn,
    int walletId,
    FinTransactionModel.TransactionType type,
  ) async {
    final categoryType = type == FinTransactionModel.TransactionType.income
        ? CategoryType.income.toString()
        : CategoryType.expense.toString();
    const transferCategoryName = "Перекази";

    final existing = await txn.query(
      DatabaseHelper.tableCategories,
      where:
          '${DatabaseHelper.colCategoryName} = ? AND ${DatabaseHelper.colCategoryType} = ? AND ${DatabaseHelper.colCategoryWalletId} = ?',
      whereArgs: [transferCategoryName, categoryType, walletId],
    );

    if (existing.isNotEmpty) {
      return existing.first[DatabaseHelper.colCategoryId] as int;
    } else {
      final newCategory = {
        DatabaseHelper.colCategoryName: transferCategoryName,
        DatabaseHelper.colCategoryType: categoryType,
        DatabaseHelper.colCategoryWalletId: walletId,
      };
      return await txn.insert(DatabaseHelper.tableCategories, newCategory);
    }
  }

  @override
  Future<void> createTransfer({
    required Wallet fromWallet,
    required Wallet toWallet,
    required double amount,
    required String currencyCode,
    required DateTime date,
    String? description,
  }) async {
    final db = await _dbHelper.database;

    double exchangeRate = 1.0;
    if (currencyCode != AppConstants.baseCurrencyCode) {
      final rateInfo = await _exchangeRateService.getConversionRate(
        currencyCode,
        AppConstants.baseCurrencyCode,
        date: date,
      );
      exchangeRate = rateInfo.rate;
    }
    
    final amountInBaseCurrency = amount * exchangeRate;

    await db.transaction((txn) async {
      final expenseCategoryId = await _getOrCreateTransferCategoryId(
          txn, fromWallet.id!, FinTransactionModel.TransactionType.expense);
      final incomeCategoryId = await _getOrCreateTransferCategoryId(
          txn, toWallet.id!, FinTransactionModel.TransactionType.income);

      final expenseTransaction = FinTransactionModel.Transaction(
        type: FinTransactionModel.TransactionType.expense,
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
      final expenseId =
          await txn.insert(DatabaseHelper.tableTransactions, expenseMap);

      final incomeTransaction = FinTransactionModel.Transaction(
        type: FinTransactionModel.TransactionType.income,
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
      final incomeId =
          await txn.insert(DatabaseHelper.tableTransactions, incomeMap);

      await txn.update(
        DatabaseHelper.tableTransactions,
        {DatabaseHelper.colTransactionLinkedTransferId: incomeId},
        where: '${DatabaseHelper.colTransactionId} = ?',
        whereArgs: [expenseId],
      );
    });
  }

  @override
  Future<FinTransactionModel.Transaction?> getTransaction(
      int transactionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.colTransactionId} = ?',
      whereArgs: [transactionId],
    );
    if (maps.isNotEmpty) {
      return FinTransactionModel.Transaction.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<FinTransactionModel.Transaction>> getTransactionsForGoal(
      int goalId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.colTransactionLinkedGoalId} = ?',
      whereArgs: [goalId],
      orderBy: '${DatabaseHelper.colTransactionDate} ASC',
    );
    return maps
        .map((map) => FinTransactionModel.Transaction.fromMap(map))
        .toList();
  }

  @override
  Future<int> createTransaction(
      FinTransactionModel.Transaction transaction, int walletId) async {
    final db = await _dbHelper.database;
    final map = transaction.toMap();
    map[DatabaseHelper.colTransactionWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableTransactions, map);
  }

  @override
  Future<int> updateTransaction(
      FinTransactionModel.Transaction transaction, int walletId) async {
    final db = await _dbHelper.database;
    final map = transaction.toMap();
    map[DatabaseHelper.colTransactionWalletId] = walletId;
    return await db.update(
      DatabaseHelper.tableTransactions,
      map,
      where: '${DatabaseHelper.colTransactionId} = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<int> deleteTransaction(int transactionId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableTransactions,
      where: '${DatabaseHelper.colTransactionId} = ?',
      whereArgs: [transactionId],
    );
  }

  @override
  Future<List<TransactionViewData>> getTransactionsWithDetails({
    required int walletId,
    String? orderBy,
    DateTime? startDate,
    DateTime? endDate,
    FinTransactionModel.TransactionType? filterTransactionType,
    int? filterCategoryId,
    int? limit,
    String? searchQuery,
  }) async {
    final db = await _dbHelper.database;
    final String defaultOrderBy =
        "t.${DatabaseHelper.colTransactionDate} DESC, t.${DatabaseHelper.colTransactionId} DESC";

    List<String> whereClauses = ['t.${DatabaseHelper.colTransactionWalletId} = ?'];
    List<dynamic> whereArgs = [walletId];

    if (startDate != null) {
      whereClauses.add("date(t.${DatabaseHelper.colTransactionDate}) >= date(?)");
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add("date(t.${DatabaseHelper.colTransactionDate}) <= date(?)");
      whereArgs.add(endDate.toIso8601String());
    }
    if (filterTransactionType != null) {
      whereClauses.add("t.${DatabaseHelper.colTransactionType} = ?");
      whereArgs.add(filterTransactionType.toString());
    }
    if (filterCategoryId != null) {
      whereClauses.add("t.${DatabaseHelper.colTransactionCategoryId} = ?");
      whereArgs.add(filterCategoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      String searchTerm = '%${searchQuery.toLowerCase()}%';
      whereClauses.add(
          "(LOWER(t.${DatabaseHelper.colTransactionDescription}) LIKE ? OR LOWER(c.${DatabaseHelper.colCategoryName}) LIKE ?)");
      whereArgs.add(searchTerm);
      whereArgs.add(searchTerm);
    }

    String whereStatement = "WHERE ${whereClauses.join(' AND ')}";
    String limitClause = limit != null ? "LIMIT $limit" : "";

    final String sql = '''
      SELECT 
        t.${DatabaseHelper.colTransactionId}, t.${DatabaseHelper.colTransactionType}, t.${DatabaseHelper.colTransactionOriginalAmount}, 
        t.${DatabaseHelper.colTransactionOriginalCurrencyCode}, t.${DatabaseHelper.colTransactionAmountInBaseCurrency}, 
        t.${DatabaseHelper.colTransactionExchangeRateUsed}, t.${DatabaseHelper.colTransactionDate}, t.${DatabaseHelper.colTransactionDescription}, 
        t.${DatabaseHelper.colTransactionCategoryId}, c.${DatabaseHelper.colCategoryName} AS categoryName, t.${DatabaseHelper.colTransactionLinkedGoalId}, t.${DatabaseHelper.colTransactionSubscriptionId}, t.${DatabaseHelper.colTransactionLinkedTransferId}, c.${DatabaseHelper.colCategoryBucket} 
      FROM ${DatabaseHelper.tableTransactions} t
      INNER JOIN ${DatabaseHelper.tableCategories} c ON t.${DatabaseHelper.colTransactionCategoryId} = c.${DatabaseHelper.colCategoryId}
      $whereStatement
      ORDER BY ${orderBy ?? defaultOrderBy}
      $limitClause 
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);
    return maps.map((map) => TransactionViewData.fromMap(map)).toList();
  }

  @override
  Future<double> getOverallBalance(int walletId) async {
    final db = await _dbHelper.database;
    double totalIncome = 0;
    var incomeResult = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total FROM ${DatabaseHelper.tableTransactions} WHERE ${DatabaseHelper.colTransactionType} = ? AND ${DatabaseHelper.colTransactionWalletId} = ?',
        [FinTransactionModel.TransactionType.income.toString(), walletId]);
    if (incomeResult.isNotEmpty && incomeResult.first['total'] != null) {
      totalIncome = (incomeResult.first['total'] as num).toDouble();
    }
    double totalExpenses = 0;
    var expenseResult = await db.rawQuery(
        'SELECT SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total FROM ${DatabaseHelper.tableTransactions} WHERE ${DatabaseHelper.colTransactionType} = ? AND ${DatabaseHelper.colTransactionWalletId} = ?',
        [FinTransactionModel.TransactionType.expense.toString(), walletId]);
    if (expenseResult.isNotEmpty && expenseResult.first['total'] != null) {
      totalExpenses = (expenseResult.first['total'] as num).toDouble();
    }
    return totalIncome - totalExpenses;
  }

  @override
  Future<double> getTotalAmount({
    required int walletId,
    required DateTime startDate,
    required DateTime endDate,
    required FinTransactionModel.TransactionType transactionType,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    List<String> whereClauses = [
      '${DatabaseHelper.colTransactionWalletId} = ?',
      '${DatabaseHelper.colTransactionType} = ?',
      '${DatabaseHelper.colTransactionDate} >= ?',
      '${DatabaseHelper.colTransactionDate} <= ?'
    ];
    List<dynamic> whereArgs = [
      walletId,
      transactionType.toString(),
      DateTime(startDate.year, startDate.month, startDate.day).toIso8601String(),
      DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
          .toIso8601String(),
    ];
    if (categoryId != null) {
      whereClauses.add('${DatabaseHelper.colTransactionCategoryId} = ?');
      whereArgs.add(categoryId);
    }

    final result = await db.query(
      DatabaseHelper.tableTransactions,
      columns: ['SUM(${DatabaseHelper.colTransactionAmountInBaseCurrency}) as total'],
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesGroupedByCategory(
      int walletId, DateTime startDate, DateTime endDate) async {
    final db = await _dbHelper.database;
    final String sql = '''
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
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [
      walletId,
      FinTransactionModel.TransactionType.expense.toString(),
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    return maps;
  }
}