class FinancialGoal {
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

  FinancialGoal({
    this.id,
    required this.name,
    required this.originalTargetAmount,
    this.originalCurrentAmount = 0.0,
    required this.currencyCode,
    this.exchangeRateUsed,
    required this.targetAmountInBaseCurrency,
    this.currentAmountInBaseCurrency = 0.0,
    this.targetDate,
    required this.creationDate,
    this.iconName,
    this.notes,
    this.isAchieved = false,
    this.updatedAt,
    this.isDeleted = false,
  });

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

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      name: map['name'],
      originalTargetAmount: (map['original_target_amount'] as num).toDouble(),
      originalCurrentAmount: (map['original_current_amount'] as num).toDouble(),
      currencyCode: map['currency_code'],
      exchangeRateUsed: (map['exchange_rate_used'] as num?)?.toDouble(),
      targetAmountInBaseCurrency: (map['target_amount_in_base_currency'] as num).toDouble(),
      currentAmountInBaseCurrency: (map['current_amount_in_base_currency'] as num).toDouble(),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      creationDate: DateTime.parse(map['creation_date']),
      iconName: map['icon_name'],
      notes: map['notes'],
      isAchieved: (map['is_achieved'] is bool) ? map['is_achieved'] : ((map['is_achieved'] as int? ?? 0) == 1),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }
}