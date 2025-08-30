import 'package:flutter/material.dart';

enum StoryType { topExpenses, comparison, mostExpensiveDay, aiTip }

abstract class FinancialStory {
  FinancialStory(this.type);
  final StoryType type;
}

class TopExpensesStory extends FinancialStory {
  TopExpensesStory({required this.period, required this.topExpenses})
      : super(StoryType.topExpenses);
  final String period;
  final List<ExpenseItem> topExpenses;
}

class ExpenseItem {
  ExpenseItem({
    required this.icon,
    required this.categoryName,
    required this.percentage,
    required this.color,
  });
  final IconData icon;
  final String categoryName;
  final double percentage;
  final Color color;
}

class ComparisonStory extends FinancialStory {
  ComparisonStory({
    required this.title,
    required this.comparisonText,
    required this.changePercentage,
    required this.isPositiveChange,
  }) : super(StoryType.comparison);
  final String title;
  final String comparisonText;
  final double changePercentage;
  final bool isPositiveChange;
}

class MostExpensiveDayStory extends FinancialStory {
  MostExpensiveDayStory({required this.title, required this.content})
      : super(StoryType.mostExpensiveDay);
  final String title;
  final String content;
}

class AiTipStory extends FinancialStory {
  AiTipStory({required this.title, required this.content})
      : super(StoryType.aiTip);
  final String title;
  final String content;
}
