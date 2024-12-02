import 'package:flutter/material.dart';

class IsiSaldoDetail extends StatefulWidget {
  final Function(double) onBalanceUpdated;

  const IsiSaldoDetail({super.key, required this.onBalanceUpdated});

  @override
  _IsiSaldoDetailState createState() => _IsiSaldoDetailState();
}

class _IsiSaldoDetailState extends State<IsiSaldoDetail> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorMessage;
  String? _selectedBank;

  final List<Map<String, String>> banks = [
    {'name': 'BRI', 'logo': 'assets/bri_logo.png'},
    {'name': 'Mandiri', 'logo': 'assets/mandiri_logo.jpg'},
    {'name': 'BNI', 'logo': 'assets/bni_logo.png'},
    {'name': 'BCA', 'logo': 'assets/bca_logo.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isi Saldo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Pilih Bank dan Masukkan Jumlah Saldo yang ingin Anda Isi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            // Pemilihan Bank
            Text(
              'Pilih Bank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: banks.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBank = banks[index]['name'];
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(banks[index]['logo']!),
                        radius: 25,
                      ),
                      title: Text(banks[index]['name']!),
                      tileColor: _selectedBank == banks[index]['name']
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Input Jumlah Saldo
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Jumlah Saldo',
                hintText: 'Rp 0',
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
              ),
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            // Tombol Isi Saldo
            ElevatedButton(
              onPressed: _topUpBalance,
              child: const Text('Isi Saldo', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), 
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Info
            Text(
              'Saldo yang diisi akan langsung ditambahkan ke saldo Anda.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _topUpBalance() {
    final String amountText = _amountController.text;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih bank terlebih dahulu')),
      );
      return;
    }

    if (amountText.isEmpty || double.tryParse(amountText) == null || double.parse(amountText) <= 0) {
      setState(() {
        _errorMessage = 'Masukkan jumlah yang valid!';
      });
    } else {
      final double amount = double.parse(amountText);
      widget.onBalanceUpdated(amount);  // Update the balance in the parent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo berhasil diisi sebesar Rp $amount dari $_selectedBank')),
      );
      Navigator.pop(context);  // Close the page
    }
  }
}
