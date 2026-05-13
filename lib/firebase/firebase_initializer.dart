import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

typedef FirebaseOptionsInitializer =
    Future<void> Function(FirebaseOptions options);

abstract interface class FirebaseInitializer {
  Future<bool> initialize();
}

class DefaultFirebaseInitializer implements FirebaseInitializer {
  DefaultFirebaseInitializer({
    bool isWeb = kIsWeb,
    FirebaseOptionsInitializer? initializeWithOptions,
  }) : _isWeb = isWeb,
       _initializeWithOptions =
           initializeWithOptions ??
           ((options) => Firebase.initializeApp(options: options));

  final bool _isWeb;
  final FirebaseOptionsInitializer _initializeWithOptions;

  @override
  Future<bool> initialize() async {
    if (!_isWeb) {
      return false;
    }

    await _initializeWithOptions(DefaultFirebaseOptions.currentPlatform);
    return true;
  }
}
