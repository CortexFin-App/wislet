class Plan {
  Plan({
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    required this.startDate,
    required this.endDate,
    this.id,
    this.exchangeRateUsed,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      originalPlannedAmount: (map['originalPlannedAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'] as String,
      plannedAmountInBaseCurrency:
          (map['plannedAmountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] is bool)
          ? map['is_deleted'] as bool
          : (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  final int? id;
  final int categoryId;
  final double originalPlannedAmount;
  final String originalCurrencyCode;
  final double plannedAmountInBaseCurrency;
  final double? exchangeRateUsed;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? updatedAt;
  final bool isDeleted;

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
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }
}
