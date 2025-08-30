import 'package:flutter/material.dart';

@immutable
class ThemeProfile {
  const ThemeProfile({
    required this.name,
    required this.seedColor,
    this.fontFamily = 'NotoSans',
    this.borderRadius = 12.0,
  });

  factory ThemeProfile.fromMap(Map<String, dynamic> map) {
    return ThemeProfile(
      name: map['name'] as String,
      seedColor: Color(map['seedColor'] as int),
      fontFamily: map['fontFamily'] as String,
      borderRadius: map['borderRadius'] as double,
    );
  }
  final String name;
  final Color seedColor;
  final String fontFamily;
  final double borderRadius;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'seedColor': seedColor.value,
      'fontFamily': fontFamily,
      'borderRadius': borderRadius,
    };
  }
}
