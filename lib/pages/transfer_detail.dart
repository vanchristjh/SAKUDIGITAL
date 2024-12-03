import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransferDetail extends StatefulWidget {
  final Function(double newBalance) onBalanceUpdated;

  const TransferDetail({Key? key, required this.onBalanceUpdated})
      : super(key: key);

  @override
  State<TransferDetail> createState() => _TransferDetailState();
}

class _TransferDetailState extends State<TransferDetail> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientEmailController = TextEditingController();
  bool _isProcessing = false;
  String? _transferMessage;
  double _currentBalance = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  Future<void> _loadCurrentBalance() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _currentBalance = userDoc['balance'] ?? 0.0;
      });
    }
  }

  Future<void> _performTransfer() async {
    final String recipientEmail = _recipientEmailController.text.trim();
    final double? amount = double.tryParse(_amountController.text);

    if (recipientEmail.isEmpty || amount == null || amount <= 0) {
      setState(() {
        _transferMessage = "Masukkan email penerima dan jumlah transfer yang valid.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final QuerySnapshot recipientQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        setState(() {
          _isProcessing = false;
          _transferMessage = "Email penerima tidak ditemukan.";
        });
        return;
      }

      final DocumentSnapshot recipientDoc = recipientQuery.docs.first;
      final recipientId = recipientDoc.id;

      if (amount > _currentBalance) {
        setState(() {
          _isProcessing = false;
          _transferMessage = "Transfer gagal. Saldo Anda tidak mencukupi.";
        });
        return;
      }

      // Perform transfer transaction
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.runTransaction((transaction) async {
          final senderRef = _firestore.collection('users').doc(user.uid);
          final recipientRef = _firestore.collection('users').doc(recipientId);

          transaction.update(senderRef, {
            'balance': FieldValue.increment(-amount),
          });

          transaction.update(recipientRef, {
            'balance': FieldValue.increment(amount),
          });

          // Log transaction for sender
          transaction.set(
              senderRef.collection('transactions').doc(),
              {
                'type': 'Transfer Keluar',
                'amount': amount,
                'recipient': recipientEmail,
                'timestamp': FieldValue.serverTimestamp(),
              });

          // Log transaction for recipient
          transaction.set(
              recipientRef.collection('transactions').doc(),
              {
                'type': 'Transfer Masuk',
                'amount': amount,
                'sender': user.email,
                'timestamp': FieldValue.serverTimestamp(),
              });
        });

        await _loadCurrentBalance();
        widget.onBalanceUpdated(_currentBalance);

        setState(() {
          _isProcessing = false;
          _transferMessage = "Transfer berhasil ke $recipientEmail.";
        });

        _amountController.clear();
        _recipientEmailController.clear();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _transferMessage = "Terjadi kesalahan: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Uang'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Saldo Anda: Rp ${_currentBalance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _recipientEmailController,
                decoration: InputDecoration(
                  labelText: 'Email Penerima',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Transfer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _performTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text('Transfer'),
                    ),
              const SizedBox(height: 20),
              if (_transferMessage != null)
                Text(
                  _transferMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: _transferMessage!.contains("berhasil")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
