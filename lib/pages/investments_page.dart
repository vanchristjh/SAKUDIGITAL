import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          InvestmentCard(
            title: 'Stocks',
            description: 'Invest in company shares',
            icon: Icons.trending_up,
          ),
          InvestmentCard(
            title: 'Mutual Funds',
            description: 'Professionally managed investment funds',
            icon: Icons.account_balance,
          ),
          InvestmentCard(
            title: 'Bonds',
            description: 'Government and corporate bonds',
            icon: Icons.security,
          ),
        ],
      ),
    );
  }
}

class InvestmentCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const InvestmentCard({
    required this.title,
    required this.description,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Handle investment option tap
        },
      ),
    );
  }
}
