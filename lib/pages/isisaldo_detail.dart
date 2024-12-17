import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/pin_screen.dart';
import '../services/firebase_service.dart';

class IsiSaldoDetail extends StatefulWidget {
  final Function(double) onBalanceUpdated;

  const IsiSaldoDetail({Key? key, required this.onBalanceUpdated}) : super(key: key);

  @override
  State<IsiSaldoDetail> createState() => _IsiSaldoDetailState();
}

class _IsiSaldoDetailState extends State<IsiSaldoDetail> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _amountController = TextEditingController();
  final List<double> _quickAmounts = [10000, 20000, 50000, 100000];
  String? _selectedBank;
  
  final List<Map<String, dynamic>> _banks = [
    {'name': 'BCA', 'icon': 'assets/bca_logo.jpg'},
    {'name': 'Mandiri', 'icon': 'assets/mandiri_logo.jpg'},
    {'name': 'BNI', 'icon': 'assets/bni_logo.png'},
    {'name': 'BRI', 'icon': 'assets/bri_logo.png'},
  ];

  void _handleTopUpConfirmation(double amount) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          title: 'Enter PIN to Confirm Top Up',
          onPinVerified: (pin) async {
            try {
              await _firebaseService.processSecuredTransaction(
                pin: pin,
                amount: amount,
                description: 'Top Up via $_selectedBank',
                isDebit: false, // false for credit/top-up
              );
              
              if (!mounted) return;
              Navigator.pop(context); // Close PIN screen
              widget.onBalanceUpdated(amount); // Call the callback to update parent
              Navigator.pop(context); // Close top up screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Top up successful')),
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
          title: const Text('Top Up'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withOpacity(0.8),
                AppTheme.darkTheme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: kToolbarHeight + 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Amount',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _quickAmounts.map((amount) => 
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardColor.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              onPressed: () => _amountController.text = amount.toString(),
                              child: Text(
                                'Rp ${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._banks.map((bank) => 
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedBank == bank['name'] 
                                ? AppTheme.primaryColor 
                                : Colors.white.withOpacity(0.1),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: RadioListTile<String>(
                            value: bank['name'],
                            groupValue: _selectedBank,
                            onChanged: (value) => setState(() => _selectedBank = value),
                            title: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    bank['icon'],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  bank['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              onPressed: () {
                if (_selectedBank == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a bank')),
                  );
                  return;
                }
                double? amount = double.tryParse(_amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                if (amount < 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Minimum amount is Rp 10.000')),
                  );
                  return;
                }
                _handleTopUpConfirmation(amount);
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}