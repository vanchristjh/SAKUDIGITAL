import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilDetail extends StatefulWidget {
  const ProfilDetail({super.key});

  @override
  _ProfilDetailState createState() => _ProfilDetailState();
}

class _ProfilDetailState extends State<ProfilDetail> {
  String _name = 'Nama Pengguna';
  String _email = 'email@example.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        _name = userDoc['name'] ?? user.displayName ?? 'Nama Pengguna';
        _email = userDoc['email'] ?? user.email ?? 'email@example.com';
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    // Navigasi ke halaman login setelah logout
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _changeIcon() {
    // Tambahkan fungsi untuk mengganti ikon
    // Contoh sederhana untuk mengganti ikon di masa depan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ganti ikon akan ditambahkan!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Avatar dan Informasi Akun
              Center(
                child: Column(
                  children: [
                    // Ikon yang dapat diganti
                    IconButton(
                      iconSize: 100,
                      icon: const Icon(Icons.person, size: 100, color: Colors.blue),
                      onPressed: _changeIcon,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Logout
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
