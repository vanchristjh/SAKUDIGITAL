import 'package:flutter/material.dart';
import '../models/voucher.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({Key? key}) : super(key: key);

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  List<String> categories = ['All', 'Food', 'Shopping', 'Travel', 'Entertainment'];
  List<Voucher> vouchers = [];
  List<Voucher> filteredVouchers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    // Simulate loading vouchers
    setState(() {
      vouchers = List.generate(
        10,
        (index) => Voucher(
          id: 'VOUCHER$index',
          category: categories[index % categories.length],
          discountPercentage: (index + 1) * 5,
          expiryDate: DateTime.now().add(Duration(days: 3 + index)),
        ),
      );
      filteredVouchers = List.from(vouchers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Vouchers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showVoucherHistory(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categories.map((category) => 
                  _buildVoucherGrid(category)
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => _filterVouchers(value),
        decoration: InputDecoration(
          hintText: 'Search vouchers...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue,
        tabs: categories.map((category) => 
          Tab(
            child: Text(
              category,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildVoucherGrid(String category) {
    final categoryVouchers = category == 'All'
        ? filteredVouchers
        : filteredVouchers.where((v) => v.category == category).toList();

    return categoryVouchers.isEmpty
        ? _buildEmptyState()
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: categoryVouchers.length,
            itemBuilder: (context, index) => _buildVoucherCard(categoryVouchers[index]),
          );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Hero(
      tag: voucher.id,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: voucher.isExpired ? null : () => _showVoucherDetails(voucher),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[700]!,
                  Colors.blue[900]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[900]!.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (voucher.isExpired || voucher.isUsed)
                  _buildOverlay(voucher),
                _buildVoucherContent(voucher),
                _buildExpiryBadge(voucher),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherContent(Voucher voucher) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(voucher.category),
              size: 24,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '${voucher.discountPercentage}% OFF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            voucher.category,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.flight;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildExpiryBadge(Voucher voucher) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Valid until: ${voucher.expiryDate.toString().split(' ')[0]}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(Voucher voucher) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          voucher.isExpired ? 'EXPIRED' : 'USED',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No vouchers found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showVoucherDetails(Voucher voucher) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherDetailsSheet(voucher: voucher),
    );
  }

  void _showVoucherHistory() {
    // Implement voucher usage history
  }

  void _filterVouchers(String query) {
    setState(() {
      filteredVouchers = vouchers.where((voucher) =>
        voucher.category.toLowerCase().contains(query.toLowerCase()) ||
        voucher.discountPercentage.toString().contains(query)
      ).toList();
    });
  }
}

class VoucherDetailsSheet extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailsSheet({Key? key, required this.voucher}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discount ${voucher.discountPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Terms and conditions apply',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Use Voucher'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Valid until: ${voucher.expiryDate.toString().split(' ')[0]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
