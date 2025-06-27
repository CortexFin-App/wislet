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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currencyCode': currencyCode,
      'billingCycle': billingCycle.toString(),
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'categoryId': categoryId,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'isActive': isActive ? 1 : 0,
      'website': website,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currencyCode'],
      billingCycle: BillingCycle.values.firstWhere((e) => e.toString() == map['billingCycle']),
      nextPaymentDate: DateTime.parse(map['nextPaymentDate']),
      startDate: DateTime.parse(map['startDate']),
      categoryId: map['categoryId'],
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
      isActive: map['isActive'] == 1,
      website: map['website'],
      reminderDaysBefore: map['reminderDaysBefore'],
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