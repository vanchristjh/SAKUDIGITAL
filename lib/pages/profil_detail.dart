import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilDetail extends StatefulWidget {
  const ProfilDetail({super.key});

  @override
  _ProfilDetailState createState() => _ProfilDetailState();
}

class _ProfilDetailState extends State<ProfilDetail> {
  String _name = 'Nama Pengguna';
  String _email = 'email@example.com';
  String? _profileImage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load profile data from Firebase and SharedPreferences
  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      // Fetching user data from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      // Storing values in SharedPreferences to persist data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _name = userDoc['name'] ?? user.displayName ?? 'Nama Pengguna';
        _email = userDoc['email'] ?? user.email ?? 'email@example.com';
        _profileImage = userDoc['profileImage'];
        prefs.setString('profileImage', _profileImage ?? '');
        prefs.setString('userName', _name);
        prefs.setString('userEmail', _email);
      });
    }
  }

  // Change the profile image
  Future<void> _changeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      File file = File(image.path);
      User? user = _auth.currentUser;

      if (user != null) {
        String fileName = 'profile_images/${user.uid}.jpg';
        TaskSnapshot uploadTask = await FirebaseStorage.instance
            .ref(fileName)
            .putFile(file);

        String imageUrl = await uploadTask.ref.getDownloadURL();

        // Update profile image in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': imageUrl,
        });

        // Save the new image URL to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('profileImage', imageUrl);

        setState(() {
          _profileImage = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengganti foto profil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profilePic',
                        child: GestureDetector(
                          onTap: _changeProfileImage,
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: _profileImage != null
                                ? NetworkImage(_profileImage!)
                                : const AssetImage('assets/logo.jpg')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          // Implement profile editing screen if needed
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat('Level', 'Gold', Icons.military_tech),
                      _buildQuickStat('Points', '2,500', Icons.stars),
                      _buildQuickStat('Vouchers', '8', Icons.card_giftcard),
                    ],
                  ),
                ],
              ),
            ),
            // Add other menu sections here
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
