import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saku_digital/pages/isisaldo_detail.dart';
import 'package:saku_digital/pages/transfer_detail.dart';
import 'package:saku_digital/pages/profil_detail.dart';
import 'theme/app_theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:saku_digital/pages/bills_page.dart';
import 'package:saku_digital/pages/investments_page.dart';
import 'package:saku_digital/pages/vouchers_page.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  double _balance = 0;
  bool _isBalanceVisible = true;
  int _currentIndex = 0;

  // Add new properties for animations
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadUserData();

    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeInOutBack,
    );
    _balanceAnimationController.forward();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      
      if (docSnapshot.exists) {
        setState(() {
          _balance = (docSnapshot.data()?['balance'] ?? 0.0).toDouble();
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to load user data: $e');
    }
  }

  Widget _buildDashboard() {
    return Container(
      color: const Color(0xFF0A0E21),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppBar(),
              _buildBalanceSection(),
              _buildQuickActions(),
              _buildPromoBanner(),
              _buildCategories(),
              _buildFavoriteContacts(),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String initial = (snapshot.data?.get('name') ?? 'U')[0];
                    return Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        snapshot.data?.get('name') ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    return AnimatedBuilder(
      animation: _balanceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_balanceAnimation.value * 0.05),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[800]!,
                        Colors.blue[900]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[900]!.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isBalanceVisible 
                                        ? Icons.visibility 
                                        : Icons.visibility_off,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() => 
                                    _isBalanceVisible = !_isBalanceVisible
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Text(
                                    _isBalanceVisible 
                                        ? 'Rp ${_balance.toStringAsFixed(0)}' 
                                        : '• • • • •',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: 'Top Up',
                                  onTap: _handleTopUp,
                                ),
                                _buildActionButton(
                                  icon: Icons.send_outlined,
                                  label: 'Transfer',
                                  onTap: _handleTransfer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickActionCard(
                  icon: Icons.receipt_long,
                  label: 'Bills',
                  onTap: _handleBills,
                  color: Colors.purple,
                ),
                _buildQuickActionCard(
                  icon: Icons.card_giftcard,
                  label: 'Vouchers',
                  onTap: () => _showVouchers(),
                  color: Colors.orange,
                ),
                _buildQuickActionCard(
                  icon: Icons.trending_up,
                  label: 'Invest',
                  onTap: () => _showInvestments(),
                  color: Colors.green,
                ),
                // Add more quick actions...
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

  Widget _buildPromoBanner() {
    final promos = [
      {'image': 'assets/promo1.jpg', 'title': 'Special Cashback 25%'},
      {'image': 'assets/promo2.jpg', 'title': 'Free Transfer Fee'},
      {'image': 'assets/promo3.jpg', 'title': 'Investment Bonus'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 150,
          autoPlay: true,
          enlargeCenterPage: true,
        ),
        items: promos.map((promo) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                promo['title']!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.flash_on, 'label': 'Electricity'},
      {'icon': Icons.water_drop, 'label': 'Water'},
      {'icon': Icons.phone_android, 'label': 'Mobile'},
      {'icon': Icons.wifi, 'label': 'Internet'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Payments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: categories.map((category) {
              return InkWell(
                onTap: () => _handleBillPayment(category['label'] as String),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['label'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteContacts() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Transfer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('favorites')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Row(
                  children: snapshot.data!.docs.map((doc) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: () => _handleQuickTransfer(doc['userId']),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white24,
                              child: Text(
                                doc['name'][0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc['name'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleBills() {
    Navigator.pushNamed(context, '/bills');
  }

  void _showVouchers() {
    Navigator.pushNamed(context, '/vouchers');
  }

  void _showInvestments() {
    Navigator.pushNamed(context, '/investments');
  }

  void _handleBillPayment(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentPage(billType: category),
      ),
    );
  }

  void _handleQuickTransfer(String userId) async {
    try {
      final recipientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!recipientDoc.exists) {
        throw Exception('Recipient not found');
      }

      final result = await Navigator.push<double>(
        context,
        MaterialPageRoute(
          builder: (context) => TransferDetail(
            onTransfer: _updateBalance,
            currentBalance: _balance,
            recipientId: userId,
            recipientName: recipientDoc.data()?['name'],
          ),
        ),
      );

      if (result != null) {
        await _updateBalance(-result);
      }
    } catch (e) {
      _showErrorSnackbar('Quick transfer failed: $e');
    }
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('transactions')
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final isTopUp = doc['type'] == 'Top Up';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isTopUp ? Colors.green : Colors.blue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isTopUp ? Icons.add : Icons.send,
                            color: isTopUp ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['type'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                DateTime.fromMillisecondsSinceEpoch(
                                  doc['timestamp'].millisecondsSinceEpoch
                                ).toString().split(' ')[0],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isTopUp ? '+' : '-'}Rp ${doc['amount']}',
                          style: TextStyle(
                            color: isTopUp ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateBalance(double amount) async {
    if (!mounted) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User data not found');
        }

        final currentBalance = (userDoc.data()?['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;

        if (amount < 0 && newBalance < 0) {
          throw Exception('Insufficient balance');
        }

        // Update balance
        transaction.update(userRef, {
          'balance': newBalance,
        });

        // Record transaction
        final transactionRef = userRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'amount': amount.abs(),
          'type': amount > 0 ? 'Top Up' : 'Transfer',
          'timestamp': FieldValue.serverTimestamp(),
          'balance_before': currentBalance,
          'balance_after': newBalance,
          'status': 'completed'
        });
      });

      // Refresh local balance after transaction
      await _loadUserData();

      _showSuccessSnackbar(
        amount > 0 
          ? 'Successfully added Rp ${amount.toStringAsFixed(0)}'
          : 'Successfully transferred Rp ${amount.abs().toStringAsFixed(0)}'
      );

    } catch (e) {
      _showErrorSnackbar(e.toString().replaceAll('Exception:', '').trim());
      rethrow;
    }
  }

  void _handleTopUp() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IsiSaldoDetail(
            onBalanceUpdated: (amount) async {
              await _updateBalance(amount);
              await _loadUserData(); // Refresh balance after top-up
              return true;
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Top up failed: ${e.toString()}');
    }
  }

  void _handleTransfer() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferDetail(
            onTransfer: (amount) async {
              if (amount > _balance) {
                throw Exception('Insufficient balance');
              }
              await _updateBalance(-amount);
              await _loadUserData(); // Refresh balance after transfer
              return amount; // Return the transfer amount
            },
            currentBalance: _balance,
            recipientId: '',
            recipientName: null,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Transfer failed: ${e.toString()}');
    }
  }

  Future<double> _getCurrentBalance(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return (doc.data()?['balance'] ?? 0.0).toDouble();
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Container(
      color: const Color(0xFF0A0E21),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Transaction History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('transactions')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No transactions yet'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final isTopUp = doc['type'] == 'Top Up';
                      final timestamp = (doc['timestamp'] as Timestamp).toDate();
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isTopUp ? Colors.green : Colors.blue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isTopUp ? Icons.add : Icons.send,
                                color: isTopUp ? Colors.green : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['type'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isTopUp ? '+' : '-'}Rp ${doc['amount']}',
                              style: TextStyle(
                                color: isTopUp ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildTransactionList(),
          const ProfileDetail(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
