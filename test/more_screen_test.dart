import 'dart:async';

import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/more_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/auth/app_auth_service.dart';
import 'package:fitapp/state/sync/app_store_sync_coordinator.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/app_store_sync_status.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSyncCoordinator extends AppStoreSyncCoordinator {
  _TestSyncCoordinator({AppStoreSyncStatus status = const AppStoreSyncStatus()})
    : _status = status,
      super(
        syncService: FirebaseAppStoreSyncService(
          backend: _NoopRemoteSnapshotStore(),
        ),
        loadLocalSnapshot: () async => null,
        applyRemoteSnapshot:
            (_, {required notifyPersistedStateObserver}) async {},
      );

  AppStoreSyncStatus _status;

  @override
  AppStoreSyncStatus get status => _status;

  void setStatus(AppStoreSyncStatus nextStatus) {
    _status = nextStatus;
    notifyListeners();
  }
}

class _NoopRemoteSnapshotStore implements RemoteSnapshotStore {
  @override
  Future<Map<String, Object?>?> fetch(String path) async => null;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}
}

class _TrackingSyncAccess extends FitAppSyncAccess {
  int syncNowCallCount = 0;

  @override
  Future<void> syncNow() async {
    syncNowCallCount += 1;
  }
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AppStore store, {
    FitAppSyncAccess? syncAccess,
    AppAuthService? authService,
    Size? size,
  }) async {
    if (size != null) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await tester.pumpWidget(
      MaterialApp(
        home: MoreScreen(
          store: store,
          syncStatusListenable: syncAccess,
          readSyncStatus: () => syncAccess?.status,
          authListenable: authService,
          readAuthState: () => authService?.state ?? const AppAuthState(),
          onSignIn: authService?.signIn,
          onSignUp: authService?.signUp,
          onSignOut: authService?.signOut,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings screen uses redesigned settings surface', (
    tester,
  ) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Units, sync, and app preferences.'), findsNothing);
    expect(find.text('Sync'), findsNothing);
    expect(find.text('Sync status'), findsNothing);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Daily macro targets'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Ready to sync.'), findsNothing);
    expect(find.text('Sync now'), findsNothing);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('more screen hides sync error status while signed out', (
    tester,
  ) async {
    final syncAccess = _TrackingSyncAccess()
      ..reportError(StateError('Sync failed while reaching the server.'));
    addTearDown(syncAccess.dispose);

    await pumpScreen(tester, AppStore(), syncAccess: syncAccess);

    expect(find.text('Account'), findsOneWidget);
    expect(find.textContaining('Sync error:'), findsNothing);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
    expect(find.text('Sync now'), findsNothing);
    expect(syncAccess.syncNowCallCount, 0);
  });

  testWidgets(
    'signed-in account card reflects coordinator sync status updates',
    (tester) async {
      final syncAccess = FitAppSyncAccess();
      final coordinator = _TestSyncCoordinator();
      final authService = _FakeAuthService(
        const AppAuthState(uid: 'user-1', email: 'me@example.com'),
      );
      addTearDown(syncAccess.dispose);
      addTearDown(coordinator.dispose);

      syncAccess.bindCoordinator(coordinator);
      await pumpScreen(
        tester,
        AppStore(),
        syncAccess: syncAccess,
        authService: authService,
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.textContaining('me@example.com'), findsOneWidget);
      expect(find.text('Ready to sync.'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      coordinator.setStatus(
        const AppStoreSyncStatus(phase: AppStoreSyncPhase.syncing),
      );
      await tester.pumpAndSettle();
      expect(find.text('Syncing...'), findsOneWidget);
    },
  );

  testWidgets('more screen preference chips update store', (tester) async {
    final store = AppStore();

    await pumpScreen(tester, store, size: const Size(900, 1200));

    await tester.ensureVisible(find.text('Pounds'));
    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();

    expect(store.preferences.workoutWeightUnit, WorkoutWeightUnit.pounds);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('more screen applies daily macro targets to the store', (
    tester,
  ) async {
    final store = AppStore();

    await pumpScreen(tester, store, size: const Size(900, 1400));

    await tester.enterText(
      find.bySemanticsLabel('Daily calories target'),
      '2100',
    );
    await tester.enterText(
      find.bySemanticsLabel('Daily protein target'),
      '140',
    );
    await tester.enterText(find.bySemanticsLabel('Daily fat target'), '65');
    await tester.enterText(find.bySemanticsLabel('Daily carbs target'), '260');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Apply targets'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply targets'));
    await tester.pumpAndSettle();

    expect(
      store.preferences.dailyMacroTargets,
      const NutritionValues(calories: 2100, protein: 140, fat: 65, carbs: 260),
    );
  });

  testWidgets('selected settings chips use readable checkmark color', (
    tester,
  ) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    final systemChip = find.widgetWithText(ChoiceChip, 'System');
    final chip = tester.widget<ChoiceChip>(systemChip);
    final context = tester.element(systemChip);
    final colorScheme = Theme.of(context).colorScheme;

    expect(chip.selected, isTrue);
    expect(chip.selectedColor, colorScheme.primaryContainer);
    expect(chip.checkmarkColor, colorScheme.onPrimaryContainer);
    expect(chip.labelStyle?.color, colorScheme.onPrimaryContainer);
  });

  testWidgets('login button opens sign in form and submits credentials', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.widgetWithText(AppBar, 'Sign in'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Sign in'),
      ),
      findsNothing,
    );
    expect(
      find.text('Use your account to sync FitApp data across devices.'),
      findsNothing,
    );
    expect(find.text('New here? Create account'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(authService.signInCalls, [
      const _AuthCall(email: 'me@example.com', password: 'secret123'),
    ]);
    expect(find.widgetWithText(AppBar, 'Sign in'), findsNothing);
    expect(find.textContaining('me@example.com'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('login form switches to sign up and renders auth errors', (
    tester,
  ) async {
    final authService = _FakeAuthService()
      ..nextError = const AuthFailure('Email is already in use.');

    await pumpScreen(tester, AppStore(), authService: authService);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.enterText(
      find.bySemanticsLabel('Confirm password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(authService.signUpCalls, [
      const _AuthCall(email: 'me@example.com', password: 'secret123'),
    ]);
    expect(find.text('Email is already in use.'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('login form rewrites generic auth errors into useful copy', (
    tester,
  ) async {
    final authService = _FakeAuthService()
      ..nextError = const AuthFailure('Error');

    await pumpScreen(tester, AppStore(), authService: authService);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsNothing);
    expect(
      find.text(
        "We couldn't sign you in. Check your email and password, then try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('signup form rewrites generic auth errors into useful copy', (
    tester,
  ) async {
    final authService = _FakeAuthService()
      ..nextError = const AuthFailure('Error');

    await pumpScreen(tester, AppStore(), authService: authService);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.enterText(
      find.bySemanticsLabel('Confirm password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsNothing);
    expect(
      find.text(
        "We couldn't create your account. Check your email and password, then try again.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('signup form requires matching password confirmation', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create account'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Confirm password'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.enterText(
      find.bySemanticsLabel('Confirm password'),
      'different123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(authService.signUpCalls, isEmpty);

    await tester.enterText(
      find.bySemanticsLabel('Confirm password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(authService.signUpCalls, [
      const _AuthCall(email: 'me@example.com', password: 'secret123'),
    ]);
  });

  testWidgets('auth form validates email before submitting', (tester) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Email'), 'not-an-email');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(authService.signInCalls, isEmpty);
  });

  testWidgets('signup form uses account-creation autofill hints', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create account'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));

    expect(fields, hasLength(3));
    expect(
      fields.elementAt(1).autofillHints,
      contains(AutofillHints.newPassword),
    );
    expect(fields.elementAt(1).textInputAction, TextInputAction.next);
    expect(
      fields.elementAt(2).autofillHints,
      contains(AutofillHints.newPassword),
    );
    expect(fields.elementAt(2).textInputAction, TextInputAction.done);
  });

  testWidgets('login form supports mobile keyboard and autofill flow', (
    tester,
  ) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    final emailField = fields.elementAt(0);
    final passwordField = fields.elementAt(1);

    expect(emailField.autofocus, isTrue);
    expect(emailField.autofillHints, contains(AutofillHints.email));
    expect(passwordField.autofillHints, contains(AutofillHints.password));
    expect(passwordField.textInputAction, TextInputAction.done);
    expect(passwordField.obscureText, isTrue);

    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(authService.signInCalls, [
      const _AuthCall(email: 'me@example.com', password: 'secret123'),
    ]);
  });

  testWidgets('login form toggles password visibility', (tester) async {
    final authService = _FakeAuthService();

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .elementAt(1)
          .obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .elementAt(1)
          .obscureText,
      isFalse,
    );
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('login form disables submit while request is in flight', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    final signInCompleter = Completer<void>();
    authService.nextSignInCompletion = signInCompleter;

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);

    signInCompleter.complete();
    await tester.pumpAndSettle();

    expect(authService.signInCalls, [
      const _AuthCall(email: 'me@example.com', password: 'secret123'),
    ]);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('login form clears auth error after editing a field', (
    tester,
  ) async {
    final authService = _FakeAuthService()
      ..nextError = const AuthFailure('Invalid email or password.');

    await pumpScreen(tester, AppStore(), authService: authService);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Email'), 'me@example.com');
    await tester.enterText(find.bySemanticsLabel('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('Email'), 'new@example.com');
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsNothing);
  });

  testWidgets('logout button signs out authenticated user', (tester) async {
    final authService = _FakeAuthService(
      const AppAuthState(uid: 'user-1', email: 'me@example.com'),
    );

    await pumpScreen(tester, AppStore(), authService: authService);

    expect(find.textContaining('me@example.com'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(authService.signOutCallCount, 1);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('more screen stacks preference cards below medium layout', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(390, 844));

    final unitsCard = find.ancestor(
      of: find.text('Workout weight'),
      matching: find.byType(Card),
    );
    final dishCard = find.ancestor(
      of: find.text('Dish weight'),
      matching: find.byType(Card),
    );
    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));

    expect(unitsCard, findsOneWidget);
    expect(dishCard, findsOneWidget);
    expect(
      identical(unitsCard.evaluate().single, dishCard.evaluate().single),
      isTrue,
    );
    expect(dishTopLeft.dy, greaterThan(workoutTopLeft.dy));
    expect((dishTopLeft.dx - workoutTopLeft.dx).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('more screen keeps unit preferences in one card when wide', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(900, 900));

    final unitsCard = find.ancestor(
      of: find.text('Workout weight'),
      matching: find.byType(Card),
    );
    final dishCard = find.ancestor(
      of: find.text('Dish weight'),
      matching: find.byType(Card),
    );
    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));

    expect(unitsCard, findsOneWidget);
    expect(dishCard, findsOneWidget);
    expect(
      identical(unitsCard.evaluate().single, dishCard.evaluate().single),
      isTrue,
    );
    expect(dishTopLeft.dy, greaterThan(workoutTopLeft.dy));
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthService extends ChangeNotifier implements AppAuthService {
  _FakeAuthService([AppAuthState initialState = const AppAuthState()])
    : _state = initialState;

  @override
  AppAuthState get state => _state;

  AppAuthState _state;
  AuthFailure? nextError;
  Completer<void>? nextSignInCompletion;
  final List<_AuthCall> signInCalls = <_AuthCall>[];
  final List<_AuthCall> signUpCalls = <_AuthCall>[];
  int signOutCallCount = 0;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCalls.add(_AuthCall(email: email, password: password));
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    final completer = nextSignInCompletion;
    if (completer != null) {
      nextSignInCompletion = null;
      await completer.future;
    }
    _state = AppAuthState(uid: 'user-1', email: email);
    notifyListeners();
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUpCalls.add(_AuthCall(email: email, password: password));
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    _state = AppAuthState(uid: 'user-1', email: email);
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    signOutCallCount += 1;
    _state = const AppAuthState();
    notifyListeners();
  }
}

class _AuthCall {
  const _AuthCall({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      other is _AuthCall && other.email == email && other.password == password;

  @override
  int get hashCode => Object.hash(email, password);
}
