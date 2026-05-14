import 'dart:async';

import 'package:fitapp/firebase/firebase_initializer.dart';
import 'package:fitapp/firebase_options.dart';
import 'package:fitapp/main.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/shared_preferences_sync_metadata_store.dart';
import 'package:fitapp/state/persistence/sync_metadata.dart';
import 'package:fitapp/state/sync/app_store_sync_coordinator.dart';
import 'package:fitapp/state/sync/app_store_sync_status.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/installation_id_store.dart';
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
        installationIdStoreFactory: () => _FakeInstallationIdStore(),
        syncServiceFactory: (_) => _RecordingSyncService(events),
        syncCoordinatorFactory:
            ({
              required installationIdStore,
              required metadataStore,
              required syncService,
              required bindPersistedStateObserver,
              required loadLocalSnapshot,
              required applyRemoteSnapshot,
            }) {
              events.add('create-coordinator');
              return AppStoreSyncCoordinator(
                installationIdStore: installationIdStore,
                metadataStore: metadataStore,
                syncService: syncService,
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
        installationIdStoreFactory: () => _FakeInstallationIdStore(),
        syncServiceFactory: (_) => _RecordingSyncService(events),
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

class _FakeInstallationIdStore implements InstallationIdStore {
  @override
  Future<String> loadOrCreate() async => 'installation-1';
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
}

class _NoopRemoteSnapshotStore implements RemoteSnapshotStore {
  @override
  Future<Map<String, Object?>?> fetch(String path) async => null;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}
}
