import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static String getReadableError(String error) {
    if (error.contains('Insufficient balance')) {
      return 'Your balance is not enough for this transaction';
    }
    if (error.contains('Invalid account')) {
      return 'Please check the account number';
    }
    if (error.contains('User not authenticated')) {
      return 'Please login again';
    }
    return 'An error occurred. Please try again.';
  }
}
