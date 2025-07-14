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
      if (id != null) 'id': id,
      'type': type.name,
      'original_amount': originalAmount,
      'original_currency_code': originalCurrencyCode,
      'amount_in_base_currency': amountInBaseCurrency,
      'exchange_rate_used': exchangeRateUsed,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'linked_goal_id': linkedGoalId,
      'subscription_id': subscriptionId,
      'linked_transfer_id': linkedTransferId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: TransactionType.values.byName(map['type']),
      originalAmount: (map['original_amount'] as num).toDouble(),
      originalCurrencyCode: map['original_currency_code'] as String,
      amountInBaseCurrency: (map['amount_in_base_currency'] as num).toDouble(),
      exchangeRateUsed: (map['exchange_rate_used'] as num?)?.toDouble(),
      categoryId: map['category_id'] as int,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      linkedGoalId: map['linked_goal_id'] as int?,
      subscriptionId: map['subscription_id'] as int?,
      linkedTransferId: map['linked_transfer_id'] as int?,
    );
  }
}