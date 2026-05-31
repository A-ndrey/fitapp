import 'dart:async';

import 'package:fitapp/firebase/firebase_initializer.dart';
import 'package:fitapp/firebase_options.dart';
import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/auth/app_auth_service.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/shared_preferences_sync_metadata_store.dart';
import 'package:fitapp/state/persistence/sync_metadata.dart';
import 'package:fitapp/state/sync/app_store_sync_coordinator.dart';
import 'package:fitapp/state/sync/app_store_sync_status.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/remote_snapshot.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web initializer calls Firebase.initializeApp with generated options',
    () async {
      FirebaseOptions? receivedOptions;
      final initializer = DefaultFirebaseInitializer(
        isWeb: true,
        optionsProvider: () => DefaultFirebaseOptions.web,
        initializeWithOptions: (options) async {
          receivedOptions = options;
        },
      );

      final didInitialize = await initializer.initialize();

      expect(didInitialize, isTrue);
      expect(receivedOptions, isNotNull);
      expect(receivedOptions!.apiKey, DefaultFirebaseOptions.web.apiKey);
      expect(receivedOptions!.appId, DefaultFirebaseOptions.web.appId);
      expect(
        receivedOptions!.messagingSenderId,
        DefaultFirebaseOptions.web.messagingSenderId,
      );
      expect(receivedOptions!.projectId, DefaultFirebaseOptions.web.projectId);
    },
  );

  test(
    'non-web initializer stays safe for tests and non-web execution',
    () async {
      var initializeCallCount = 0;
      final initializer = DefaultFirebaseInitializer(
        isWeb: false,
        initializeWithOptions: (_) async {
          initializeCallCount += 1;
        },
      );

      final didInitialize = await initializer.initialize();

      expect(didInitialize, isFalse);
      expect(initializeCallCount, 0);
    },
  );

  test('placeholder firebase options reject unsupported platforms', () {
    expect(
      () => DefaultFirebaseOptions.currentPlatform,
      throwsA(isA<UnsupportedError>()),
    );
  });

  testWidgets(
    'app startup creates the coordinator and triggers reconcile after runApp without blocking the first frame',
    (tester) async {
      final events = <String>[];
      final initializerCompleter = Completer<void>();
      final persistence = _InMemoryAppStorePersistence();
      final metadataStore = _FakeSyncMetadataStore();
      final syncAccess = FitAppSyncAccess();
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {
          events.add('firebase-init');
          await initializerCompleter.future;
        }),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              events.add('hydrate-store');
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: () => metadataStore,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => _FakeAuthService.signedIn(),
        syncCoordinatorFactory:
            ({
              required metadataStore,
              required syncService,
              required userIdProvider,
              required bindPersistedStateObserver,
              required loadLocalSnapshot,
              required applyRemoteSnapshot,
            }) {
              events.add('create-coordinator');
              return AppStoreSyncCoordinator(
                metadataStore: metadataStore,
                syncService: syncService,
                userIdProvider: userIdProvider,
                bindPersistedStateObserver: bindPersistedStateObserver,
                loadLocalSnapshot: loadLocalSnapshot,
                applyRemoteSnapshot: applyRemoteSnapshot,
              );
            },
        syncAccess: syncAccess,
      );

      await launchFitApp(
        startup: startup,
        appRunner: (app) async {
          events.add('run-app');
          await tester.pumpWidget(app);
          expect(find.byType(WidgetsApp), findsOneWidget);
        },
      );

      expect(events, ['hydrate-store', 'run-app', 'firebase-init']);
      expect(syncAccess.coordinator, isNull);
      expect(find.byType(WidgetsApp), findsOneWidget);

      initializerCompleter.complete();
      await tester.pump();
      await tester.pump();

      expect(events, [
        'hydrate-store',
        'run-app',
        'firebase-init',
        'create-coordinator',
        'fetch-remote',
        'push-remote',
      ]);
      expect(syncAccess.coordinator, isNotNull);
    },
  );

  testWidgets(
    'sync retry re-attempts background startup after Firebase initialization failure',
    (tester) async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final metadataStore = _FakeSyncMetadataStore();
      final syncAccess = FitAppSyncAccess();
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _FailingOnceFirebaseInitializer(events),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: () => metadataStore,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => _FakeAuthService.signedIn(),
        syncAccess: syncAccess,
      );

      await launchFitApp(
        startup: startup,
        appRunner: (app) async {
          await tester.pumpWidget(app);
        },
      );
      await tester.pump();
      await tester.pump();

      expect(events, ['firebase-init-1']);
      expect(syncAccess.coordinator, isNull);
      expect(syncAccess.status.phase, AppStoreSyncPhase.error);
      expect(
        syncAccess.status.lastErrorMessage,
        contains('firebase init failed'),
      );

      await syncAccess.syncNow();
      await tester.pump();
      await tester.pump();

      expect(events, [
        'firebase-init-1',
        'firebase-init-2',
        'fetch-remote',
        'push-remote',
      ]);
      expect(syncAccess.coordinator, isNotNull);
      expect(syncAccess.status.phase, AppStoreSyncPhase.synced);
    },
  );

  test(
    'deleteAccountData clears sync coordinator before deleting remote user state',
    () async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(events: events);
      final syncAccess = _RecordingSyncAccess(events);
      final coordinator = AppStoreSyncCoordinator(
        syncService: _RecordingSyncService(events),
        loadLocalSnapshot: () async => null,
        applyRemoteSnapshot:
            (_, {required notifyPersistedStateObserver}) async {},
      );
      addTearDown(syncAccess.dispose);
      addTearDown(coordinator.dispose);
      syncAccess.bindCoordinator(coordinator);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {}),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => authService,
        syncAccess: syncAccess,
      );

      await startup.deleteAccountData(password: 'secret123');

      expect(events, [
        'reauth:secret123',
        'clear-coordinator',
        'delete-remote:user-1',
        'delete-auth',
      ]);
      expect(authService.state.isSignedIn, isFalse);
      expect(persistence.state, isNull);
    },
  );

  test(
    'deleteAccountData stops bound coordinator before later local saves can sync',
    () async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(events: events);
      final syncAccess = _RecordingSyncAccess(events);
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {}),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => authService,
        syncAccess: syncAccess,
      );

      await startup.startBackgroundSync();
      expect(syncAccess.coordinator, isNotNull);
      expect(events, ['fetch-remote', 'push-remote']);

      await startup.deleteAccountData(password: 'secret123');
      startup.store.setAppearancePreference(AppearancePreference.dark);
      await _pumpEventQueue();

      final deleteIndex = events.indexOf('delete-remote:user-1');
      expect(deleteIndex, isNot(-1));
      expect(events.skip(deleteIndex + 1), isNot(contains('push-remote')));
    },
  );

  test(
    'deleteAccountData waits for in-flight coordinator push before remote deletion',
    () async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(events: events);
      final syncAccess = _RecordingSyncAccess(events);
      final syncService = _BlockingPushSyncService(events);
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {}),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => syncService,
        authServiceFactory: (_) => authService,
        syncAccess: syncAccess,
      );

      final syncFuture = startup.startBackgroundSync();
      await syncService.waitForPushStart();

      final deletionFuture = startup.deleteAccountData(password: 'secret123');
      await _pumpEventQueue();

      expect(events, [
        'fetch-remote',
        'push-start',
        'reauth:secret123',
        'clear-coordinator',
      ]);

      syncService.completePush();
      await syncFuture;
      await deletionFuture;

      expect(events, [
        'fetch-remote',
        'push-start',
        'reauth:secret123',
        'clear-coordinator',
        'push-finish',
        'delete-remote:user-1',
        'delete-auth',
      ]);
    },
  );

  test(
    'deleteAccountData prevents in-flight background startup from binding a coordinator',
    () async {
      final events = <String>[];
      final initializerCompleter = Completer<void>();
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(events: events);
      final syncAccess = _RecordingSyncAccess(events);
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {
          events.add('firebase-init');
          await initializerCompleter.future;
        }),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => authService,
        syncCoordinatorFactory:
            ({
              required metadataStore,
              required syncService,
              required userIdProvider,
              required bindPersistedStateObserver,
              required loadLocalSnapshot,
              required applyRemoteSnapshot,
            }) {
              events.add('create-coordinator');
              return AppStoreSyncCoordinator(
                metadataStore: metadataStore,
                syncService: syncService,
                userIdProvider: userIdProvider,
                bindPersistedStateObserver: bindPersistedStateObserver,
                loadLocalSnapshot: loadLocalSnapshot,
                applyRemoteSnapshot: applyRemoteSnapshot,
              );
            },
        syncAccess: syncAccess,
      );

      final syncFuture = startup.startBackgroundSync();
      await _pumpEventQueue();

      events.add('delete-start');
      final deletionFuture = startup.deleteAccountData(password: 'secret123');
      await _pumpEventQueue();

      initializerCompleter.complete();
      await Future.wait([syncFuture, deletionFuture]);

      final deletionStartIndex = events.indexOf('delete-start');
      expect(deletionStartIndex, isNot(-1));
      expect(
        events.skip(deletionStartIndex + 1),
        isNot(
          anyOf(
            contains('create-coordinator'),
            contains('fetch-remote'),
            contains('push-remote'),
          ),
        ),
      );
      expect(
        events,
        containsAllInOrder([
          'reauth:secret123',
          'delete-remote:user-1',
          'delete-auth',
        ]),
      );
    },
  );

  test(
    'deleteAccountData leaves sync and remote data untouched when reauth fails',
    () async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(
        events: events,
        reauthError: const AuthFailure('Invalid email or password.'),
      );
      final syncAccess = _RecordingSyncAccess(events);
      final coordinator = AppStoreSyncCoordinator(
        syncService: _RecordingSyncService(events),
        loadLocalSnapshot: () async => null,
        applyRemoteSnapshot:
            (_, {required notifyPersistedStateObserver}) async {},
      );
      addTearDown(syncAccess.dispose);
      addTearDown(coordinator.dispose);
      syncAccess.bindCoordinator(coordinator);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {}),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => authService,
        syncAccess: syncAccess,
      );

      await expectLater(
        startup.deleteAccountData(password: 'wrong-password'),
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            'Invalid email or password.',
          ),
        ),
      );

      expect(events, ['reauth:wrong-password']);
      expect(syncAccess.coordinator, same(coordinator));
      expect(syncAccess.status, coordinator.status);
      expect(authService.state.isSignedIn, isTrue);
      expect(persistence.state, isNull);
    },
  );

  test(
    'deleteAccountData does not recreate remote state when auth deletion fails after remote deletion',
    () async {
      final events = <String>[];
      final persistence = _InMemoryAppStorePersistence();
      final authService = _FakeAuthService.signedIn(
        events: events,
        deleteError: const AuthFailure('Account deletion failed.'),
      );
      final syncAccess = _RecordingSyncAccess(events);
      addTearDown(syncAccess.dispose);

      final startup = await prepareFitAppStartup(
        firebaseInitializer: _RecordingFirebaseInitializer(() async {}),
        appStorePersistenceFactory: (_) => persistence,
        appStoreHydrator:
            ({required persistence, required onPersistedStateSaved}) async {
              return AppStore(
                persistence: persistence,
                onPersistedStateSaved: onPersistedStateSaved,
              );
            },
        syncMetadataStoreFactory: _FakeSyncMetadataStore.new,
        syncServiceFactory: (_) => _RecordingSyncService(events),
        authServiceFactory: (_) => authService,
        syncAccess: syncAccess,
      );

      await expectLater(
        startup.deleteAccountData(password: 'secret123'),
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            'Account deletion failed.',
          ),
        ),
      );

      expect(events, [
        'reauth:secret123',
        'delete-remote:user-1',
        'delete-auth',
      ]);
      expect(authService.state.isSignedIn, isTrue);

      await authService.signOut();
      await authService.signIn(email: 'me@example.com', password: 'secret123');
      await startup.startBackgroundSync();
      startup.store.setAppearancePreference(AppearancePreference.dark);
      await _pumpEventQueue();

      final deleteIndex = events.indexOf('delete-remote:user-1');
      expect(deleteIndex, isNot(-1));
      expect(events.skip(deleteIndex + 1), isNot(contains('push-remote')));
      expect(syncAccess.coordinator, isNull);
    },
  );
}

class _RecordingFirebaseInitializer implements FirebaseInitializer {
  _RecordingFirebaseInitializer(this.onInitialize);

  final Future<void> Function() onInitialize;

  @override
  Future<bool> initialize() async {
    await onInitialize();
    return true;
  }
}

class _FailingOnceFirebaseInitializer implements FirebaseInitializer {
  _FailingOnceFirebaseInitializer(this.events);

  final List<String> events;
  var _attempts = 0;

  @override
  Future<bool> initialize() async {
    _attempts += 1;
    events.add('firebase-init-$_attempts');
    if (_attempts == 1) {
      throw StateError('firebase init failed');
    }
    return true;
  }
}

class _InMemoryAppStorePersistence implements AppStorePersistence {
  PersistedAppState? state;

  @override
  Future<PersistedAppState?> load() async => state;

  @override
  Future<void> save(PersistedAppState state) async {
    this.state = state;
  }
}

class _FakeSyncMetadataStore implements SharedPreferencesSyncMetadataStore {
  SyncMetadata? metadata;

  @override
  Future<SyncMetadata?> load() async => metadata;

  @override
  Future<void> save(SyncMetadata metadata) async {
    this.metadata = metadata;
  }
}

class _RecordingSyncAccess extends FitAppSyncAccess {
  _RecordingSyncAccess(this.events);

  final List<String> events;

  @override
  void clearCoordinator() {
    if (coordinator != null) {
      events.add('clear-coordinator');
    }
    super.clearCoordinator();
  }

  @override
  Future<void> stopCoordinator() async {
    if (coordinator != null) {
      events.add('clear-coordinator');
    }
    await super.stopCoordinator();
  }
}

class _RecordingSyncService implements FirebaseAppStoreSyncService {
  _RecordingSyncService(this.events);

  final List<String> events;

  @override
  final RemoteSnapshotStore backend = _NoopRemoteSnapshotStore();

  @override
  final Set<String> knownExerciseIds = const <String>{};

  @override
  Future<RemoteSnapshot?> fetch(String installationId) async {
    events.add('fetch-remote');
    return null;
  }

  @override
  Future<RemoteSnapshot> push(
    String installationId,
    PersistedAppState state,
    String snapshotHash,
  ) async {
    events.add('push-remote');
    return RemoteSnapshot(
      state: state,
      updatedAt: DateTime.utc(2026, 5, 14, 12),
      snapshotHash: snapshotHash,
    );
  }

  @override
  Future<void> deleteUserState(String userId) async {
    events.add('delete-remote:$userId');
  }
}

class _BlockingPushSyncService implements FirebaseAppStoreSyncService {
  _BlockingPushSyncService(this.events);

  final List<String> events;
  final Completer<void> _pushStarted = Completer<void>();
  final Completer<void> _pushCanFinish = Completer<void>();

  @override
  final RemoteSnapshotStore backend = _NoopRemoteSnapshotStore();

  @override
  final Set<String> knownExerciseIds = const <String>{};

  @override
  Future<RemoteSnapshot?> fetch(String installationId) async {
    events.add('fetch-remote');
    return null;
  }

  @override
  Future<RemoteSnapshot> push(
    String installationId,
    PersistedAppState state,
    String snapshotHash,
  ) async {
    events.add('push-start');
    _pushStarted.complete();
    await _pushCanFinish.future;
    events.add('push-finish');
    return RemoteSnapshot(
      state: state,
      updatedAt: DateTime.utc(2026, 5, 14, 12),
      snapshotHash: snapshotHash,
    );
  }

  Future<void> waitForPushStart() => _pushStarted.future;

  void completePush() {
    _pushCanFinish.complete();
  }

  @override
  Future<void> deleteUserState(String userId) async {
    events.add('delete-remote:$userId');
  }
}

class _FakeAuthService extends ChangeNotifier implements AppAuthService {
  _FakeAuthService.signedIn({
    List<String>? events,
    AuthFailure? reauthError,
    AuthFailure? deleteError,
  }) : _events = events,
       _reauthError = reauthError,
       _deleteError = deleteError,
       _state = const AppAuthState(uid: 'user-1', email: 'me@example.com');

  final List<String>? _events;
  final AuthFailure? _reauthError;
  final AuthFailure? _deleteError;
  AppAuthState _state;

  @override
  AppAuthState get state => _state;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _state = AppAuthState(uid: 'user-1', email: email);
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _state = const AppAuthState();
    notifyListeners();
  }

  @override
  Future<void> reauthenticate({required String password}) async {
    _events?.add('reauth:$password');
    final error = _reauthError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> deleteAccount() async {
    _events?.add('delete-auth');
    final error = _deleteError;
    if (error != null) {
      throw error;
    }
    _state = const AppAuthState();
    notifyListeners();
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    _state = AppAuthState(uid: 'user-1', email: email);
    notifyListeners();
  }
}

class _NoopRemoteSnapshotStore implements RemoteSnapshotStore {
  @override
  Future<Map<String, Object?>?> fetch(String path) async => null;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}

  @override
  Future<void> delete(String path) async {}
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
