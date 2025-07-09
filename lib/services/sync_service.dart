import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../core/di/injector.dart';
import '../providers/wallet_provider.dart';
import '../utils/database_helper.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/plan_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/debt_loan_repository.dart';
import '../data/repositories/repeating_transaction_repository.dart';
import '../models/transaction.dart' as fin_transaction;
import '../models/category.dart' as fin_category;
import '../models/wallet.dart' as fin_wallet;
import '../models/financial_goal.dart' as fin_goal;
import '../models/budget_models.dart' as fin_budget;
import '../models/plan.dart' as fin_plan;
import '../models/subscription_model.dart' as fin_sub;
import '../models/debt_loan_model.dart' as fin_debt;
import '../models/repeating_transaction_model.dart' as fin_rt;

class SyncService {
  final DatabaseHelper _dbHelper;
  final TransactionRepository _supabaseTransactionRepo;
  final CategoryRepository _supabaseCategoryRepo;
  final WalletRepository _supabaseWalletRepo;
  final GoalRepository _supabaseGoalRepo;
  final BudgetRepository _supabaseBudgetRepo;
  final PlanRepository _supabasePlanRepo;
  final SubscriptionRepository _supabaseSubRepo;
  final DebtLoanRepository _supabaseDebtRepo;
  final RepeatingTransactionRepository _supabaseRtRepo;
  
  bool _isSyncing = false;

  SyncService(
    this._dbHelper, 
    this._supabaseTransactionRepo, 
    this._supabaseCategoryRepo, 
    this._supabaseWalletRepo,
    this._supabaseGoalRepo,
    this._supabaseBudgetRepo,
    this._supabasePlanRepo,
    this._supabaseSubRepo,
    this._supabaseDebtRepo,
    this._supabaseRtRepo
  );

  Future<void> synchronize() async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint("SyncService: Synchronization started.");

    try {
      await _pullUpdates();
      await _pushUpdates();
    } catch (e) {
      debugPrint("SyncService: Synchronization failed: $e");
    } finally {
      _isSyncing = false;
      debugPrint("SyncService: Synchronization finished.");
    }
  }

  Future<void> _pullUpdates() async {
    debugPrint("SyncService: Starting pull phase...");
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getString('last_sync_timestamp');
    
    final walletProvider = getIt<WalletProvider>();
    if (walletProvider.wallets.isEmpty) await walletProvider.loadWallets();
    final wallets = walletProvider.wallets;

    for (var wallet in wallets) {
       if (wallet.id == null) continue;
       
       final remoteTransactionsResult = await _supabaseTransactionRepo.getTransactionsSince(wallet.id!, lastSyncTimestamp);
       remoteTransactionsResult.fold(
         (failure) => debugPrint("SyncService: Failed to pull transactions for wallet ${wallet.id}: ${failure.userMessage}"),
         (remoteTransactions) async {
            if (remoteTransactions.isEmpty) return;
            debugPrint("SyncService: Pulled ${remoteTransactions.length} transaction updates for wallet ${wallet.id}.");
            final db = await _dbHelper.database;
            await db.transaction((txn) async {
              for (var remoteTx in remoteTransactions) {
                await txn.insert(
                  DatabaseHelper.tableTransactions,
                  remoteTx.toMap(),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            });
         }
       );
    }

    await prefs.setString('last_sync_timestamp', DateTime.now().toIso8601String());
    debugPrint("SyncService: Pull phase completed.");
  }

  Future<void> _pushUpdates() async {
    debugPrint("SyncService: Starting push phase...");
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> pendingOperations;

    do {
      pendingOperations = await db.query(
        DatabaseHelper.tableSyncQueue,
        where: '${DatabaseHelper.colSyncStatus} = ?',
        whereArgs: ['pending'],
        limit: 20,
        orderBy: '${DatabaseHelper.colSyncTimestamp} ASC',
      );

      debugPrint("SyncService: Found ${pendingOperations.length} pending operations.");

      for (var op in pendingOperations) {
        bool success = await _handleOperation(op);
        await db.update(
          DatabaseHelper.tableSyncQueue,
          {'status': success ? 'success' : 'failed'},
          where: '${DatabaseHelper.colSyncId} = ?',
          whereArgs: [op[DatabaseHelper.colSyncId]],
        );
      }
    } while (pendingOperations.isNotEmpty);
    debugPrint("SyncService: Push phase completed.");
  }

  Future<bool> _handleOperation(Map<String, dynamic> operation) async {
    final type = operation[DatabaseHelper.colSyncActionType];
    final entity = operation[DatabaseHelper.colSyncEntityType];
    final payload = jsonDecode(operation[DatabaseHelper.colSyncPayload]);
    final walletId = payload['walletId'] ?? payload['wallet_id'];
    
    try {
      switch (entity) {
        case 'transaction':
          final tx = fin_transaction.Transaction.fromMap(payload);
          switch (type) {
            case 'create': await _supabaseTransactionRepo.createTransaction(tx, walletId); break;
            case 'update': await _supabaseTransactionRepo.updateTransaction(tx, walletId); break;
            case 'delete': await _supabaseTransactionRepo.deleteTransaction(tx.id!); break;
          }
          break;
        case 'category':
          final category = fin_category.Category.fromMap(payload);
           switch (type) {
            case 'create': await _supabaseCategoryRepo.createCategory(category, walletId); break;
            case 'update': await _supabaseCategoryRepo.updateCategory(category); break;
            case 'delete': await _supabaseCategoryRepo.deleteCategory(category.id!); break;
          }
          break;
        case 'wallet':
          final wallet = fin_wallet.Wallet.fromMap(payload);
          final ownerId = wallet.ownerUserId;
           switch (type) {
            case 'create': await _supabaseWalletRepo.createWallet(name: wallet.name, ownerUserId: ownerId, isDefault: wallet.isDefault); break;
            case 'update': await _supabaseWalletRepo.updateWallet(wallet); break;
            case 'delete': await _supabaseWalletRepo.deleteWallet(wallet.id!); break;
          }
          break;
        case 'financial_goal':
          final goal = fin_goal.FinancialGoal.fromMap(payload);
          switch (type) {
            case 'create': await _supabaseGoalRepo.createFinancialGoal(goal, walletId); break;
            case 'update': await _supabaseGoalRepo.updateFinancialGoal(goal); break;
            case 'delete': await _supabaseGoalRepo.deleteFinancialGoal(goal.id!); break;
          }
          break;
        case 'budget':
           final budget = fin_budget.Budget.fromMap(payload);
           switch (type) {
            case 'create': await _supabaseBudgetRepo.createBudget(budget, walletId); break;
            case 'update': await _supabaseBudgetRepo.updateBudget(budget); break;
            case 'delete': await _supabaseBudgetRepo.deleteBudget(budget.id!); break;
          }
          break;
        case 'plan':
           final plan = fin_plan.Plan.fromMap(payload);
           switch (type) {
             case 'create': await _supabasePlanRepo.createPlan(plan, walletId); break;
            case 'update': await _supabasePlanRepo.updatePlan(plan); break;
            case 'delete': await _supabasePlanRepo.deletePlan(plan.id!); break;
          }
          break;
        case 'subscription':
           final sub = fin_sub.Subscription.fromMap(payload);
           switch (type) {
            case 'create': await _supabaseSubRepo.createSubscription(sub, walletId); break;
            case 'update': await _supabaseSubRepo.updateSubscription(sub, walletId); break;
            case 'delete': await _supabaseSubRepo.deleteSubscription(sub.id!); break;
          }
          break;
        case 'debt_loan':
            final debt = fin_debt.DebtLoan.fromMap(payload);
           switch (type) {
            case 'create': await _supabaseDebtRepo.createDebtLoan(debt, walletId); break;
            case 'update': await _supabaseDebtRepo.updateDebtLoan(debt); break;
            case 'delete': await _supabaseDebtRepo.deleteDebtLoan(debt.id!); break;
          }
          break;
        case 'repeating_transaction':
           final rt = fin_rt.RepeatingTransaction.fromMap(payload);
           switch (type) {
            case 'create': await _supabaseRtRepo.createRepeatingTransaction(rt, walletId); break;
            case 'update': await _supabaseRtRepo.updateRepeatingTransaction(rt); break;
            case 'delete': await _supabaseRtRepo.deleteRepeatingTransaction(rt.id!); break;
          }
           break;
      }
      return true;
    } catch (e) {
      debugPrint("SyncService: Failed to handle sync operation: $operation. Error: $e");
      return false;
    }
  }
}