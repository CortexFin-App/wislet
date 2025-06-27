import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as FinTransaction;
import 'package:sage_wallet_reborn/services/notification_service.dart';

class AnalyticsService {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final NotificationService _notificationService;

  AnalyticsService(this._transactionRepo, this._categoryRepo, this._notificationService);

  Future<void> analyzeAndNotifyOnNewTransaction(FinTransaction.Transaction transaction, int walletId) async {
    if (transaction.type == FinTransaction.TransactionType.income) {
      return; 
    }

    try {
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      
      final recentTransactions = await _transactionRepo.getTransactionsWithDetails(
        walletId: walletId,
        startDate: threeMonthsAgo,
        endDate: now,
        filterCategoryId: transaction.categoryId,
        filterTransactionType: FinTransaction.TransactionType.expense,
      );

      if (recentTransactions.length < 5) {
        return; 
      }

      double totalSpendingLast3Months = 0;
      for (var tx in recentTransactions) {
        totalSpendingLast3Months += tx.amountInBaseCurrency;
      }
      double averageMonthlySpending = totalSpendingLast3Months / 3;
      
      final startOfCurrentMonth = DateTime(now.year, now.month, 1);
      double currentMonthSpending = await _transactionRepo.getTotalAmount(
        walletId: walletId,
        startDate: startOfCurrentMonth,
        endDate: now,
        transactionType: FinTransaction.TransactionType.expense,
        categoryId: transaction.categoryId
      );

      if (averageMonthlySpending > 100 && currentMonthSpending > (averageMonthlySpending * 2.5)) {
        final categoryName = await _categoryRepo.getCategoryNameById(transaction.categoryId);
        final notificationId = 900000 + transaction.categoryId; 
        
        await _notificationService.showNotification(
          notificationId,
          "Незвична активність 📈",
          "Витрати в категорії \"$categoryName\" цього місяця значно вищі за середні. Все під контролем?",
          channelId: NotificationService.goalNotificationChannelId
        );
      }
    } catch (e) {
      debugPrint("AnalyticsService Error: $e");
    }
  }
}