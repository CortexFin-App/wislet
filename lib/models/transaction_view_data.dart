import 'package:sage_wallet_reborn/models/transaction.dart' as fin_transaction;
import 'package:sage_wallet_reborn/models/category.dart' as fin_category;
import 'package:sage_wallet_reborn/utils/database_helper.dart';

class TransactionViewData {
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
  final fin_category.Bucket categoryBucket;

  TransactionViewData({
    required this.id,
    required this.type,
    required this.originalAmount,
    required this.originalCurrencyCode,
    required this.amountInBaseCurrency,
    this.exchangeRateUsed,
    required this.date,
    this.description,
    required this.categoryId,
    required this.categoryName,
    this.linkedGoalId,
    this.subscriptionId,
    required this.categoryBucket,
  });

  factory TransactionViewData.fromMap(Map<String, dynamic> map) {
    return TransactionViewData(
      id: map[DatabaseHelper.colTransactionId] as int,
      type: fin_transaction.TransactionType.values.firstWhere(
              (e) => e.toString() == map[DatabaseHelper.colTransactionType] as String),
      originalAmount: map[DatabaseHelper.colTransactionOriginalAmount] as double? ?? map['amount'] as double? ?? 0.0,
      originalCurrencyCode: map[DatabaseHelper.colTransactionOriginalCurrencyCode] as String? ?? 'UAH',
      amountInBaseCurrency: map[DatabaseHelper.colTransactionAmountInBaseCurrency] as double? ?? map['amount'] as double? ?? 0.0,
      exchangeRateUsed: map[DatabaseHelper.colTransactionExchangeRateUsed] as double?,
      date: DateTime.parse(map[DatabaseHelper.colTransactionDate] as String),
      description: map[DatabaseHelper.colTransactionDescription] as String?,
      categoryId: map[DatabaseHelper.colTransactionCategoryId] as int,
      categoryName: map['categoryName'] as String,
      linkedGoalId: map[DatabaseHelper.colTransactionLinkedGoalId] as int?,
      subscriptionId: map[DatabaseHelper.colTransactionSubscriptionId] as int?,
      categoryBucket: fin_category.stringToExpenseBucket(map[DatabaseHelper.colCategoryBucket] as String?),
    );
  }

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