import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saku_digital/home_page.dart';
import 'package:saku_digital/login_page.dart';
import 'package:saku_digital/login_services/forgot_password_page.dart';
import 'package:saku_digital/login_services/register_page.dart';
import 'package:saku_digital/models/profile_model.dart';
import 'package:saku_digital/pages/bill_payment_page.dart';
import 'package:saku_digital/pages/bills_page.dart';
import 'package:saku_digital/pages/investments_page.dart';
import 'package:saku_digital/pages/vouchers_page.dart';
import 'package:saku_digital/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        // ...other providers...
      ],
      child: const MyApp(),
    ),
  );
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if necessary
  await Firebase.initializeApp();
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
        builder: (_) => BillPaymentPage(billType: billType, userBalance: 0.0),
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseMessaging _messaging;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
  }

  void _initializeFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Register the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.messageId}');
      // You can show a dialog or snackbar here
    });

    // Handle message when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // Handle the message differently or navigate to a default page
      }
    });

    // Handle message when the app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Handle the message differently or navigate to a default page
    });
  }

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
