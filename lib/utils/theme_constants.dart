import 'package:flutter/material.dart';

class ThemeConstants {
  static const primaryColor = Color(0xFF2196F3);
  static const secondaryColor = Color(0xFF1976D2);

  static final bottomNavBarDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, -5),
      ),
    ],
  );
}
