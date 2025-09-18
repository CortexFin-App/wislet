import 'package:wislet/models/category.dart' as fin_category;
import 'package:wislet/models/transaction.dart' as fin_transaction;
import 'package:wislet/utils/database_helper.dart';

class TransactionViewData {
  TransactionViewData({
    required this.id,
    required this.type,
    required this.originalAmount,
    required this.originalCurrencyCode,
    required this.amountInBaseCurrency,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    this.exchangeRateUsed,
    this.description,
    this.linkedGoalId,
    this.subscriptionId,
    this.categoryBucket,
  });

  factory TransactionViewData.fromMap(Map<String, dynamic> map) {
    String categoryNameValue;
    fin_category.Bucket? categoryBucketValue;

    if (map.containsKey('categories') && map['categories'] is Map) {
      final categoryMap = map['categories'] as Map<String, dynamic>;
      categoryNameValue =
          categoryMap['name'] as String? ?? 'Р‘РµР· РєР°С‚РµРіРѕСЂС–С—';
      categoryBucketValue = categoryMap['bucket'] != null
          ? fin_category.stringToExpenseBucket(categoryMap['bucket'] as String?)
          : null;
    } else {
      categoryNameValue =
          map['categoryName'] as String? ?? 'Р‘РµР· РєР°С‚РµРіРѕСЂС–С—';
      categoryBucketValue = map[DatabaseHelper.colCategoryBucket] != null
          ? fin_category.stringToExpenseBucket(
              map[DatabaseHelper.colCategoryBucket] as String?,
            )
          : null;
    }

    return TransactionViewData(
      id: map[DatabaseHelper.colTransactionId] as int,
      type: fin_transaction.TransactionType.values.byName(
        map[DatabaseHelper.colTransactionType] as String? ?? 'expense',
      ),
      originalAmount:
          (map[DatabaseHelper.colTransactionOriginalAmount] as num? ?? 0.0)
              .toDouble(),
      originalCurrencyCode:
          map[DatabaseHelper.colTransactionOriginalCurrencyCode] as String? ??
              'UAH',
      amountInBaseCurrency:
          (map[DatabaseHelper.colTransactionAmountInBaseCurrency] as num? ??
                  0.0)
              .toDouble(),
      exchangeRateUsed:
          (map[DatabaseHelper.colTransactionExchangeRateUsed] as num?)
              ?.toDouble(),
      date: DateTime.parse(map[DatabaseHelper.colTransactionDate] as String),
      description: map[DatabaseHelper.colTransactionDescription] as String?,
      categoryId: map[DatabaseHelper.colTransactionCategoryId] as int,
      categoryName: categoryNameValue,
      linkedGoalId: map[DatabaseHelper.colTransactionLinkedGoalId] as int?,
      subscriptionId: map[DatabaseHelper.colTransactionSubscriptionId] as int?,
      categoryBucket: categoryBucketValue,
    );
  }
  final int id;
  final fin_transaction.TransactionType type;
  final double originalAmount;
  final String originalCurrencyCode;
  final double amountInBaseCurrency;
  final double? exchangeRateUsed;
  final DateTime date;
  final String? description;
  final int categoryId;
  final String categoryName;
  final int? linkedGoalId;
  final int? subscriptionId;
  final fin_category.Bucket? categoryBucket;

  fin_transaction.Transaction toTransactionModel() {
    return fin_transaction.Transaction(
      id: id,
      type: type,
      originalAmount: originalAmount,
      originalCurrencyCode: originalCurrencyCode,
      amountInBaseCurrency: amountInBaseCurrency,
      exchangeRateUsed: exchangeRateUsed,
      categoryId: categoryId,
      date: date,
      description: description,
      linkedGoalId: linkedGoalId,
      subscriptionId: subscriptionId,
    );
  }
}
