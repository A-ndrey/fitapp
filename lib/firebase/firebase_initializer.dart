import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

typedef FirebaseOptionsInitializer =
    Future<void> Function(FirebaseOptions options);
typedef FirebaseOptionsProvider = FirebaseOptions Function();
typedef FirebaseAppsProvider = List<FirebaseApp> Function();

abstract interface class FirebaseInitializer {
  Future<bool> initialize();
}

class DefaultFirebaseInitializer implements FirebaseInitializer {
  DefaultFirebaseInitializer({
    bool isWeb = kIsWeb,
    FirebaseOptionsInitializer? initializeWithOptions,
    FirebaseOptionsProvider? optionsProvider,
    FirebaseAppsProvider? appsProvider,
  }) : _isWeb = isWeb,
       _optionsProvider =
           optionsProvider ?? (() => DefaultFirebaseOptions.currentPlatform),
       _appsProvider = appsProvider ?? (() => Firebase.apps),
       _initializeWithOptions =
           initializeWithOptions ??
           ((options) => Firebase.initializeApp(options: options));

  final bool _isWeb;
  final FirebaseOptionsProvider _optionsProvider;
  final FirebaseAppsProvider _appsProvider;
  final FirebaseOptionsInitializer _initializeWithOptions;
  Future<bool>? _initializationFuture;

  @override
  Future<bool> initialize() async {
    return _initializationFuture ??= _initialize();
  }

  Future<bool> _initialize() async {
    if (!_isWeb) {
      return false;
    }

    if (_appsProvider().isNotEmpty) {
      return true;
    }

    await _initializeWithOptions(_optionsProvider());
    return true;
  }
}
