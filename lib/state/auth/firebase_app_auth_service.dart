import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../../firebase/firebase_initializer.dart';
import 'app_auth_service.dart';

class FirebaseAppAuthService extends ChangeNotifier implements AppAuthService {
  FirebaseAppAuthService({
    FirebaseInitializer? firebaseInitializer,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseInitializer =
           firebaseInitializer ?? DefaultFirebaseInitializer(),
       _firebaseAuthProvider = firebaseAuth == null
           ? (() => firebase_auth.FirebaseAuth.instance)
           : (() => firebaseAuth) {
    unawaited(_bindAuthState());
  }

  final FirebaseInitializer _firebaseInitializer;
  final firebase_auth.FirebaseAuth Function() _firebaseAuthProvider;
  firebase_auth.FirebaseAuth? _firebaseAuth;
  StreamSubscription<firebase_auth.User?>? _userSubscription;
  AppAuthState _state = const AppAuthState();

  @override
  AppAuthState get state => _state;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final auth = await _ensureFirebaseAuth();
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final auth = await _ensureFirebaseAuth();
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    final auth = await _ensureFirebaseAuth();
    await auth.signOut();
  }

  Future<void> _bindAuthState() async {
    final didInitialize = await _firebaseInitializer.initialize();
    if (!didInitialize) {
      return;
    }
    final auth = _firebaseAuthProvider();
    _firebaseAuth = auth;
    _setUser(auth.currentUser);
    _userSubscription = auth.authStateChanges().listen(_setUser);
  }

  Future<firebase_auth.FirebaseAuth> _ensureFirebaseAuth() async {
    final existing = _firebaseAuth;
    if (existing != null) {
      return existing;
    }

    final didInitialize = await _firebaseInitializer.initialize();
    if (!didInitialize) {
      throw const AuthFailure('Firebase Auth is only available on web.');
    }

    final auth = _firebaseAuthProvider();
    _firebaseAuth = auth;
    _userSubscription ??= auth.authStateChanges().listen(_setUser);
    return auth;
  }

  void _setUser(firebase_auth.User? user) {
    final nextState = AppAuthState(uid: user?.uid, email: user?.email);
    if (_state.uid == nextState.uid && _state.email == nextState.email) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  String _messageFor(firebase_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Email is already in use.',
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account is disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Invalid email or password.',
      'weak-password' => 'Password is too weak.',
      _ => error.message ?? 'Authentication failed.',
    };
  }

  @override
  void dispose() {
    unawaited(_userSubscription?.cancel());
    super.dispose();
  }
}
