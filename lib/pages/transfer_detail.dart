import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../screens/pin_screen.dart';

class TransferDetail extends StatefulWidget {
  final Function(double) onTransfer;

  const TransferDetail({Key? key, required this.onTransfer, required double currentBalance, required String recipientId, required recipientName}) : super(key: key);

  @override
  State<TransferDetail> createState() => _TransferDetailState();
}

class _TransferDetailState extends State<TransferDetail> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _recipientName;

  // Format currency
  final _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmount);
  }

  void _formatAmount() {
    String text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isNotEmpty) {
      double value = double.parse(text);
      String formatted = _currencyFormat.format(value);
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _searchRecipient(String email) async {
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) return;
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'User not authenticated';

      final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final senderEmail = senderDoc.data()?['email'] as String? ?? '';

      final recipientSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (recipientSnapshot.docs.isNotEmpty) {
        final recipientData = recipientSnapshot.docs.first.data();
        if (recipientData['email'] == senderEmail) {
          setState(() {
            _recipientName = null;
          });
          // Optionally, show a message that users cannot transfer to themselves
        } else {
          setState(() {
            _recipientName = recipientData['name'];
          });
        }
      } else {
        setState(() {
          _recipientName = null;
        });
      }
    } catch (e) {
      setState(() {
        _recipientName = null;
      });
    }
  }

  Future<void> processTransfer(String pin, double amount, String description) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final senderEmail = senderDoc.data()?['email'] as String? ?? '';

    final recipientDocs = await _firestore
        .collection('users')
        .where('email', isEqualTo: _recipientController.text)
        .limit(1)
        .get();

    if (!senderDoc.exists) throw 'Sender account not found';
    if (recipientDocs.docs.isEmpty) throw 'Recipient account not found';

    final recipientDoc = recipientDocs.docs.first;
    final recipientEmail = recipientDoc.data()['email'] as String? ?? '';

    if (recipientEmail == senderEmail) {
      throw 'Cannot transfer to your own email';
    }

    final senderBalance = (senderDoc.data()?['balance'] ?? 0.0) as double;
    
    if (senderBalance < amount) throw 'Insufficient balance';

    // Start transaction
    return _firestore.runTransaction((transaction) async {
      // Update sender's balance and add transaction record
      transaction.update(senderDoc.reference, {
        'balance': senderBalance - amount,
      });

      transaction.set(
        senderDoc.reference.collection('transactions').doc(),
        {
          'type': 'transfer_out',
          'amount': amount,
          'description': description,
          'recipient': recipientDoc.id,
          'timestamp': FieldValue.serverTimestamp(),
          'balance_before': senderBalance,
          'balance_after': senderBalance - amount,
        }
      );

      // Update recipient's balance and add transaction record
      final recipientBalance = (recipientDoc.data()['balance'] ?? 0.0) as double;
      transaction.update(recipientDoc.reference, {
        'balance': recipientBalance + amount,
      });

      transaction.set(
        recipientDoc.reference.collection('transactions').doc(),
        {
          'type': 'transfer_in',
          'amount': amount,
          'description': 'Transfer from ${senderEmail}',
          'sender': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'balance_before': recipientBalance,
          'balance_after': recipientBalance + amount,
        }
      );
    });
  }

  void _handleTransfer() async {
    if (_formKey.currentState?.validate() ?? false) {
      final amountString = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.parse(amountString);
      _handleTransferConfirmation(amount);
    }
  }

  void _handleTransferConfirmation(double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          amount: amount,
          bank: 'Internal Transfer',
          title: 'Enter PIN to Confirm Transfer',
          onPinVerified: (pin) async {
            try {
              setState(() {
                _isLoading = true;
              });
              await processTransfer(
                pin,
                amount,
                _descriptionController.text.isEmpty
                    ? 'Transfer to ${_recipientController.text}'
                    : _descriptionController.text,
              );
              
              if (!mounted) return;
              Navigator.pop(context); // Close PIN screen
              widget.onTransfer(amount); // Notify parent about the transfer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer successful')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      ),
    );
  }

  String? _validateRecipient(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter recipient email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    if (_recipientName == null) {
      return 'Invalid or same email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transfer Details'),
          elevation: 0,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient Email Card
                      Card(
                        color: AppTheme.cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recipient Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _recipientController,
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: 'Enter recipient email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: _recipientName != null
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : null,
                                ),
                                onChanged: _searchRecipient,
                                validator: _validateRecipient,
                              ),
                              if (_recipientName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _recipientName!,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount Card
                      Card(
                        color: AppTheme.cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Please enter amount';
                                  }
                                  final amount = double.tryParse(
                                    value!.replaceAll(RegExp(r'[^0-9]'), '')
                                  );
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description Card
                      Card(
                        color: AppTheme.cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description (Optional)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Enter transfer description',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                            ],
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleTransfer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isLoading ? 'Processing...' : 'Continue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}