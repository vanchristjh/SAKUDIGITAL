import 'dart:ui';
import 'package:saku_digital/utils/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:saku_digital/pages/aktivitas_page.dart';
import 'package:saku_digital/pages/bayar_detail.dart';
import 'package:saku_digital/pages/isisaldo_detail.dart';
import 'package:saku_digital/pages/pindai_detail.dart';
import 'package:saku_digital/pages/profil_detail.dart';
import 'package:saku_digital/pages/transaction_detail.dart';
import 'package:saku_digital/pages/transfer_detail.dart';
import 'package:saku_digital/pages/messages_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isBalanceVisible = true;
  int _selectedIndex = 1;

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _refreshBalance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Balance updated!')),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessagesPage()),
    );
  }

  void _sendMessage(String messageContent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New Message: $messageContent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double appBarHeight = kToolbarHeight + statusBarHeight;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.8),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, User!',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const Text('Welcome back',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: _openMessages,
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            color: Colors.black, size: 28),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: const Text('2',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/logo.jpg'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(appBarHeight),
      bottomNavigationBar: Container(
        decoration: ThemeConstants.bottomNavBarDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.history, 'Aktivitas'),
                _buildNavItem(1, Icons.home, 'Beranda'),
                _buildNavItem(2, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: ThemeConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? ThemeConstants.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? ThemeConstants.primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double topPadding) {
    switch (_selectedIndex) {
      case 0:
        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: const AktivitasPage(),
        );
      case 1:
        return _buildHomeContent(topPadding);
      case 2:
      default:
        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: const ProfilDetail(),
        );
    }
  }

  Widget _buildHomeContent(double topPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 12), // Reduced from 16
          _buildQuickActions(),
          const SizedBox(height: 12), // Reduced from 16
          _buildPromotionBanner(),
          const SizedBox(height: 12), // Reduced from 16
          _buildRecentTransactions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo Anda',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              IconButton(
                onPressed: _toggleBalanceVisibility,
                icon: Icon(
                  _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible ? 'Rp 1.500.000' : '• • • • • •',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMainAction(Icons.add, 'Isi Saldo', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const IsisaldoDetail()));
              }),
              _buildMainAction(Icons.send, 'Kirim', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransferDetail()));
              }),
              _buildMainAction(Icons.qr_code_scanner, 'Pindai', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PindaiDetail()));
              }),
              _buildMainAction(Icons.payment, 'Bayar', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BayarDetail()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Layanan Digital',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            crossAxisSpacing: 6,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            children: [
              _buildQuickActionItem(
                  Icons.phone_android, 'Pulsa', Colors.orange),
              _buildQuickActionItem(
                  Icons.electric_bolt, 'Listrik', Colors.blue),
              _buildQuickActionItem(Icons.water_drop, 'PDAM', Colors.lightBlue),
              _buildQuickActionItem(Icons.wifi, 'Internet', Colors.green),
              _buildQuickActionItem(
                  Icons.smartphone, 'Paket Data', Colors.purple),
              _buildQuickActionItem(Icons.tv, 'TV Kabel', Colors.indigo),
              _buildQuickActionItem(Icons.credit_card, 'KK', Colors.red),
              _buildQuickActionItem(Icons.receipt_long, 'Tagihan', Colors.teal),
              _buildQuickActionItem(Icons.games, 'Games', Colors.amber),
              _buildQuickActionItem(Icons.grid_view, 'Lainnya', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPromotionBanner() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.blue[400]!,
                  Colors.blue[800]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Special Offer ${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Get 50% cashback on your first transaction!',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              double transactionAmount = 150000.0 + (index * 10000);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionDetail(
                        transactionId: index + 1,
                        transactionAmount: transactionAmount,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet,
                          color: Colors.blue.shade300),
                    ),
                    title: Text('Transaction ${index + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800)),
                    subtitle: Text('Payment for services',
                        style: TextStyle(color: Colors.grey.shade600)),
                    trailing: Text(
                      'Rp ${transactionAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
