import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';
import 'package:saku_digital/services/firebase_service.dart';
import 'package:saku_digital/utils/error_handler.dart';
import 'package:saku_digital/widgets/loading_overlay.dart' as overlay;
import '../utils/theme_constants.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<double?> _checkUserBalance() async {
    try {
      final userBalance = await _firebaseService.getUserBalance();
      if (userBalance <= 0) {
        throw Exception('Insufficient balance. Please top up your account.');
      }
      return userBalance;
    } catch (e) {
      ErrorHandler.showError(context, ErrorHandler.getReadableError(e.toString()));
      return null;
    }
  }

  Future<void> _handleBillPayment(String billType) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final userBalance = await _checkUserBalance();
    Navigator.pop(context); // Hide loading

    if (userBalance == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => overlay.LoadingOverlay(
          child: BillPaymentPage(
            billType: billType,
            userBalance: userBalance,
          ),
        ),
      ),
    );

    if (result == true) {
      setState(() {});
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Category',
                style: ThemeConstants.textStyleHeading.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: 'Payment Category Selection',
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                        childAspectRatio: constraints.maxWidth > 600 ? 1.2 : 1.1, // Adjusted aspect ratio for larger screens
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
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
              ),
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
    return Hero(
      tag: 'bill_${label.toLowerCase()}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleBillPayment(label),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
