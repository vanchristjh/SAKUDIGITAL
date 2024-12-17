import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../screens/pin_screen.dart';
import '../services/firebase_service.dart';

class IsiSaldoDetail extends StatefulWidget {
  final Function(double) onBalanceUpdated;

  const IsiSaldoDetail({Key? key, required this.onBalanceUpdated}) : super(key: key);

  @override
  State<IsiSaldoDetail> createState() => _IsiSaldoDetailState();
}

class _IsiSaldoDetailState extends State<IsiSaldoDetail> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _amountController = TextEditingController();
  final List<double> _quickAmounts = [10000, 20000, 50000, 100000];
  String? _selectedBank;
  bool _isLoading = false;
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  final List<Map<String, dynamic>> _banks = [
    {'name': 'BCA', 'icon': 'assets/bca_logo.jpg'},
    {'name': 'Mandiri', 'icon': 'assets/mandiri_logo.jpg'},
    {'name': 'BNI', 'icon': 'assets/bni_logo.png'},
    {'name': 'BRI', 'icon': 'assets/bri_logo.png'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    double? number = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number != null) {
      return _currencyFormat.format(number);
    }
    return value;
  }

  void _handleTopUpConfirmation(double amount) async {
    setState(() => _isLoading = true);
    
    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            title: 'Confirm Top Up',
            amount: amount,
            bank: _selectedBank!,
            onPinVerified: (pin) async {
              try {
                await _firebaseService.processSecuredTransaction(
                  pin: pin,
                  amount: amount,
                  description: 'Top Up via $_selectedBank',
                  isDebit: false,
                );
                
                if (!mounted) return;
                Navigator.pop(context);
                widget.onBalanceUpdated(amount);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Successfully topped up ${_currencyFormat.format(amount)}'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(e.toString()),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Top Up Saldo'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.9),
                    AppTheme.darkTheme.scaffoldBackgroundColor,
                    AppTheme.darkTheme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Form(
                key: _formKey,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAmountSection(),
                            _buildQuickAmounts(),
                            const SizedBox(height: 32),
                            _buildBankSelection(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomButton(),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Amount',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  String formatted = _formatCurrency(value);
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                double? amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                if (amount == null || amount < 10000) {
                  return 'Minimum amount is Rp 10.000';
                }
                return null;
              },
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _quickAmounts.map((amount) => 
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _amountController.text = _formatCurrency(amount.toString()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _formatCurrency(amount.toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildBankSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        ...(_banks.map((bank) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedBank = bank['name']),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedBank == bank['name']
                          ? AppTheme.primaryColor
                          : Colors.white12,
                      width: _selectedBank == bank['name'] ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(bank['icon'], fit: BoxFit.contain),
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
                      const Spacer(),
                      if (_selectedBank == bank['name'])
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ).toList()),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: () {
            if (_selectedBank == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a bank')),
              );
              return;
            }
            if (_formKey.currentState?.validate() ?? false) {
              double? amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
              if (amount != null) {
                _handleTopUpConfirmation(amount);
              }
            }
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
    );
  }
}