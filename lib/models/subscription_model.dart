enum BillingCycle { daily, weekly, monthly, quarterly, yearly, custom }

extension BillingCycleX on BillingCycle {
  static BillingCycle fromName(String name) =>
      BillingCycle.values.byName(name);
}

class Subscription {
  Subscription({
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.billingCycle,
    required this.nextPaymentDate,
    required this.startDate,
    this.id,
    this.categoryId,
    this.paymentMethod,
    this.notes,
    this.isActive = true,
    this.website,
    this.reminderDaysBefore = 1,
    this.updatedAt,
    this.isDeleted = false,
    this.subscriptionColor,
  });

  factory Subscription.fromMap(Map<String, dynamic> map) {
    bool _bool(dynamic v, [bool def = false]) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      return def;
    }

    return Subscription(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      billingCycle: BillingCycleX.fromName(map['billing_cycle'] as String),
      nextPaymentDate: DateTime.parse(map['next_payment_date'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      categoryId: map['category_id'] as int?,
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      isActive: _bool(map['is_active'], true),
      website: map['website'] as String?,
      reminderDaysBefore: (map['reminder_days_before'] as num?)?.toInt() ?? 1,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isDeleted: _bool(map['is_deleted'], false),
      subscriptionColor: map['subscription_color'] as int?, // ARGB int
    );
  }

  final int? id;
  final String name;
  final double amount;
  final String currencyCode;
  final BillingCycle billingCycle;
  DateTime nextPaymentDate;
  final DateTime startDate;
  final int? categoryId;
  final String? paymentMethod;
  final String? notes;
  final bool isActive;
  final String? website;
  final int? reminderDaysBefore;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int? subscriptionColor;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'currency_code': currencyCode,
      'billing_cycle': billingCycle.name,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'category_id': categoryId,
      'payment_method': paymentMethod,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'website': website,
      'reminder_days_before': reminderDaysBefore,
      'is_deleted': isDeleted ? 1 : 0,
      'subscription_color': subscriptionColor,
    };
  }

  /// Обчислити дату наступного платежу від довільної дати.
  static DateTime calculateNextPaymentDate(DateTime fromDate, BillingCycle c) {
    switch (c) {
      case BillingCycle.daily:
        return fromDate.add(const Duration(days: 1));
      case BillingCycle.weekly:
        return fromDate.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case BillingCycle.quarterly:
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case BillingCycle.yearly:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      case BillingCycle.custom:
        return fromDate.add(const Duration(days: 30));
    }
  }
}
