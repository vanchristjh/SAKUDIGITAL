import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late BuildContext _context;
  final List<Particle> particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),  // Increased duration
    )..repeat();

    Future.delayed(const Duration(seconds: 4), () {  // Increased delay
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _context = context;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Animated particles
          ...particles.map((particle) => AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => particle.build(_controller.value),
              )),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container with glassmorphism
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                // App name with modern typography
                const Text(
                  'SakuDigital',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Digital Wallet Solution',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1,
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

class Particle {
  final double initialX = math.Random().nextDouble() * 400 - 200;
  final double initialY = math.Random().nextDouble() * 400 - 200;
  final double speed = math.Random().nextDouble() * 2 + 1;
  final double size = math.Random().nextDouble() * 4 + 2;

  Widget build(double progress) {
    return Builder(
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return Positioned(
          left: size.width / 2 + initialX + math.cos(progress * 2 * math.pi) * 30 * speed,
          top: size.height / 2 + initialY + math.sin(progress * 2 * math.pi) * 30 * speed,
          child: Container(
            width: this.size,
            height: this.size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
