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
    apiKey: 'AIzaSyCXbeMwhnOJ9u3ebJKecjiG-fRMaBqyo7E',
    appId: '1:253211492166:web:feedc83d86ec8537c22f47',
    messagingSenderId: '253211492166',
    projectId: 'fitapp-37523',
    authDomain: 'fitapp-37523.firebaseapp.com',
    storageBucket: 'fitapp-37523.firebasestorage.app',
    measurementId: 'G-RZJJ6SVL94',
  );

}