import 'package:collection/collection.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/models/transaction.dart';
import '../models/ai_insight.dart';

class AiInsightService {
  Future<AiInsight?> getInsight(UserFinancialProfile profile, TransactionRepository transactionRepo) async {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    for (var entry in profile.spendingByCategory.entries) {
      final categoryName = entry.key;
      final thisMonthSpending = entry.value;

      final categoryId = (profile.categories.firstWhereOrNull((cat) => cat.name == categoryName))?.id;
      if (categoryId == null) continue;

      final lastMonthSpendingEither = await transactionRepo.getTotalAmount(
        walletId: profile.walletId,
        startDate: startOfLastMonth,
        endDate: endOfLastMonth,
        transactionType: TransactionType.expense,
        categoryId: categoryId,
      );

      final lastMonthSpending = lastMonthSpendingEither.getOrElse((_) => 0.0);

      if (thisMonthSpending > 500 && lastMonthSpending > 0 && thisMonthSpending > (lastMonthSpending * 2.5)) {
        return AiInsight(
          title: "Мудра порада",
          content: "Ваші витрати в категорії \"$categoryName\" цього місяця значно вищі за попередній. Можливо, варто переглянути цей аспект бюджету?",
        );
      }
    }
    
    return null;
  }
}