import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saku_digital/home_page.dart';
import 'package:saku_digital/login_page.dart';
import 'package:saku_digital/login_services/forgot_password_page.dart';
import 'package:saku_digital/login_services/register_page.dart';
import 'package:saku_digital/pages/bills_page.dart';
import 'package:saku_digital/pages/investments_page.dart';
import 'package:saku_digital/pages/vouchers_page.dart';
import 'package:saku_digital/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:saku_digital/pages/isisaldo_detail.dart';
import 'package:saku_digital/pages/transfer_detail.dart';
import 'package:saku_digital/pages/profil_detail.dart';
import 'package:saku_digital/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize Firebase Messaging and handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Get the device token (useful for push notifications)
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  runApp(const MyApp());
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saku Digital',
      initialRoute: '/',  // SplashScreen will be shown initially
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/bills': (context) => const BillsPage(),
        '/investments': (context) => const InvestmentsPage(),
        '/vouchers': (context) => const VouchersPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,  // Primary color for the app
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
