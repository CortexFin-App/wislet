import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage_wallet_reborn/models/budget_models.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransactionModel;
import 'package:sage_wallet_reborn/services/notification_service.dart';
import 'package:sage_wallet_reborn/utils/database_helper.dart';
import 'package:sage_wallet_reborn/data/repositories/budget_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';

class LocalBudgetRepositoryImpl implements BudgetRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRepository _transactionRepository;
  final NotificationService _notificationService;

  LocalBudgetRepositoryImpl(this._dbHelper, this._transactionRepository, this._notificationService);

  @override
  Future<int> createBudget(Budget budget, int walletId) async {
    final db = await _dbHelper.database;
    final map = budget.toMap();
    map[DatabaseHelper.colBudgetWalletId] = walletId;
    return await db.insert(DatabaseHelper.tableBudgets, map);
  }

  @override
  Future<int> updateBudget(Budget budget) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableBudgets,
      budget.toMap(),
      where: '${DatabaseHelper.colBudgetId} = ?',
      whereArgs: [budget.id],
    );
  }

  @override
  Future<int> deleteBudget(int budgetId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableBudgets,
      where: '${DatabaseHelper.colBudgetId} = ?',
      whereArgs: [budgetId],
    );
  }

  @override
  Future<List<Budget>> getAllBudgets(int walletId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBudgets,
      where: '${DatabaseHelper.colBudgetWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseHelper.colBudgetStartDate} DESC',
    );
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  @override
  Future<Budget?> getActiveBudgetForDate(int walletId, DateTime date) async {
    final db = await _dbHelper.database;
    final dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableBudgets,
      where: '${DatabaseHelper.colBudgetWalletId} = ? AND ${DatabaseHelper.colBudgetIsActive} = 1 AND date(${DatabaseHelper.colBudgetStartDate}) <= ? AND date(${DatabaseHelper.colBudgetEndDate}) >= ?',
      whereArgs: [walletId, dateString, dateString],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> createBudgetEnvelope(BudgetEnvelope envelope) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.tableBudgetEnvelopes, envelope.toMap());
  }

  @override
  Future<int> updateBudgetEnvelope(BudgetEnvelope envelope) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableBudgetEnvelopes,
      envelope.toMap(),
      where: '${DatabaseHelper.colEnvelopeId} = ?',
      whereArgs: [envelope.id],
    );
  }

  @override
  Future<int> deleteBudgetEnvelope(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableBudgetEnvelopes,
      where: '${DatabaseHelper.colEnvelopeId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<BudgetEnvelope>> getEnvelopesForBudget(int budgetId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableBudgetEnvelopes,
      where: '${DatabaseHelper.colEnvelopeBudgetId} = ?',
      whereArgs: [budgetId],
    );
    return maps.map((map) => BudgetEnvelope.fromMap(map)).toList();
  }

  @override
  Future<BudgetEnvelope?> getEnvelopeForCategory(int budgetId, int categoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableBudgetEnvelopes,
      where: '${DatabaseHelper.colEnvelopeBudgetId} = ? AND ${DatabaseHelper.colEnvelopeCategoryId} = ?',
      whereArgs: [budgetId, categoryId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return BudgetEnvelope.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> checkAndNotifyEnvelopeLimits(FinTransactionModel.Transaction transaction, int walletId) async {
    if (transaction.type != FinTransactionModel.TransactionType.expense || transaction.categoryId < 1) return;
    final activeBudget = await getActiveBudgetForDate(walletId, transaction.date);
    if (activeBudget == null || (activeBudget.strategyType != BudgetStrategyType.envelope && activeBudget.strategyType != BudgetStrategyType.zeroBased)) {
      return;
    }
    
    final envelope = await getEnvelopeForCategory(activeBudget.id!, transaction.categoryId);
    if (envelope == null || envelope.plannedAmountInBaseCurrency <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    final totalSpentInBase = await _transactionRepository.getTotalAmount(
      walletId: walletId,
      startDate: activeBudget.startDate,
      endDate: activeBudget.endDate,
      transactionType: FinTransactionModel.TransactionType.expense,
      categoryId: envelope.categoryId,
    );
    
    final percentageSpent = (totalSpentInBase / envelope.plannedAmountInBaseCurrency) * 100;
    
    const double warningThreshold = 90.0;
    const double exceededThreshold = 100.0;
    String warningKey = 'envelope_notif_${envelope.id}_warn_sent';
    String exceededKey = 'envelope_notif_${envelope.id}_exceed_sent';
    bool warningSent = prefs.getBool(warningKey) ?? false;
    bool exceededSent = prefs.getBool(exceededKey) ?? false;
    int notificationIdBase = envelope.id! * 30000;

    if (percentageSpent >= exceededThreshold && !exceededSent) {
      String title = "Бюджет Конверта Перевищено!";
      String body = "Витрати в конверті \"${envelope.name}\" перевищили запланований ліміт.";
      await _notificationService.showNotification(notificationIdBase + 2, title, body, payload: 'budget/${activeBudget.id}');
      await prefs.setBool(exceededKey, true);
      await prefs.setBool(warningKey, true);
    } else if (percentageSpent >= warningThreshold && !warningSent && !exceededSent) {
      String title = "Увага: Бюджет Конверта";
      String body = "Витрати в конверті \"${envelope.name}\" досягли ${percentageSpent.toStringAsFixed(0)}% від ліміту.";
      await _notificationService.showNotification(notificationIdBase + 1, title, body, payload: 'budget/${activeBudget.id}');
      await prefs.setBool(warningKey, true);
    } else if (percentageSpent < warningThreshold && (warningSent || exceededSent)) {
      await prefs.setBool(warningKey, false);
      await prefs.setBool(exceededKey, false);
    }
  }
}