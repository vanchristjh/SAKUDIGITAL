import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:saku_digital/utils/error_handler.dart';
import '../screens/pin_screen.dart';
import '../services/firebase_service.dart';

class BillPaymentPage extends StatefulWidget {
  final String billType;
  final double userBalance;

  const BillPaymentPage({
    required this.billType,
    required this.userBalance,
    Key? key
  }) : super(key: key);

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  Map<String, dynamic> _billDetails = {};
  bool _accountValid = false;
  final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  void _onAccountNumberChanged() {
    // Simplify to just update UI
    setState(() {
      _accountValid = _accountController.text.length >= 8;
    });
  }

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_onAccountNumberChanged);
  }

  Future<bool> _validatePaymentDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ErrorHandler.showError(context, 'Please enter a valid amount');
      return false;
    }

    if (amount > widget.userBalance) {
      ErrorHandler.showError(context, 'Insufficient balance');
      return false;
    }

    if (_accountController.text.length < 8) {
      ErrorHandler.showError(context, 'Account number must be at least 8 digits');
      return false;
    }

    return true;
  }

  Future<void> _validateAndProcessPayment() async {
    if (!await _validatePaymentDetails()) return;
    
    try {
      setState(() => _isLoading = true);
      final amount = double.parse(_amountController.text);
      await _handlePaymentProcess(amount);
    } catch (e) {
      ErrorHandler.showError(context, ErrorHandler.getReadableError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePaymentProcess(double amount) async {
    if (!mounted) return;

    try {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            title: 'Confirm Payment',
            amount: amount,
            bank: widget.billType,
            onPinVerified: (pin) => _processPayment(amount, pin),
          ),
        ),
      );

      if (success == true && mounted) {
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      ErrorHandler.showError(context, ErrorHandler.getReadableError(e.toString()));
    }
  }

  Future<bool> _processPayment(double amount, String pin) async {
    try {
      setState(() => _isLoading = true);
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Reference to user document
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Run transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User data not found');
        }

        final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance - amount;

        if (newBalance < 0) {
          throw Exception('Insufficient balance');
        }

        // Update user balance
        transaction.update(userRef, {'balance': newBalance});

        // Record transaction
        final transactionRef = userRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'type': 'Bill Payment',
          'billType': widget.billType,
          'accountNumber': _accountController.text,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
          'balance_before': currentBalance,
          'balance_after': newBalance,
        });
      });

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Payment successful',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
      }
      
      return true;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getReadableError(e.toString()));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text('${widget.billType} Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Balance: ${_currencyFormatter.format(widget.userBalance)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enter Payment Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _accountController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '${widget.billType} Account Number',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter account number';
                              }
                              if (value!.length < 8) {
                                return 'Account number must be at least 8 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _amountController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              prefixText: 'Rp ',
                              prefixStyle: const TextStyle(color: Colors.white),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter amount';
                              }
                              final amount = double.tryParse(value!);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _validateAndProcessPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
