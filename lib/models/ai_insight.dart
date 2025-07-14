import 'package:sage_wallet_reborn/models/category.dart';

class AiInsight {
  final String title;
  final String content;

  AiInsight({required this.title, required this.content});
}

class UserFinancialProfile {
  final int walletId;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> spendingByCategory;
  final List<Category> categories;

  UserFinancialProfile({
    required this.walletId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.spendingByCategory,
    required this.categories,
  });
}