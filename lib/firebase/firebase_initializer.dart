import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

typedef FirebaseOptionsInitializer =
    Future<void> Function(FirebaseOptions options);
typedef FirebaseOptionsProvider = FirebaseOptions Function();

abstract interface class FirebaseInitializer {
  Future<bool> initialize();
}

class DefaultFirebaseInitializer implements FirebaseInitializer {
  DefaultFirebaseInitializer({
    bool isWeb = kIsWeb,
    FirebaseOptionsInitializer? initializeWithOptions,
    FirebaseOptionsProvider? optionsProvider,
  }) : _isWeb = isWeb,
       _optionsProvider =
           optionsProvider ?? (() => DefaultFirebaseOptions.currentPlatform),
       _initializeWithOptions =
           initializeWithOptions ??
           ((options) => Firebase.initializeApp(options: options));

  final bool _isWeb;
  final FirebaseOptionsProvider _optionsProvider;
  final FirebaseOptionsInitializer _initializeWithOptions;

  @override
  Future<bool> initialize() async {
    if (!_isWeb) {
      return false;
    }

    await _initializeWithOptions(_optionsProvider());
    return true;
  }
}
