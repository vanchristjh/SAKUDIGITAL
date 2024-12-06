import 'package:flutter/material.dart';
import '../register_page.dart' as register; // Add this import
import '../services/firebase_service.dart';

class PinScreen extends StatefulWidget {
  final Function(String) onPinVerified;
  final String title;

  const PinScreen({
    Key? key, 
    required this.onPinVerified,
    this.title = 'Enter PIN',
  }) : super(key: key);

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String pin = '';
  final int pinLength = 6;
  bool isLoading = false;
  String? errorMessage;

  void _verifyPin() async {
    if (pin.length == pinLength) {
      if (!mounted) return;
      
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Simplified verification - just pass the PIN to the callback
        widget.onPinVerified(pin);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          errorMessage = e.toString();
          pin = '';
        });
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void addDigit(String digit) {
    if (!isLoading && pin.length < pinLength) {
      setState(() {
        pin += digit;
        errorMessage = null;
      });
      if (pin.length == pinLength) {
        _verifyPin();
      }
    }
  }

  void removeDigit() {
    if (!isLoading && pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
        errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pinLength,
                    (index) => Container(
                      margin: const EdgeInsets.all(8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < pin.length 
                          ? Colors.blue 
                          : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            AbsorbPointer(
              absorbing: isLoading,
              child: Opacity(
                opacity: isLoading ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) return const SizedBox.shrink();
                      if (index == 10) {
                        return NumPadButton(
                          text: '0',
                          onTap: () => addDigit('0'),
                        );
                      }
                      if (index == 11) {
                        return NumPadButton(
                          text: '←',
                          onTap: removeDigit,
                        );
                      }
                      return NumPadButton(
                        text: '${index + 1}',
                        onTap: () => addDigit('${index + 1}'),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class NumPadButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const NumPadButton({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white, // Add proper contrast
            ),
          ),
        ),
      ),
    );
  }
}
