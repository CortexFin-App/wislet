enum TransactionType { income, expense }

class Transaction {
  final int? id;
  final TransactionType type;
  final double originalAmount;
  final String originalCurrencyCode;
  final double amountInBaseCurrency;
  final double? exchangeRateUsed;
  final int categoryId;
  final DateTime date;
  final String? description;
  final int? linkedGoalId;
  final int? subscriptionId;
  final int? linkedTransferId;

  Transaction({
    this.id,
    required this.type,
    required this.originalAmount,
    required this.originalCurrencyCode,
    required this.amountInBaseCurrency,
    this.exchangeRateUsed,
    required this.categoryId,
    required this.date,
    this.description,
    this.linkedGoalId,
    this.subscriptionId,
    this.linkedTransferId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'originalAmount': originalAmount,
      'originalCurrencyCode': originalCurrencyCode,
      'amountInBaseCurrency': amountInBaseCurrency,
      'exchangeRateUsed': exchangeRateUsed,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'linkedGoalId': linkedGoalId,
      'subscriptionId': subscriptionId,
      'linkedTransferId': linkedTransferId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: TransactionType.values.firstWhere((e) => e.toString() == map['type']),
      originalAmount: (map['originalAmount'] as num).toDouble(),
      originalCurrencyCode: map['originalCurrencyCode'] as String,
      amountInBaseCurrency: (map['amountInBaseCurrency'] as num).toDouble(),
      exchangeRateUsed: (map['exchangeRateUsed'] as num?)?.toDouble(),
      categoryId: map['categoryId'] as int,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      linkedGoalId: map['linkedGoalId'] as int?,
      subscriptionId: map['subscriptionId'] as int?,
      linkedTransferId: map['linkedTransferId'] as int?,
    );
  }
}