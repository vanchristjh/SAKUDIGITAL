import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Transaction History'),
      ),
      body: FutureBuilder<List<TransactionData>>(
        future: FirebaseService().getUserTransactions(
          FirebaseAuth.instance.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionCard(transaction);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionData transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white.withOpacity(0.05),
      child: ListTile(
        leading: Icon(
          transaction.type == 'debit' ? Icons.remove_circle : Icons.add_circle,
          color: transaction.type == 'debit' ? Colors.red : Colors.green,
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _formatDate(transaction.timestamp),
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          'Rp ${transaction.amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: transaction.type == 'debit' ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
