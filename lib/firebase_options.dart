// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAES7tLob4GkaR3JQbGysBawnGRfUrrK7E',
    appId: '1:796150564786:web:13f63e7f35b7239d75c6ab',
    messagingSenderId: '796150564786',
    projectId: 'sakudigital-3021c',
    authDomain: 'sakudigital-3021c.firebaseapp.com',
    storageBucket: 'sakudigital-3021c.firebasestorage.app',
    measurementId: 'G-VHWGQR7E02',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXMNE5zkeB2gAJS4CHsXrrOpGXGVMZo8g',
    appId: '1:796150564786:android:8db08df182e6276d75c6ab',
    messagingSenderId: '796150564786',
    projectId: 'sakudigital-3021c',
    storageBucket: 'sakudigital-3021c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAaXVEZU-BqtFS43FVfdDnNTE3d7_YA2Fs',
    appId: '1:796150564786:ios:6b3203dd3d90819c75c6ab',
    messagingSenderId: '796150564786',
    projectId: 'sakudigital-3021c',
    storageBucket: 'sakudigital-3021c.firebasestorage.app',
    iosBundleId: 'com.example.sakudigital',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAaXVEZU-BqtFS43FVfdDnNTE3d7_YA2Fs',
    appId: '1:796150564786:ios:6b3203dd3d90819c75c6ab',
    messagingSenderId: '796150564786',
    projectId: 'sakudigital-3021c',
    storageBucket: 'sakudigital-3021c.firebasestorage.app',
    iosBundleId: 'com.example.sakudigital',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAES7tLob4GkaR3JQbGysBawnGRfUrrK7E',
    appId: '1:796150564786:web:c335765bf2ae521c75c6ab',
    messagingSenderId: '796150564786',
    projectId: 'sakudigital-3021c',
    authDomain: 'sakudigital-3021c.firebaseapp.com',
    storageBucket: 'sakudigital-3021c.firebasestorage.app',
    measurementId: 'G-6BNX6LESV4',
  );
}
