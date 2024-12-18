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
    int? number = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number != null) {
      return _currencyFormat.format(number);
    }
    return value;
  }

  // Improved validation function
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null) {
      return 'Invalid amount';
    }
    
    if (amount < 10000) {
      return 'Minimum amount is Rp 10.000';
    }
    
    if (amount > 10000000) {
      return 'Maximum amount is Rp 10.000.000';
    }
    
    return null;
  }

  // Updated top up handler without fee
  Future<void> _handleTopUp() async {
    if (_selectedBank == null) {
      _showErrorMessage('Please select a bank');
      return;
    }

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(amountStr);
    
    if (amount == null) {
      _showErrorMessage('Invalid amount');
      return;
    }

    final validationError = _validateAmount(amountStr);
    if (validationError != null) {
      _showErrorMessage(validationError);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final success = await _processTopUp(amount);
      
      if (success && mounted) {
        widget.onBalanceUpdated(amount.toDouble()); // Convert to double if needed
        _showSuccessMessage('Successfully topped up ${_formatCurrency(amount.toString())}');
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updated process top up without fee
  Future<bool> _processTopUp(int amount) async {
    final totalCharge = amount; // Total to be charged is the entered amount

    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          title: 'Confirm Top Up',
          amount: totalCharge.toDouble(), // Show entered amount
          bank: _selectedBank!,
          onPinVerified: (pin) => _verifyAndProcessTransaction(pin, amount),
        ),
      ),
    ) ?? false;
  }

  // Updated transaction verification without fee
  Future<bool> _verifyAndProcessTransaction(String pin, int amount) async {
    try {
      // Process the transaction without fee
      await _firebaseService.processSecuredTransaction(
        pin: pin,
        amount: amount.toDouble(),
        fee: 0.0, // Set fee to zero
        description: 'Top Up via $_selectedBank',
        isDebit: false,
      );

      // Update balance with exact amount
      await _firebaseService.updateBalance(amount.toDouble());
      return true;
    } catch (e) {
      throw Exception('Transaction failed: ${e.toString()}');
    }
  }

  // Helper function to show error message
  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Helper function to show success message
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Top Up Balance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildAmountSection(),
              const SizedBox(height: 20),
              _buildQuickAmountGrid(),
              const SizedBox(height: 30),
              _buildPaymentMethodsSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20), // Ensure consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wallet, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Add Funds',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'How much would you like to add?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Select an amount to top up your wallet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Updated padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Amount',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            _buildAmountInput(),
            if (_amountController.text.isNotEmpty) ...[
              const SizedBox(height: 15),
              _buildTransactionSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.isNotEmpty) {
          String formatted = _formatCurrency(value).replaceAll('Rp ', '');
          _amountController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
        setState(() {});
      },
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'Rp',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        hintText: '0',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amount',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            Text(
              _formatCurrency(amount.toString()),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quickAmounts.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2, // Responsive columns
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final amount = _quickAmounts[index];
        return ElevatedButton(
          onPressed: () {
            setState(() {
              _amountController.text = _formatCurrency(amount.toString());
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _formatCurrency(amount.toString()),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _banks.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2, // Responsive columns
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 3,
          ),
          itemBuilder: (context, index) {
            final bank = _banks[index];
            final isSelected = _selectedBank == bank['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBank = bank['name'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      bank['icon'],
                      height: 30,
                      width: 30,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      bank['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isLoading ? null : _handleTopUp,
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}