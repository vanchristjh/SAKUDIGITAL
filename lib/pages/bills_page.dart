import 'package:flutter/material.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Bills'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Payment Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildBillCard(
                    context: context,
                    title: 'Electricity',
                    icon: Icons.electric_bolt,
                    color: Colors.blue,
                    type: 'Electricity',
                  ),
                  _buildBillCard(
                    context: context,
                    title: 'Water',
                    icon: Icons.water_drop,
                    color: Colors.cyan,
                    type: 'Water',
                  ),
                  _buildBillCard(
                    context: context,
                    title: 'Internet',
                    icon: Icons.wifi,
                    color: Colors.orange,
                    type: 'Internet',
                  ),
                  _buildBillCard(
                    context: context,
                    title: 'Phone',
                    icon: Icons.phone,
                    color: Colors.green,
                    type: 'Phone',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillPaymentPage(billType: type),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
