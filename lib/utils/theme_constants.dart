import 'package:flutter/material.dart';

class ThemeConstants {
  static const backgroundColor = Color(0xFF0A0E21);
  static const primaryColor = Color(0xFF2196F3);
  static const secondaryColor = Color(0xFF1976D2);
  static const cardColor = Color(0xFF1D1E33);

  static final gradientPrimary = LinearGradient(
    colors: [Colors.blue[700]!, Colors.blue[900]!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
  );

  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
    labelStyle: TextStyle(color: Colors.grey[400]),
  );

  static const textStyleHeading = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const textStyleSubheading = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );

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
