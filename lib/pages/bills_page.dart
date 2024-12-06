import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/theme_constants.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  Stream<QuerySnapshot> getRecentPayments() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    // Using a single field index for better performance
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'bill_payment')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  void _navigateToBillPayment(String billType) {
    Navigator.pushNamed(
      context,
      '/bill-payment',
      arguments: billType,
    ).then((_) {
      // Refresh the page when coming back from payment
      setState(() {});
    });
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
      onTap: () => _navigateToBillPayment(label),
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
          return Center(
            child: Text(
              'Error loading payments: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final payments = snapshot.data?.docs ?? [];
        if (payments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: ThemeConstants.cardDecoration.copyWith(
                border: payment['status'] == 'completed'
                    ? null
                    : Border.all(color: Colors.orange),
              ),
              child: ListTile(
                leading: _getBillIcon(payment['category'] as String? ?? ''),
                title: Text(
                  payment['description'] as String? ?? 'Bill Payment',
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(payment['timestamp'] as Timestamp),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (payment['status'] != 'completed')
                      Text(
                        payment['status']?.toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          color: payment['status'] == 'failed' 
                              ? Colors.red 
                              : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${NumberFormat('#,##0').format(payment['amount'])}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (payment['accountNumber'] != null)
                      Text(
                        payment['accountNumber'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                isThreeLine: payment['status'] != 'completed',
              ),
            );
          },
        );
      },
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
