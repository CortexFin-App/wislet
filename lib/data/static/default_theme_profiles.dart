import 'package:flutter/material.dart';
import 'package:wislet/models/theme_profile.dart';

final List<ThemeProfile> defaultThemeProfiles = [
  const ThemeProfile(
    name: 'Класичний Синій',
    seedColor: Color(0xFF0077B6),
  ),
  const ThemeProfile(
    name: 'Лісова Свіжість',
    seedColor: Color(0xFF2d6a4f),
    borderRadius: 8,
  ),
  const ThemeProfile(
    name: 'Захід Сонця',
    seedColor: Color(0xFFf77f00),
  ),
  const ThemeProfile(
    name: 'Строгий Графіт',
    seedColor: Color(0xFF525252),
    borderRadius: 4,
  ),
  const ThemeProfile(
    name: 'Королівський Аметист',
    seedColor: Color(0xFF6a0dad),
  ),
];
