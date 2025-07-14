import 'package:flutter/material.dart';

enum BillingCycle { daily, weekly, monthly, quarterly, yearly, custom }

class Subscription {
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

  Subscription({
    this.id,
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.billingCycle,
    required this.nextPaymentDate,
    required this.startDate,
    this.categoryId,
    this.paymentMethod,
    this.notes,
    this.isActive = true,
    this.website,
    this.reminderDaysBefore,
    this.updatedAt,
    this.isDeleted = false,
  });

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
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'],
      billingCycle: BillingCycle.values.byName(map['billing_cycle']),
      nextPaymentDate: DateTime.parse(map['next_payment_date']),
      startDate: DateTime.parse(map['start_date']),
      categoryId: map['category_id'],
      paymentMethod: map['payment_method'],
      notes: map['notes'],
      isActive: (map['is_active'] is bool) ? map['is_active'] : ((map['is_active'] as int? ?? 1) == 1),
      website: map['website'],
      reminderDaysBefore: map['reminder_days_before'],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      isDeleted: (map['is_deleted'] is bool) ? map['is_deleted'] : ((map['is_deleted'] as int? ?? 0) == 1),
    );
  }

  DateTime calculateNextPaymentDate(DateTime fromDate, BillingCycle cycle) {
    switch (cycle) {
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

String billingCycleToString(BillingCycle cycle, BuildContext context) {
  switch (cycle) {
    case BillingCycle.daily:
      return 'Щодня';
    case BillingCycle.weekly:
      return 'Щотижня';
    case BillingCycle.monthly:
      return 'Щомісяця';
    case BillingCycle.quarterly:
      return 'Щоквартально';
    case BillingCycle.yearly:
      return 'Щороку';
    case BillingCycle.custom:
      return 'Інше';
  }
}