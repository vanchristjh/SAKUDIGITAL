import 'package:flutter/material.dart';

class Voucher {
  final String id;
  final String category;
  final int discountPercentage;
  final DateTime expiryDate;
  final bool isUsed;
  final String terms;

  Voucher({
    required this.id,
    required this.category,
    required this.discountPercentage,
    required this.expiryDate,
    this.isUsed = false,
    this.terms = 'Terms and conditions apply',
  });

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;
  
  bool get isExpired => DateTime.now().isAfter(expiryDate);
}
