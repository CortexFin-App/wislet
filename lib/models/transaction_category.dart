import 'package:flutter/material.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}
