import 'package:flutter/material.dart';

enum StoryType { topExpenses, comparison, mostExpensiveDay, aiTip }

abstract class FinancialStory {
  final StoryType type;
  FinancialStory(this.type);
}

class TopExpensesStory extends FinancialStory {
  final String period;
  final List<ExpenseItem> topExpenses;
  TopExpensesStory({required this.period, required this.topExpenses}) : super(StoryType.topExpenses);
}

class ExpenseItem {
  final IconData icon;
  final String categoryName;
  final double percentage;
  final Color color;
  ExpenseItem({required this.icon, required this.categoryName, required this.percentage, required this.color});
}

class ComparisonStory extends FinancialStory {
  final String title;
  final String comparisonText;
  final double changePercentage;
  final bool isPositiveChange;
  ComparisonStory({required this.title, required this.comparisonText, required this.changePercentage, required this.isPositiveChange}) : super(StoryType.comparison);
}

class MostExpensiveDayStory extends FinancialStory {
  final String title;
  final String content;
  MostExpensiveDayStory({required this.title, required this.content}) : super(StoryType.mostExpensiveDay);
}

class AiTipStory extends FinancialStory {
  final String title;
  final String content;
  AiTipStory({required this.title, required this.content}) : super(StoryType.aiTip);
}