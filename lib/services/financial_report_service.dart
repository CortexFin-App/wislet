import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/data/repositories/transaction_repository.dart';
import 'package:sage_wallet_reborn/models/ai_insight.dart';
import 'package:sage_wallet_reborn/models/category.dart' as fin_category;
import 'package:sage_wallet_reborn/models/financial_story.dart';
import 'package:sage_wallet_reborn/models/transaction.dart' as fin_transaction;
import 'package:sage_wallet_reborn/services/ai_insight_service.dart';

class FinancialReportService {
  final TransactionRepository _transactionRepo = getIt<TransactionRepository>();
  final CategoryRepository _categoryRepo = getIt<CategoryRepository>();
  final AiInsightService _aiInsightService = getIt<AiInsightService>();

  Future<List<FinancialStory>> getFinancialStories({
    required int walletId,
  }) async {
    final stories = <FinancialStory>[];

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month);

    final expensesGroupedEither =
        await _transactionRepo.getExpensesGroupedByCategory(
      walletId,
      startOfMonth,
      now,
    );
    expensesGroupedEither.fold(
      (l) => null,
      (expenses) {
        if (expenses.isNotEmpty) {
          final totalExpenses = expenses.fold<double>(
            0,
            (sum, item) => sum + (item['totalAmount'] as num),
          );
          if (totalExpenses > 0) {
            stories.add(
              TopExpensesStory(
                period: 'РІ С†СЊРѕРјСѓ РјС–СЃСЏС†С–',
                topExpenses: expenses
                    .take(3)
                    .map(
                      (e) => ExpenseItem(
                        icon: Icons.label,
                        categoryName: e['categoryName'] as String,
                        percentage:
                            (e['totalAmount'] as double) / totalExpenses * 100,
                        color: Colors.primaries[
                            expenses.indexOf(e) % Colors.primaries.length],
                      ),
                    )
                    .toList(),
              ),
            );
          }
        }
      },
    );

    final thisMonthExpensesEither = await _transactionRepo.getTotalAmount(
      walletId: walletId,
      startDate: startOfMonth,
      endDate: now,
      transactionType: fin_transaction.TransactionType.expense,
    );

    await thisMonthExpensesEither.fold(
      (l) => null,
      (thisMonthExpenses) async {
        final startOfLastMonth = DateTime(now.year, now.month - 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);

        final lastMonthExpensesEither = await _transactionRepo.getTotalAmount(
          walletId: walletId,
          startDate: startOfLastMonth,
          endDate: endOfLastMonth,
          transactionType: fin_transaction.TransactionType.expense,
        );

        lastMonthExpensesEither.fold(
          (l) => null,
          (lastMonthExpenses) {
            if (lastMonthExpenses > 0) {
              final diff = lastMonthExpenses - thisMonthExpenses;
              final percentChange = (diff / lastMonthExpenses) * 100;
              stories.add(
                ComparisonStory(
                  title:
                      'РџРѕСЂС–РІРЅСЏРЅРЅСЏ Р· РјРёРЅСѓР»РёРј РјС–СЃСЏС†РµРј',
                  comparisonText:
                      'Р’РёС‚СЂР°С‚Рё С†СЊРѕРіРѕ РјС–СЃСЏС†СЏ ${diff > 0 ? 'РјРµРЅС€С–' : 'Р±С–Р»СЊС€С–'} РЅР° ${diff.abs().toStringAsFixed(0)} РіСЂРЅ',
                  changePercentage: percentChange,
                  isPositiveChange: diff > 0,
                ),
              );
            }
          },
        );
      },
    );

    final allCategoriesEither = await _categoryRepo.getAllCategories(walletId);
    final allCategories =
        allCategoriesEither.getOrElse((_) => <fin_category.Category>[]);

    final totalIncome = await _transactionRepo
        .getTotalAmount(
          walletId: walletId,
          startDate: startOfMonth,
          endDate: now,
          transactionType: fin_transaction.TransactionType.income,
        )
        .then((e) => e.getOrElse((_) => 0.0));
    final totalExpenses = await _transactionRepo
        .getTotalAmount(
          walletId: walletId,
          startDate: startOfMonth,
          endDate: now,
          transactionType: fin_transaction.TransactionType.expense,
        )
        .then((e) => e.getOrElse((_) => 0.0));

    final spendingByCategory = <String, double>{};
    final expensesGrouped = await _transactionRepo.getExpensesGroupedByCategory(
      walletId,
      startOfMonth,
      now,
    );
    expensesGrouped.fold(
      (l) => null,
      (r) {
        for (final item in r) {
          spendingByCategory[item['categoryName'] as String] =
              item['totalAmount'] as double;
        }
      },
    );

    final financialProfile = UserFinancialProfile(
      walletId: walletId,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      spendingByCategory: spendingByCategory,
      categories: allCategories,
    );

    final insight =
        await _aiInsightService.getInsight(financialProfile, _transactionRepo);
    if (insight != null) {
      stories.add(AiTipStory(title: insight.title, content: insight.content));
    }

    return stories;
  }
}
