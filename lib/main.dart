import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saku_digital/home_page.dart';
import 'package:saku_digital/login_page.dart';
import 'package:saku_digital/login_services/forgot_password_page.dart';
import 'package:saku_digital/login_services/register_page.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';
import 'package:saku_digital/pages/bills_page.dart';
import 'package:saku_digital/pages/investments_page.dart';
import 'package:saku_digital/pages/vouchers_page.dart';
import 'package:saku_digital/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

class Routes {
  static const String billPayment = '/bill-payment';
  static const String bills = '/bills';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.billPayment:
      final billType = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => BillPaymentPage(billType: billType),
        settings: settings,
      );
    case Routes.bills:
      return MaterialPageRoute(
        builder: (_) => const BillsPage(),
        settings: settings,
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Route not found')),
        ),
      );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saku Digital',
      theme: ThemeData.dark(),
      initialRoute: '/',
      onGenerateRoute: generateRoute,
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/investments': (context) => const InvestmentsPage(),
        '/vouchers': (context) => const VouchersPage(),
      },
    );
  }
}
