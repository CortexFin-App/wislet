import 'package:sage_wallet_reborn/models/category.dart';
import 'package:sage_wallet_reborn/models/plan.dart';

class PlanViewData {
  PlanViewData({
    required this.id,
    required this.categoryId,
    required this.originalPlannedAmount,
    required this.originalCurrencyCode,
    required this.plannedAmountInBaseCurrency,
    required this.startDate,
    required this.endDate,
    required this.categoryName,
    required this.categoryType,
    this.exchangeRateUsed,
  });

  factory PlanViewData.fromMap(Map<String, dynamic> map) {
    return PlanViewData(
      id: map['id'] as int,
      categoryId: map['categoryId'] as int,
      originalPlannedAmount: (map['originalPlannedAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'] as String,
      plannedAmountInBaseCurrency:
          (map['plannedAmountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      categoryName: map['categoryName'] as String,
      categoryType: CategoryType.values.firstWhere(
        (e) => e.toString() == map['categoryType'],
      ),
    );
  }

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

  Plan toPlanModel() {
    return Plan(
      id: id,
      categoryId: categoryId,
      originalPlannedAmount: originalPlannedAmount,
      originalCurrencyCode: originalCurrencyCode,
      plannedAmountInBaseCurrency: plannedAmountInBaseCurrency,
      exchangeRateUsed: exchangeRateUsed,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
