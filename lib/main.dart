import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saku_digital/home_page.dart';
import 'package:saku_digital/login_page.dart';
import 'package:saku_digital/login_services/forgot_password_page.dart';
import 'package:saku_digital/login_services/register_page.dart';
import 'package:saku_digital/pages/aktivitas_page.dart';
import 'package:saku_digital/pages/profil_detail.dart';
import 'package:saku_digital/pages/messages_page.dart';
import 'package:saku_digital/pages/transaction_detail.dart';
import 'package:saku_digital/pages/transfer_detail.dart';
import 'package:saku_digital/pages/bayar_detail.dart';
import 'package:saku_digital/pages/pindai_detail.dart';
import 'package:saku_digital/pages/isisaldo_detail.dart';
import 'package:saku_digital/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saku Digital',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => const HomePage(),
        '/aktivitas': (context) => const AktivitasPage(),
        '/profil': (context) => const ProfilDetail(),
        '/messages': (context) => const MessagesPage(),
        '/transaction': (context) => const TransactionDetail(transactionId: 0, transactionAmount: 0.0), // Default route with dummy data
        '/transfer': (context) => const TransferDetail(),
        '/bayar': (context) => const BayarDetail(),
        '/pindai': (context) => const PindaiDetail(),
        '/isisaldo': (context) => IsiSaldoDetail(onBalanceUpdated: (double balance) {}),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
