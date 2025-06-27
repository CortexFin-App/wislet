enum BudgetStrategyType {
  categoryBased,
  envelope,
  rule50_30_20,
  zeroBased,
}

class Budget {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetStrategyType strategyType;
  final double? plannedIncomeInBaseCurrency;
  final bool isActive;

  Budget({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.strategyType,
    this.plannedIncomeInBaseCurrency,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'strategyType': strategyType.toString(),
      'plannedIncomeInBaseCurrency': plannedIncomeInBaseCurrency,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      strategyType: BudgetStrategyType.values.firstWhere((e) => e.toString() == map['strategyType']),
      plannedIncomeInBaseCurrency: (map['plannedIncomeInBaseCurrency'] as num?)?.toDouble(),
      isActive: map['isActive'] == 1,
    );
  }
}

class BudgetEnvelope {
  final int? id;
  final int budgetId;
  final String name;
  final int categoryId;
  final double originalPlannedAmount;
  final String originalCurrencyCode;
  final double plannedAmountInBaseCurrency;
  final double? exchangeRateUsed;

  BudgetEnvelope({
    this.id,
    required this.budgetId,
    required this.name,
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    this.exchangeRateUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budgetId': budgetId,
      'name': name,
      'categoryId': categoryId,
      'originalPlannedAmount': originalPlannedAmount,
      'originalCurrencyCode': originalCurrencyCode,
      'plannedAmountInBaseCurrency': plannedAmountInBaseCurrency,
      'exchangeRateUsed': exchangeRateUsed,
    };
  }

  factory BudgetEnvelope.fromMap(Map<String, dynamic> map) {
    return BudgetEnvelope(
      id: map['id'],
      budgetId: map['budgetId'],
      name: map['name'],
      categoryId: map['categoryId'],
      originalPlannedAmount: (map['originalPlannedAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'],
      plannedAmountInBaseCurrency: (map['plannedAmountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
    );
  }
}

String budgetStrategyTypeToString(BudgetStrategyType type) {
  switch (type) {
    case BudgetStrategyType.categoryBased:
      return 'За категоріями';
    case BudgetStrategyType.envelope:
      return 'Конверти';
    case BudgetStrategyType.rule50_30_20:
      return 'Правило 50/30/20';
    case BudgetStrategyType.zeroBased:
      return 'Нульовий бюджет';
  }
}