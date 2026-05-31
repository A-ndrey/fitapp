import 'package:flutter/foundation.dart';

class AppAuthState {
  const AppAuthState({this.uid, this.email});

  final String? uid;
  final String? email;

  bool get isSignedIn => uid != null;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AppAuthService implements Listenable {
  AppAuthState get state;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();

  Future<void> reauthenticate({required String password});

  Future<void> deleteAccount();
}
