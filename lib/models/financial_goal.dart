class FinancialGoal {
  FinancialGoal({
    required this.name,
    required this.originalTargetAmount,
    required this.originalCurrentAmount,
    required this.currencyCode,
    required this.targetAmountInBaseCurrency,
    required this.currentAmountInBaseCurrency,
    required this.creationDate,
    this.id,
    this.exchangeRateUsed,
    this.targetDate,
    this.iconName,
    this.notes,
    this.isAchieved = false,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    bool asBool(dynamic v, {bool def = false}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return def;
    }

    return FinancialGoal(
      id: map['id'] as int?,
      name: map['name'] as String,
      originalTargetAmount: (map['original_target_amount'] as num).toDouble(),
      originalCurrentAmount: (map['original_current_amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      exchangeRateUsed: (map['exchange_rate_used'] as num?)?.toDouble(),
      targetAmountInBaseCurrency:
          (map['target_amount_in_base_currency'] as num).toDouble(),
      currentAmountInBaseCurrency:
          (map['current_amount_in_base_currency'] as num).toDouble(),
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      creationDate: DateTime.parse(map['creation_date'] as String),
      iconName: map['icon_name'] as String?,
      notes: map['notes'] as String?,
      isAchieved: asBool(map['is_achieved']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: asBool(map['is_deleted']),
    );
  }

  final int? id;
  final String name;
  final double originalTargetAmount;
  final double originalCurrentAmount;
  final String currencyCode;
  final double? exchangeRateUsed;
  final double targetAmountInBaseCurrency;
  final double currentAmountInBaseCurrency;
  final DateTime? targetDate;
  final DateTime creationDate;
  final String? iconName;
  final String? notes;
  final bool isAchieved;
  final DateTime? updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'original_target_amount': originalTargetAmount,
      'original_current_amount': originalCurrentAmount,
      'currency_code': currencyCode,
      'exchange_rate_used': exchangeRateUsed,
      'target_amount_in_base_currency': targetAmountInBaseCurrency,
      'current_amount_in_base_currency': currentAmountInBaseCurrency,
      'target_date': targetDate?.toIso8601String(),
      'creation_date': creationDate.toIso8601String(),
      'icon_name': iconName,
      'notes': notes,
      'is_achieved': isAchieved ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  FinancialGoal copyWith({
    int? id,
    String? name,
    double? originalTargetAmount,
    double? originalCurrentAmount,
    String? currencyCode,
    double? exchangeRateUsed,
    double? targetAmountInBaseCurrency,
    double? currentAmountInBaseCurrency,
    DateTime? targetDate,
    DateTime? creationDate,
    String? iconName,
    String? notes,
    bool? isAchieved,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      originalTargetAmount: originalTargetAmount ?? this.originalTargetAmount,
      originalCurrentAmount:
          originalCurrentAmount ?? this.originalCurrentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRateUsed: exchangeRateUsed ?? this.exchangeRateUsed,
      targetAmountInBaseCurrency:
          targetAmountInBaseCurrency ?? this.targetAmountInBaseCurrency,
      currentAmountInBaseCurrency:
          currentAmountInBaseCurrency ?? this.currentAmountInBaseCurrency,
      targetDate: targetDate ?? this.targetDate,
      creationDate: creationDate ?? this.creationDate,
      iconName: iconName ?? this.iconName,
      notes: notes ?? this.notes,
      isAchieved: isAchieved ?? this.isAchieved,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
