
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionData transaction;

  const TransactionDetailPage({Key? key, required this.transaction}) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    String transactionType;
    Color typeColor;

    if (transaction.type == 'transfer_in') {
      transactionType = 'Incoming';
      typeColor = Colors.green;
    } else if (transaction.type == 'transfer_out') {
      transactionType = 'Outgoing';
      typeColor = Colors.red;
    } else {
      transactionType = 'Unknown';
      typeColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFF0A0E21),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    transaction.type == 'transfer_in' ? Icons.add_circle : Icons.remove_circle,
                    color: typeColor,
                    size: 40,
                  ),
                  title: Text(
                    transactionType,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${transaction.description}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const Divider(color: Colors.white54),
                _buildDetailRow('Amount', 'Rp ${transaction.amount.toStringAsFixed(0)}', typeColor),
                const SizedBox(height: 8),
                _buildDetailRow('Date', _formatDate(transaction.timestamp), Colors.white),
                const SizedBox(height: 8),
                _buildDetailRow('Balance Before', 'Rp ${transaction.balance_before.toStringAsFixed(0)}', Colors.white),
                const SizedBox(height: 8),
                _buildDetailRow('Balance After', 'Rp ${transaction.balance_after.toStringAsFixed(0)}', Colors.white),
                // Add more details if necessary
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}