enum BudgetStrategyType {
  categoryBased,
  envelope,
  rule50_30_20,
  zeroBased,
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

class Budget {
  Budget({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.strategyType,
    this.id,
    this.plannedIncomeInBaseCurrency,
    this.isActive = true,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      strategyType: BudgetStrategyType.values.byName(map['strategy_type'] as String),
      plannedIncomeInBaseCurrency: (map['planned_income_in_base_currency'] as num?)?.toDouble(),
      isActive: (map['is_active'] is bool) ? map['is_active'] as bool : (map['is_active'] as int? ?? 1) == 1,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] as bool : (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final BudgetStrategyType strategyType;
  final double? plannedIncomeInBaseCurrency;
  final bool isActive;
  final DateTime? updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'strategy_type': strategyType.name,
      'planned_income_in_base_currency': plannedIncomeInBaseCurrency,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}

class BudgetEnvelope {
  BudgetEnvelope({
    required this.budgetId,
    required this.name,
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    this.id,
    this.exchangeRateUsed,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory BudgetEnvelope.fromMap(Map<String, dynamic> map) {
    return BudgetEnvelope(
      id: map['id'] as int?,
      budgetId: map['budget_id'] as int,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
      originalPlannedAmount: (map['original_planned_amount'] as num).toDouble(),
      originalCurrencyCode: map['original_currency_code'] as String,
      plannedAmountInBaseCurrency: (map['planned_amount_in_base_currency'] as num).toDouble(),
      exchangeRateUsed: (map['exchange_rate_used'] as num?)?.toDouble(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] as bool : (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  final int? id;
  final int budgetId;
  final String name;
  final int categoryId;
  final double originalPlannedAmount;
  final String originalCurrencyCode;
  final double plannedAmountInBaseCurrency;
  final double? exchangeRateUsed;
  final DateTime? updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'budget_id': budgetId,
      'name': name,
      'category_id': categoryId,
      'original_planned_amount': originalPlannedAmount,
      'original_currency_code': originalCurrencyCode,
      'planned_amount_in_base_currency': plannedAmountInBaseCurrency,
      'exchange_rate_used': exchangeRateUsed,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}
