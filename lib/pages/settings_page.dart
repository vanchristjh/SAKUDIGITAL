import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../translations/app_translations.dart';
import '../providers/language_provider.dart';
import '../services/language_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String getText(String key) {
    return LanguageService.getText(context, key);
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirebase();
    _loadSettings();
  }

  Future<void> _loadSettingsFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('user_settings').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            Provider.of<LanguageProvider>(context, listen: false).setLanguage(data['language'] ?? 'English');
          });
        }
      }
    } catch (e) {
      print('Error loading settings from Firebase: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      Provider.of<LanguageProvider>(context, listen: false).setLanguage(prefs.getString('language') ?? 'English');
    });
  }

  Future<void> _saveSettings(String newLanguage) async {
    try {
      await Provider.of<LanguageProvider>(context, listen: false).setLanguage(newLanguage);
      
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_settings').doc(user.uid).set({
          'language': newLanguage,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${getText('languageChanged')} $newLanguage')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(getText('settings')),
        backgroundColor: const Color(0xFF0A0E21),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
          ),
        ),
        child: ListView(
          children: [
            _buildSection(
              getText('appSettings'),
              [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.green),
                  title: Text(getText('language'),
                      style: const TextStyle(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: languageProvider.currentLanguage,
                    dropdownColor: const Color(0xFF0A0E21),
                    items: ['English', 'Indonesian']
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang,
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await _saveSettings(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            _buildSection(
              getText('privacyAndSecurity'),
              [
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.orange),
                  title: Text(getText('privacyPolicy'),
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70),
                  onTap: () => _showPrivacyPolicy(),
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(getText('termsOfService'),
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70),
                  onTap: () => _showTermsOfService(),
                ),
              ],
            ),
            _buildSection(
              getText('about'),
              [
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.green),
                  title: Text(getText('appVersion'),
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Text('1.0.0',
                      style: TextStyle(color: Colors.white70)),
                ),
                ListTile(
                  leading: const Icon(Icons.update, color: Colors.purple),
                  title: Text(getText('checkUpdates'),
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70),
                  onTap: () => _checkForUpdates(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.white24),
      ],
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E21),
        title: Text(getText('privacyPolicy'),
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(
            getText('privacyPolicyText'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getText('close'), 
                style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E21),
        title: Text(getText('termsOfService'),
            style: const TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'By using our application, you agree to these terms of service. '
            'The application is provided "as is" without any warranties. '
            'We reserve the right to modify or discontinue the service at any time.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simulate checking for updates
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading indicator
      Navigator.pop(context);

      // Show result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0A0E21),
          title: Text(getText('updateCheck'),
              style: const TextStyle(color: Colors.white)),
          content: const Text(
            'Your application is up to date!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading indicator
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0A0E21),
          title: Text(getText('updateError'), style: const TextStyle(color: Colors.white)),
          content: Text(
            'An error occurred while checking for updates: ${e.toString()}',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }
}
