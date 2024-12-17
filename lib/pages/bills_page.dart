import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';
import 'package:saku_digital/services/firebase_service.dart';
import 'package:saku_digital/utils/error_handler.dart';
import 'package:saku_digital/widgets/common_widgets.dart';
import 'package:saku_digital/widgets/loading_overlay.dart' as overlay;
import '../utils/theme_constants.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  
  Stream<QuerySnapshot> getRecentPayments() {
    try {
      return _firebaseService.getTransactionHistory().map((snapshot) {
        final billPayments = snapshot.docs.where(
          (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == 'bill_payment';
          },
        ).take(5).toList();
        
        return snapshot;
      });
    } catch (e) {
      print('Payment history error: $e');
      return Stream.error(ErrorHandler.getReadableError(e.toString()));
    }
  }

  void validatePaymentData(Map<String, dynamic> data, String docId) {
    if (!data.containsKey('amount')) {
      throw 'Missing amount field';
    }
    if (!data.containsKey('timestamp')) {
      throw 'Missing timestamp field';
    }
    if (!data.containsKey('status')) {
      throw 'Missing status field';
    }
    if (data['amount'] is! num) {
      throw 'Invalid amount format';
    }
    if (data['timestamp'] is! Timestamp) {
      throw 'Invalid timestamp format';
    }
    if (data['status'] is! String) {
      throw 'Invalid status format';
    }
  }

  Future<void> _handleBillPayment(String billType) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => overlay.LoadingOverlay(
            child: BillPaymentPage(billType: billType),
          ),
        ),
      );

      if (result == true) {
        setState(() {}); // Refresh the page
      }
    } catch (e) {
      ErrorHandler.showError(context, ErrorHandler.getReadableError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> billCategories = [
      {'icon': Icons.flash_on, 'label': 'Electricity', 'color': Colors.yellow},
      {'icon': Icons.water_drop, 'label': 'Water', 'color': Colors.blue},
      {'icon': Icons.phone_android, 'label': 'Phone', 'color': Colors.green},
      {'icon': Icons.wifi, 'label': 'Internet', 'color': Colors.orange},
      {'icon': Icons.credit_card, 'label': 'Credit Card', 'color': Colors.purple},
      {'icon': Icons.home, 'label': 'Mortgage', 'color': Colors.red},
    ];

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bills & Payments'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Category',
                style: ThemeConstants.textStyleHeading,
                semanticsLabel: 'Payment Category Selection',
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 600 ? 4 : 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: billCategories.length,
                    itemBuilder: (context, index) {
                      final category = billCategories[index];
                      return _buildCategoryCard(
                        context: context,
                        icon: category['icon'] as IconData,
                        label: category['label'] as String,
                        color: category['color'] as Color,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Recent Payments', style: ThemeConstants.textStyleHeading),
              const SizedBox(height: 16),
              _buildRecentPayments(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _handleBillPayment(label),
      child: Container(
        decoration: ThemeConstants.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeConstants.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No recent payments',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bill payment history will appear here',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayments() {
    return StreamBuilder<QuerySnapshot>(
      stream: getRecentPayments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final payments = snapshot.data?.docs ?? [];
        if (payments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) => _buildListItem(payments[index]),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ThemeConstants.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text(
            'Unable to load payments',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(DocumentSnapshot doc) {
    try {
      final payment = doc.data() as Map<String, dynamic>?;
      if (payment == null) throw 'Invalid payment data';

      // Safely extract and validate data
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
      final timestamp = payment['timestamp'] as Timestamp?;
      final status = payment['status'] as String? ?? 'pending';
      final description = payment['description'] as String? ?? 'Bill Payment';
      final category = payment['category'] as String? ?? '';
      final accountNumber = payment['accountNumber'] as String?;

      if (amount < 0) throw 'Invalid amount';
      if (timestamp == null) throw 'Missing timestamp';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: ThemeConstants.cardDecoration.copyWith(
          border: status == 'completed'
              ? null
              : Border.all(color: _getStatusColor(status)),
        ),
        child: ListTile(
          leading: _getBillIcon(category),
          title: Text(
            description,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(timestamp),
                style: TextStyle(color: Colors.grey[400]),
              ),
              if (status != 'completed')
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: _buildTrailingWidget(amount, accountNumber),
          isThreeLine: status != 'completed',
        ),
      );
    } catch (e) {
      print('Error building list item: $e');
      return _buildErrorListItem();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'failed':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTrailingWidget(double amount, String? accountNumber) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rp ${NumberFormat('#,##0').format(amount)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (accountNumber != null)
          Text(
            accountNumber,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ThemeConstants.cardDecoration,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 24),
          const SizedBox(width: 12),
          const Text(
            'Error displaying payment',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _getBillIcon(String category) {
    final Map<String, Map<String, dynamic>> categoryIcons = {
      'electricity': {'icon': Icons.flash_on, 'color': Colors.yellow},
      'water': {'icon': Icons.water_drop, 'color': Colors.blue},
      'phone': {'icon': Icons.phone_android, 'color': Colors.green},
      'internet': {'icon': Icons.wifi, 'color': Colors.orange},
      'credit_card': {'icon': Icons.credit_card, 'color': Colors.purple},
      'mortgage': {'icon': Icons.home, 'color': Colors.red},
    };

    final categoryData = categoryIcons[category.toLowerCase()] ?? {
      'icon': Icons.receipt,
      'color': Colors.grey,
    };

    return CircleAvatar(
      backgroundColor: (categoryData['color'] as Color).withOpacity(0.1),
      child: Icon(categoryData['icon'] as IconData, color: categoryData['color'] as Color),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }
}
