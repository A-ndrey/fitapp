import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder web options so the app builds before FlutterFire configure runs.
///
/// Replace this file with generated output from `flutterfire configure` when a
/// real Firebase project is available.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are only configured for web in this app.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder-web-api-key',
    appId: '1:1234567890:web:placeholderfitapp',
    messagingSenderId: '1234567890',
    projectId: 'placeholder-fitapp',
    authDomain: 'placeholder-fitapp.firebaseapp.com',
    storageBucket: 'placeholder-fitapp.firebasestorage.app',
  );
}
