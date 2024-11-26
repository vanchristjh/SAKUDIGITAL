import 'package:flutter/material.dart';

class BankAccount {
  String accountNumber;
  String accountHolder;
  double balance;

  BankAccount({
    required this.accountNumber,
    required this.accountHolder,
    required this.balance,
  });

  bool transfer(double amount, BankAccount recipient) {
    if (amount <= 0) {
      return false;
    }
    if (amount > balance) {
      return false;
    }
    balance -= amount;
    recipient.balance += amount;
    return true;
  }
}

void main() {
  runApp(const TransferApp());
}

class TransferApp extends StatelessWidget {
  const TransferApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transfer App',
      theme: ThemeData(
        primaryColor: Colors.blueAccent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87), // Corrected here
        ),
      ),
      home: const TransferDetail(),
    );
  }
}

class TransferDetail extends StatefulWidget {
  const TransferDetail({Key? key}) : super(key: key);

  @override
  _TransferDetailState createState() => _TransferDetailState();
}

class _TransferDetailState extends State<TransferDetail> {
  final BankAccount senderAccount = BankAccount(accountNumber: "1234567890", accountHolder: "John Doe", balance: 1000000);
  final BankAccount recipientAccount = BankAccount(accountNumber: "0987654321", accountHolder: "Jane Smith", balance: 500000);
  
  final TextEditingController _amountController = TextEditingController();
  String _transferMessage = "";

  void _performTransfer() {
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _transferMessage = "Jumlah transfer tidak valid.";
      });
      return;
    }
    bool success = senderAccount.transfer(amount, recipientAccount);
    setState(() {
      if (success) {
        _transferMessage = "Transfer berhasil Rp${amount.toStringAsFixed(2)} ke ${recipientAccount.accountHolder}.";
      } else {
        _transferMessage = "Transfer gagal. Pastikan jumlah valid dan saldo mencukupi.";
      }
    });
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Uang', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                color: Colors.white.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Saldo Pengirim: Rp${senderAccount.balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Saldo Penerima: Rp${recipientAccount.balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Transfer',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _performTransfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text('Transfer', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              Text(
                _transferMessage,
                style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
