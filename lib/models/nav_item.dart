import 'package:flutter/material.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final Widget screen;
}
