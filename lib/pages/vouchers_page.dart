import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/voucher.dart';
import '../services/voucher_service.dart';
import 'voucher_details_sheet.dart';
import 'voucher_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VouchersPage extends StatefulWidget {
  const VouchersPage({Key? key}) : super(key: key);

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late VoucherService _voucherService;
  List<String> categories = ['All', 'Food', 'Shopping', 'Travel', 'Entertainment'];
  List<Voucher> vouchers = [];
  List<Voucher> filteredVouchers = [];

  final Map<String, String> categoryBackgroundUrls = {
    'Food': 'https://source.unsplash.com/random/800x600/?food',
    'Shopping': 'https://source.unsplash.com/random/800x600/?shopping',
    'Travel': 'https://source.unsplash.com/random/800x600/?travel',
    'Entertainment': 'https://source.unsplash.com/random/800x600/?entertainment',
  };

  @override
  void initState() {
    super.initState();
    _initVoucherService();
    _tabController = TabController(length: categories.length, vsync: this);
  }

  Future<void> _initVoucherService() async {
    final prefs = await SharedPreferences.getInstance();
    _voucherService = VoucherService(prefs);
    await _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final loadedVouchers = await _voucherService.getVouchers();
    if (loadedVouchers.isEmpty) {
      await _voucherService.generateInitialVouchers();
      final initialVouchers = await _voucherService.getVouchers();
      setState(() {
        vouchers = initialVouchers;
        filteredVouchers = List.from(vouchers);
      });
    } else {
      setState(() {
        vouchers = loadedVouchers;
        filteredVouchers = List.from(vouchers);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              _buildSearchBar(),
              _buildCategoryTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: categories.map((category) => 
                    AnimationConfiguration.staggeredGrid(
                      position: 0,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _buildVoucherGrid(category),
                        ),
                      ),
                    )
                  ).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'My Vouchers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find the best deals for you',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              _buildHistoryButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: () => _showVoucherHistory(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(
          Icons.history,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => _filterVouchers(value),
        decoration: InputDecoration(
          hintText: 'Search vouchers...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: Colors.purple[200],
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: categories.map((category) => 
          Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.2),
                    Colors.blue.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(child: Text(category)),
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
        : AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: categoryVouchers.length,
              itemBuilder: (context, index) {
                final voucher = categoryVouchers[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildVoucherCard(voucher),
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Hero(
      tag: voucher.id,
      child: GestureDetector(
        onTap: voucher.isExpired ? null : () => _showVoucherDetails(voucher),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.2),
                Colors.blue.withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    categoryBackgroundUrls[voucher.category] ?? 
                    'https://source.unsplash.com/random/800x600/?discount',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: _getCategoryColor(voucher.category),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.white, Colors.white70],
                              ).createShader(bounds),
                              child: Icon(
                                _getCategoryIcon(voucher.category),
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: _getCategoryColor(voucher.category),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (voucher.isExpired || voucher.isUsed)
                  _buildOverlay(voucher),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDiscountBadge(voucher),
                      const Spacer(),
                      _buildVoucherInfo(voucher),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange[700]!;
      case 'shopping':
        return Colors.purple[700]!;
      case 'travel':
        return Colors.blue[700]!;
      case 'entertainment':
        return Colors.red[700]!;
      default:
        return Colors.blue[900]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_menu;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.flight_takeoff;
      case 'entertainment':
        return Icons.theaters_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  Widget _buildDiscountBadge(Voucher voucher) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${voucher.discountPercentage}% OFF',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVoucherInfo(Voucher voucher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          voucher.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Valid until: ${voucher.expiryDate.toString().split(' ')[0]}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[600]!],
              ).createShader(bounds),
              child: const Icon(
                Icons.card_giftcard,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherDetailsSheet(
        voucher: voucher,
        onUseVoucher: (voucher) async {
          await _voucherService.useVoucher(voucher.id);
          await _loadVouchers(); // Reload vouchers after using one
        },
      ),
    );
  }

  void _showVoucherHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoucherHistoryPage(
          usedVouchers: _voucherService.getUsedVouchers(vouchers),
        ),
      ),
    );
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

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (var i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
