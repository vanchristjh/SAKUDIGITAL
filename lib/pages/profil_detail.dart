import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:saku_digital/pages/pin_management.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> getUserStream() {
    return _firestore
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .snapshots();
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}

class ProfileDetail extends StatefulWidget {
  const ProfileDetail({Key? key}) : super(key: key);

  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E21),
              Colors.blue.shade900.withOpacity(0.8),
            ],
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: _userService.getUserStream(),
          builder: _buildProfileContent,
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CustomLoadingIndicator();
    }

    if (snapshot.hasError) {
      return CustomErrorWidget(error: snapshot.error.toString());
    }

    if (!snapshot.hasData || !snapshot.data!.exists) {
      return const CustomEmptyState();
    }

    final userData = snapshot.data!.data() as Map<String, dynamic>;
    
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(userData),
          SliverFadeTransition(
            opacity: _controller,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeSection(userData),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildAccountOverview(userData),
                  const SizedBox(height: 24),
                  _buildSecuritySection(),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> userData) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          userData['name'] ?? 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'profile_image',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      (userData['name'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_image',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                (userData['name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                Text(
                  userData['name'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildActionTile(
          icon: Icons.receipt_long,
          title: 'Transactions',
          onTap: () => Navigator.pushNamed(context, '/transactions'),
        ),
        _buildActionTile(
          icon: Icons.card_giftcard,
          title: 'Rewards',
          onTap: () => Navigator.pushNamed(context, '/rewards'),
        ),
        _buildActionTile(
          icon: Icons.support_agent,
          title: 'Support',
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        _buildActionTile(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 28,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOverview(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildOverviewTile(
            title: 'Balance',
            value: 'Rp ${userData['balance']?.toString() ?? '0'}',
            icon: Icons.account_balance_wallet,
          ),
          if (userData['rewards'] != null) ...[
            const SizedBox(height: 16),
            _buildOverviewTile(
              title: 'Reward Points',
              value: userData['rewards'].toString(),
              icon: Icons.stars,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildActionButton(
            'PIN Management',
            Icons.lock_outline,
            () => _navigateToPinManagement(context),
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildActionButton(
            'Biometric Security',
            Icons.fingerprint,
            () => _toggleBiometric(context),
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildActionButton(
            'Logout',
            Icons.logout,
            () => _handleLogout(context),
            color: Colors.red[400],
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.blue[400], size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap,
      {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color ?? Colors.white70),
              const SizedBox(width: 16),
              Text(title,
                  style: TextStyle(color: color ?? Colors.white70, fontSize: 16)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation Methods

  Future<void> _navigateToPinManagement(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PinManagementPage()),
      );
    } catch (e) {
      _showError(context, 'Failed to open PIN management: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Confirm Logout',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout',
                style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _userService.logout(context);
      } catch (e) {
        if (mounted) _showError(context, e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _toggleBiometric(BuildContext context) async {
    // Implement biometric toggle logic
  }

  Widget _buildOverviewTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Widgets
class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final String error;
  const CustomErrorWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class CustomEmptyState extends StatelessWidget {
  const CustomEmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No profile data available',
          style: TextStyle(color: Colors.white70)),
    );
  }
}

class SliverFadeTransition extends SingleChildRenderObjectWidget {
  final Animation<double> opacity;

  const SliverFadeTransition({
    Key? key,
    required this.opacity,
    required Widget sliver,
  }) : super(key: key, child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSliverFadeTransition(opacity: opacity);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSliverFadeTransition renderObject) {
    renderObject.opacity = opacity;
  }
}

class RenderSliverFadeTransition extends RenderProxySliver {
  RenderSliverFadeTransition({
    required Animation<double> opacity,
    RenderSliver? sliver,
  }) : _opacity = opacity,
       super(sliver);

  Animation<double> _opacity;

  set opacity(Animation<double> value) {
    if (_opacity == value) return;
    if (attached) _opacity.removeListener(markNeedsPaint);
    _opacity = value;
    if (attached) _opacity.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _opacity.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _opacity.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.canvas.saveLayer(
        paintBounds.shift(offset),
        Paint()..color = Color.fromRGBO(255, 255, 255, _opacity.value),
      );
      context.paintChild(child!, offset);
      context.canvas.restore();
    }
  }
}