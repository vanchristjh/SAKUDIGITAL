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
  const HomePage({Key? key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saku Digital',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _openMessages,
                  icon: const Icon(Icons.mail_outline, color: Colors.blueAccent),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Aktivitas'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const AktivitasPage();
      case 1:
        return _buildHomeContent();
      case 2:
      default:
        return const ProfilDetail();
    }
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconButton(Icons.qr_code_scanner, 'Scan', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PindaiDetail()));
                }),
                _buildIconButton(Icons.add_circle, 'Top Up', () {
                  _sendMessage('Top-up transaction successful.');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const IsisaldoDetail()));
                }),
                _buildIconButton(Icons.send, 'Transfer', () {
                  _sendMessage('Transfer transaction successful.');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TransferDetail()));
                }),
                _buildIconButton(Icons.payments, 'Pay', () {
                  _sendMessage('Payment completed successfully.');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BayarDetail()));
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildBalanceCard(),
          const SizedBox(height: 20),
          const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: 5,
              itemBuilder: (context, index) {
                double transactionAmount = 150000.0 + (index * 10000); // Varying amount for each transaction

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetail(
                          transactionId: index + 1,
                          transactionAmount: transactionAmount, // Pass amount to detail page
                        ),
                      ),
                    );
                  },
                  child: _buildTransactionCard(index, transactionAmount),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A8E8), Color(0xFF007EA7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Your Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          Row(
            children: [
              Text(
                _isBalanceVisible ? 'Rp 1,000,000' : '****',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _toggleBalanceVisibility,
                icon: Icon(
                  _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _refreshBalance,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(int index, double transactionAmount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
        ),
        title: Text('Transaction ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Payment for services'),
        trailing: Text('Rp ${transactionAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blueAccent)),
      ),
    );
  }
}
