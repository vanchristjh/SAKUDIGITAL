import 'package:flutter/material.dart';

class ThemeConstants {
  static const backgroundColor = Color(0xFF0A0E21);
  static const primaryColor = Colors.blue;
  static const cardColor = Color(0xFF1D1E33);

  static final cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white10),
  );

  static const textStyleHeading = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const textStyleSubheading = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );

  static final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
