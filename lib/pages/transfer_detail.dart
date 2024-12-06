import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/pin_screen.dart';

class TransferDetail extends StatefulWidget {
  final Function(double) onTransfer;

  const TransferDetail({Key? key, required this.onTransfer}) : super(key: key);

  @override
  State<TransferDetail> createState() => _TransferDetailState();
}

class _TransferDetailState extends State<TransferDetail> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> processTransfer(String pin, double amount, String description) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!senderDoc.exists) throw 'Sender account not found';

    final senderBalance = (senderDoc.data()?['balance'] ?? 0.0) as double;
    if (senderBalance < amount) throw 'Insufficient balance';

    // Verify recipient exists
    final recipientSnapshot = await _firestore
        .collection('users')
        .where('accountNumber', isEqualTo: _recipientController.text)
        .limit(1)
        .get();

    if (recipientSnapshot.docs.isEmpty) throw 'Recipient account not found';
    final recipientDoc = recipientSnapshot.docs.first;

    // Start transaction
    return _firestore.runTransaction((transaction) async {
      // Update sender balance
      transaction.update(senderDoc.reference, {
        'balance': senderBalance - amount,
        'transactions': FieldValue.arrayUnion([{
          'type': 'transfer_out',
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        }])
      });

      // Update recipient balance
      transaction.update(recipientDoc.reference, {
        'balance': (recipientDoc.data()['balance'] ?? 0.0) + amount,
        'transactions': FieldValue.arrayUnion([{
          'type': 'transfer_in',
          'amount': amount,
          'description': 'Transfer from ${senderDoc.data()?['accountNumber']}',
          'timestamp': FieldValue.serverTimestamp(),
        }])
      });
    });
  }

  void _handleTransfer() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text);
      _handleTransferConfirmation(amount);
    }
  }

  void _handleTransferConfirmation(double amount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          title: 'Enter PIN to Confirm Transfer',
          onPinVerified: (pin) async {
            try {
              await processTransfer(
                pin,
                amount,
                'Transfer to ${_recipientController.text}'
              );
              
              if (!mounted) return;
              Navigator.pop(context); // Close PIN screen
              Navigator.pop(context); // Close transfer screen
              widget.onTransfer(amount); // Notify parent about the transfer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer successful')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transfer'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipient Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _recipientController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Recipient Account',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter recipient account';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        labelText: 'Enter amount',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _handleTransfer,
              child: const Text(
                'Transfer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}