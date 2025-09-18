import 'package:wislet/models/category.dart';

class AiInsight {
  AiInsight({required this.title, required this.content});

  final String title;
  final String content;
}

class UserFinancialProfile {
  UserFinancialProfile({
    required this.walletId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.spendingByCategory,
    required this.categories,
  });

  final int walletId;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> spendingByCategory;
  final List<Category> categories;
}
