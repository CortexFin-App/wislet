class Plan {
  final int? id;
  final int categoryId;
  final double originalPlannedAmount;
  final String originalCurrencyCode;
  final double plannedAmountInBaseCurrency;
  final double? exchangeRateUsed;
  final DateTime startDate;
  final DateTime endDate;

  Plan({
    this.id,
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    this.exchangeRateUsed,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'originalPlannedAmount': originalPlannedAmount,
      'originalCurrencyCode': originalCurrencyCode,
      'plannedAmountInBaseCurrency': plannedAmountInBaseCurrency,
      'exchangeRateUsed': exchangeRateUsed,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      originalPlannedAmount: (map['originalPlannedAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'] as String,
      plannedAmountInBaseCurrency: (map['plannedAmountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );
  }
}