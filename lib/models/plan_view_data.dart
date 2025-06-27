import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/models/plan.dart';

class PlanViewData {
  final int id;
  final int categoryId;
  final double originalPlannedAmount;
  final String originalCurrencyCode;
  final double plannedAmountInBaseCurrency;
  final double? exchangeRateUsed;
  final DateTime startDate;
  final DateTime endDate;
  final String categoryName;
  final CategoryType categoryType;

  PlanViewData({
    required this.id,
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    this.exchangeRateUsed,
    required this.startDate,
    required this.endDate,
    required this.categoryName,
    required this.categoryType,
  });

  factory PlanViewData.fromMap(Map<String, dynamic> map) {
    return PlanViewData(
      id: map['id'],
      categoryId: map['categoryId'],
      originalPlannedAmount: (map['originalPlannedAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'],
      plannedAmountInBaseCurrency: (map['plannedAmountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      categoryName: map['categoryName'],
      categoryType: CategoryType.values.firstWhere((e) => e.toString() == map['categoryType']),
    );
  }

  Plan toPlanModel() {
    return Plan(
        id: id,
        categoryId: categoryId,
        originalPlannedAmount: originalPlannedAmount,
        originalCurrencyCode: originalCurrencyCode,
        plannedAmountInBaseCurrency: plannedAmountInBaseCurrency,
        exchangeRateUsed: exchangeRateUsed,
        startDate: startDate,
        endDate: endDate
    );
  }
}