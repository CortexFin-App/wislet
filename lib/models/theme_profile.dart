import 'package:flutter/material.dart';

class ThemeProfile {
  final String name;
  final Color seedColor;
  final String fontFamily;
  final double borderRadius;

  const ThemeProfile({
    required this.name,
    required this.seedColor,
    this.fontFamily = 'NotoSans',
    this.borderRadius = 12.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'seedColor': seedColor.value,
      'fontFamily': fontFamily,
      'borderRadius': borderRadius,
    };
  }

  factory ThemeProfile.fromMap(Map<String, dynamic> map) {
    return ThemeProfile(
      name: map['name'],
      seedColor: Color(map['seedColor']),
      fontFamily: map['fontFamily'],
      borderRadius: map['borderRadius'],
    );
  }
}