import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/pin_screen.dart';
import '../services/firebase_service.dart';

class BillPaymentPage extends StatefulWidget {
  final String billType;

  const BillPaymentPage({required this.billType, Key? key}) : super(key: key);

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

  Future<bool> _validateBillAccount(String accountNumber) async {
    try {
      final response = await _firebaseService.validateBillAccount(
        billType: widget.billType,
        accountNumber: accountNumber,
      );
      return response['isValid'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getBillDetails() async {
    if (_accountController.text.isEmpty) return {};

    try {
      setState(() => _isLoading = true);
      final details = await _firebaseService.getBillDetails(
        billType: widget.billType,
        accountNumber: _accountController.text,
      );
      _amountController.text = details['amount']?.toString() ?? '';
      return details;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return {};
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onAccountNumberChanged() async {
    final accountNumber = _accountController.text;
    if (accountNumber.length < 8) {
      setState(() {
        _accountValid = false;
        _billDetails = {};
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // First validate account
      final validation = await _validateBillAccount(accountNumber);
      _accountValid = validation;

      if (_accountValid) {
        // Then get bill details
        _billDetails = await _getBillDetails();
        if (_billDetails['amount'] != null) {
          _amountController.text = _billDetails['amount'].toString();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_onAccountNumberChanged);
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
                        onPressed: () => _handlePaymentConfirmation(double.parse(_amountController.text)),
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

  Future<void> _handlePaymentConfirmation(double amount) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_accountValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid account number')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_billDetails['amount'] != null && _billDetails['amount'] != amount) {
        throw Exception('Amount does not match the bill');
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            title: 'Enter PIN to Confirm Payment',
            onPinVerified: (pin) async {
              try {
                await _firebaseService.processBillPayment(
                  billType: widget.billType,
                  accountNumber: _accountController.text,
                  amount: amount,
                  pin: pin,
                );
                
                if (!mounted) return;
                Navigator.pop(context); // Close PIN screen
                Navigator.pop(context); // Close payment screen
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Successful')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                throw e;
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
