import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _pin;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
    _loadPin();
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

  Future<void> _loadPin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _pin = prefs.getString('userPin');
    });
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

    // Ask for PIN before proceeding with the transfer
    String? enteredPin = await _showPinDialog();
    if (enteredPin != _pin) {
      setState(() {
        _transferMessage = "PIN yang Anda masukkan salah.";
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

        await _loadCurrentBalance(); // Refresh balance after transaction
        widget.onBalanceUpdated(_currentBalance); // Notify HomePage to update balance

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

  Future<String?> _showPinDialog() async {
    String pin = '';
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Masukkan PIN'),
          content: TextField(
            obscureText: true,
            onChanged: (value) {
              pin = value;
            },
            decoration: InputDecoration(hintText: 'Masukkan PIN Anda'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Konfirmasi'),
              onPressed: () {
                Navigator.pop(context, pin);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Uang'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Saldo Anda: Rp ${_currentBalance.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _recipientEmailController,
                decoration: InputDecoration(
                  labelText: 'Email Penerima',
                  prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
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
                  prefixIcon: Icon(Icons.money, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton(
                      onPressed: _performTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      ),
                      child: const Text(
                        'Transfer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
