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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalTargetAmount': originalTargetAmount,
      'originalCurrentAmount': originalCurrentAmount,
      'currencyCode': currencyCode,
      'exchangeRateUsed': exchangeRateUsed,
      'targetAmountInBaseCurrency': targetAmountInBaseCurrency,
      'currentAmountInBaseCurrency': currentAmountInBaseCurrency,
      'targetDate': targetDate?.toIso8601String(),
      'creationDate': creationDate.toIso8601String(),
      'iconName': iconName,
      'notes': notes,
      'isAchieved': isAchieved ? 1 : 0,
    };
  }

  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      name: map['name'],
      originalTargetAmount: (map['originalTargetAmount'] as num).toDouble(),
      originalCurrentAmount: (map['originalCurrentAmount'] as num).toDouble(),
      currencyCode: map['currencyCode'],
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      targetAmountInBaseCurrency: (map['targetAmountInBaseCurrency'] as num).toDouble(),
      currentAmountInBaseCurrency: (map['currentAmountInBaseCurrency'] as num).toDouble(),
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      creationDate: DateTime.parse(map['creationDate']),
      iconName: map['iconName'],
      notes: map['notes'],
      isAchieved: (map['isAchieved'] as int) == 1,
    );
  }
}