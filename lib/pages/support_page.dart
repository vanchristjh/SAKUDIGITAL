import 'package:flutter/material.dart';
import 'package:saku_digital/main.dart';
import 'package:url_launcher/url_launcher.dart';
// Add this import if you have a profile model
import '../models/profile_model.dart';

class SupportPage extends StatelessWidget {
  final Profile? userProfile; // Add profile parameter

  const SupportPage({Key? key, this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
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
          padding: const EdgeInsets.all(16),
          children: [
            // Add profile summary card
            if (userProfile != null)
              _buildProfileCard(context, userProfile!),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              title: 'Customer Service',
              description: 'Contact our 24/7 customer service',
              icon: Icons.headset_mic,
              onTap: () => _launchPhoneCall(context, '1500123'),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              title: 'Email Support',
              description: 'Send us an email',
              icon: Icons.email,
              onTap: () => _launchEmail(context, 'support@sakudigital.com'),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              title: 'FAQ',
              description: 'Frequently asked questions',
              icon: Icons.help,
              onTap: () => _showFAQ(context),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Profile profile) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            profile.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          profile.email,
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: Colors.grey[400]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchPhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog(context, 'Cannot launch phone dialer.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred while trying to make a call.');
    }
  }

  Future<void> _launchEmail(BuildContext context, String emailAddress) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Support Request',
        'body': userProfile != null 
            ? 'Name: ${userProfile!.name}\nEmail: ${userProfile!.email}\n\nMessage: '
            : 'I need support with: ',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorDialog(context, 'Cannot launch email client.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred while trying to send an email.');
    }
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('FAQ', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                'How do I reset my PIN?',
                'Go to Profile > Security > PIN Management to reset your PIN.',
              ),
              _buildFAQItem(
                'How to transfer money?',
                'Select Transfer from the home screen and follow the instructions.',
              ),
              _buildFAQItem(
                'Is my money safe?',
                'Yes, we use industry-standard security measures to protect your funds.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
