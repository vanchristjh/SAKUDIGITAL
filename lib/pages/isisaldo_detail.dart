import 'package:flutter/material.dart';

class IsisaldoDetail extends StatefulWidget {
  const IsisaldoDetail({Key? key}) : super(key: key);

  @override
  _IsisaldoDetailState createState() => _IsisaldoDetailState();
}

class _IsisaldoDetailState extends State<IsisaldoDetail> {
  String? _selectedBank;
  final List<String> _banks = ['BRI', 'BNI', 'Mandiri', 'BCA', 'Danamon'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Isi Saldo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Dropdown for bank selection
              DropdownButtonFormField<String>(
                value: _selectedBank,
                hint: const Text(
                  'Pilih Bank',
                  style: TextStyle(color: Colors.white),
                ),
                items: _banks.map((String bank) {
                  return DropdownMenuItem<String>(
                    value: bank,
                    child: Text(
                      bank,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBank = newValue;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Custom amount TextField
              TextField(
                decoration: InputDecoration(
                  hintText: 'Masukkan Jumlah Saldo',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.wallet, color: Colors.white),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),

              // Predefined amounts for top-up
              const Text(
                'Pilih Jumlah Top-Up:',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),

              // Predefined top-up buttons
              Wrap(
                spacing: 10,
                children: [
                  _buildTopUpButton(context, 'Rp 50.000'),
                  _buildTopUpButton(context, 'Rp 100.000'),
                  _buildTopUpButton(context, 'Rp 200.000'),
                  _buildTopUpButton(context, 'Rp 500.000'),
                ],
              ),
              const SizedBox(height: 30),

              // Elevated button for submitting the balance
              ElevatedButton(
                onPressed: () {
                  if (_selectedBank != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saldo berhasil diisi melalui $_selectedBank!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan pilih bank terlebih dahulu!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: const Text(
                  'Isi Saldo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopUpButton(BuildContext context, String amount) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top-Up Amount: $amount')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 3,
      ),
      child: Text(
        amount,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}