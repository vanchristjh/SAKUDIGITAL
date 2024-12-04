import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saku_digital/pages/isisaldo_detail.dart';
import 'package:saku_digital/pages/transfer_detail.dart';
import 'package:saku_digital/pages/profil_detail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isBalanceVisible = true;
  int _selectedIndex = 1;
  String _userName = 'User';
  String? _profileImage;
  double _balance = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBalance();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name')?.split(' ')[0] ?? 'User';
      _profileImage = prefs.getString('profileImage');
    });
  }

  Future<void> _loadBalance() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _balance = userDoc['balance'] ?? 0.0;
      });
    }
  }

  Future<void> _addTransaction(
      {required String type, required double amount}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('transactions').add({
        'type': type,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(user.uid).update({
        'balance': FieldValue.increment(
            type == 'Isi Saldo' ? amount : -amount),
      });
      _loadBalance();
    }
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $_userName!',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Text(
            'Welcome back',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        CircleAvatar(
          backgroundImage:
              _profileImage != null ? NetworkImage(_profileImage!) : null,
          child: _profileImage == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTransactionList();
      case 1:
        return _buildHomeContent();
      case 2:
        return const ProfilDetail();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTransactionList() {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Tidak ada transaksi.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!.docs;
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Text(transaction['type']),
              subtitle: Text(transaction['timestamp']
                  ?.toDate()
                  .toString()
                  .split('.')[0] ?? ''),
              trailing: Text(
                (transaction['type'] == 'Isi Saldo' ? '+' : '-') +
                    'Rp ${transaction['amount']}',
                style: TextStyle(
                    color: transaction['type'] == 'Isi Saldo'
                        ? Colors.green
                        : Colors.red),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 12),
          _buildPromotionBanner(),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Anda',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
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
            _isBalanceVisible ? 'Rp ${_balance.toStringAsFixed(0)}' : '• • • • •',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMainAction(Icons.add, 'Isi Saldo', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IsiSaldoDetail(onBalanceUpdated: (newBalance) {
                      _addTransaction(type: 'Isi Saldo', amount: newBalance);
                    }),
                  ),
                );
              }),
              _buildMainAction(Icons.send, 'Transfer', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransferDetail(onBalanceUpdated: (newBalance) {
                      _addTransaction(type: 'Transfer', amount: newBalance);
                    }),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Promo: Cashback 10%!',
            style: TextStyle(color: Colors.black87, fontSize: 16),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
            ),
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: onTap,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black)),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
