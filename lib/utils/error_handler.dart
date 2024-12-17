import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          textColor: Colors.white,
        ),
      ),
    );
  }

  static String getReadableError(String error) {
    final errorMessages = {
      'permission-denied': 'You don\'t have permission for this action',
      'insufficient-balance': 'Insufficient balance',
      'invalid-amount': 'Please enter a valid amount',
      'network-error': 'Connection error. Please check your internet',
      'invalid-account': 'Account number is invalid',
      'user-not-found': 'User not found',
      'invalid-pin': 'Invalid PIN',
    };

    for (var entry in errorMessages.entries) {
      if (error.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }
    return error.replaceAll(RegExp(r'Exception:|Error:'), '').trim();
  }
}
