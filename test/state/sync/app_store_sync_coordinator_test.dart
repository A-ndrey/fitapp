import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/persistence/shared_preferences_sync_metadata_store.dart';
import 'package:fitapp/state/persistence/sync_metadata.dart';
import 'package:fitapp/state/sync/app_store_sync_coordinator.dart';
import 'package:fitapp/state/sync/app_store_sync_status.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/installation_id_store.dart';
import 'package:fitapp/state/sync/remote_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'startup reconcile uploads local state when remote is missing',
    () async {
      final localSnapshot = _stateWithFood('tomato');
      final harness = _CoordinatorHarness(
        localSnapshot: localSnapshot,
        remoteSnapshot: null,
      );

      await harness.coordinator.start();

      expect(harness.pushCalls, hasLength(1));
      expect(harness.pushCalls.single.installationId, 'installation-1');
      expect(harness.pushCalls.single.state.userFoods.single.id, 'tomato');
      expect(harness.appliedRemoteSnapshots, isEmpty);
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
      expect(harness.coordinator.status.lastSyncedAt, isNotNull);
      expect(harness.coordinator.status.lastErrorMessage, isNull);
      expect(harness.metadataStore.savedMetadata, hasLength(1));
      expect(
        harness.metadataStore.savedMetadata.single.lastSyncedSnapshotHash,
        _snapshotHash(localSnapshot),
      );
    },
  );

  test(
    'startup reconcile applies remote state when remote timestamp is newer than the accepted remote timestamp',
    () async {
      final localSnapshot = _stateWithFood('tomato');
      final remoteSnapshot = _stateWithFood('cucumber');
      final harness = _CoordinatorHarness(
        localSnapshot: localSnapshot,
        remoteSnapshot: RemoteSnapshot(
          state: remoteSnapshot,
          updatedAt: DateTime.utc(2026, 5, 13, 12),
          snapshotHash: _snapshotHash(remoteSnapshot),
        ),
        initialMetadata: SyncMetadata(
          installationId: 'installation-1',
          lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 10),
          lastSyncedSnapshotHash: _snapshotHash(localSnapshot),
        ),
      );

      await harness.coordinator.start();

      expect(harness.pushCalls, isEmpty);
      expect(harness.appliedRemoteSnapshots, hasLength(1));
      expect(
        harness.appliedRemoteSnapshots.single.userFoods.single.id,
        'cucumber',
      );
      expect(harness.currentLocalSnapshot.userFoods.single.id, 'cucumber');
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
      expect(
        harness.metadataStore.savedMetadata.single.lastSyncedSnapshotHash,
        _snapshotHash(remoteSnapshot),
      );
    },
  );

  test(
    'startup reconcile uploads local when remote timestamp is not newer than the accepted remote timestamp',
    () async {
      final localSnapshot = _stateWithFood('tomato');
      final remoteSnapshot = _stateWithFood('cucumber');
      final acceptedRemoteTimestamp = DateTime.utc(2026, 5, 13, 12);
      final harness = _CoordinatorHarness(
        localSnapshot: localSnapshot,
        remoteSnapshot: RemoteSnapshot(
          state: remoteSnapshot,
          updatedAt: acceptedRemoteTimestamp,
          snapshotHash: _snapshotHash(remoteSnapshot),
        ),
        initialMetadata: SyncMetadata(
          installationId: 'installation-1',
          lastKnownRemoteUpdatedAt: acceptedRemoteTimestamp,
          lastSyncedSnapshotHash: _snapshotHash(localSnapshot),
        ),
      );

      await harness.coordinator.start();

      expect(harness.pushCalls, hasLength(1));
      expect(harness.pushCalls.single.state.userFoods.single.id, 'tomato');
      expect(harness.appliedRemoteSnapshots, isEmpty);
      expect(harness.currentLocalSnapshot.userFoods.single.id, 'tomato');
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
    },
  );

  test(
    'startup reconcile uploads local when local is unsynced even if remote timestamp is newer',
    () async {
      final lastSyncedSnapshot = _stateWithFood('tomato');
      final localSnapshot = _stateWithFood('cucumber');
      final harness = _CoordinatorHarness(
        localSnapshot: localSnapshot,
        remoteSnapshot: RemoteSnapshot(
          state: lastSyncedSnapshot,
          updatedAt: DateTime.utc(2026, 5, 13, 12),
          snapshotHash: _snapshotHash(lastSyncedSnapshot),
        ),
        initialMetadata: SyncMetadata(
          installationId: 'installation-1',
          lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 10),
          lastSyncedSnapshotHash: _snapshotHash(lastSyncedSnapshot),
        ),
      );

      await harness.coordinator.start();

      expect(harness.pushCalls, hasLength(1));
      expect(harness.pushCalls.single.state.userFoods.single.id, 'cucumber');
      expect(harness.appliedRemoteSnapshots, isEmpty);
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
    },
  );

  test(
    'malformed remote payload leaves local state intact and sets error after a real decode failure',
    () async {
      final localSnapshot = _stateWithFood('tomato');
      final harness = _CoordinatorHarness(
        localSnapshot: localSnapshot,
        syncService: FirebaseAppStoreSyncService(
          backend: _StaticRemoteSnapshotStore({
            'schemaVersion': 1,
            'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 5, 13, 9)),
            'snapshotHash': 'hash-malformed',
            'payload': const <Object?>[],
          }),
          knownExerciseIds: const <String>{},
        ),
      );

      await harness.coordinator.start();

      expect(harness.appliedRemoteSnapshots, isEmpty);
      expect(harness.currentLocalSnapshot.userFoods.single.id, 'tomato');
      expect(harness.pushCalls, isEmpty);
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.error);
      expect(
        harness.coordinator.status.lastErrorMessage,
        contains('PersistedAppState'),
      );
      expect(
        harness.metadataStore.savedMetadata.single.lastSyncError,
        contains('PersistedAppState'),
      );
    },
  );

  test(
    'consecutive persisted mutations while one upload is in flight coalesce into a single follow-up upload',
    () async {
      final initialSnapshot = _stateWithFood('tomato');
      final firstQueuedSnapshot = _stateWithFood('cucumber');
      final finalQueuedSnapshot = _stateWithFood('pepper');
      final firstPushCompleter = Completer<RemoteSnapshot>();
      var pushCount = 0;
      final harness = _CoordinatorHarness(
        localSnapshot: initialSnapshot,
        remoteSnapshot: RemoteSnapshot(
          state: initialSnapshot,
          updatedAt: DateTime.utc(2026, 5, 13, 9),
          snapshotHash: _snapshotHash(initialSnapshot),
        ),
        initialMetadata: SyncMetadata(
          installationId: 'installation-1',
          lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 9),
          lastSyncedSnapshotHash: _snapshotHash(initialSnapshot),
        ),
        onPush: (installationId, state, snapshotHash) {
          pushCount += 1;
          if (pushCount == 1) {
            return firstPushCompleter.future;
          }
          return Future<RemoteSnapshot>.value(
            RemoteSnapshot(
              state: state,
              updatedAt: DateTime.utc(2026, 5, 13, 9, pushCount),
              snapshotHash: snapshotHash,
            ),
          );
        },
      );

      await harness.coordinator.start();

      harness.coordinator.persistedStateObserver(firstQueuedSnapshot);
      await _pumpEventQueue();
      harness.coordinator.persistedStateObserver(_stateWithFood('onion'));
      harness.coordinator.persistedStateObserver(finalQueuedSnapshot);
      await _pumpEventQueue();

      expect(harness.pushCalls, hasLength(1));
      expect(harness.pushCalls.single.state.userFoods.single.id, 'cucumber');

      firstPushCompleter.complete(
        RemoteSnapshot(
          state: firstQueuedSnapshot,
          updatedAt: DateTime.utc(2026, 5, 13, 9, 1),
          snapshotHash: _snapshotHash(firstQueuedSnapshot),
        ),
      );
      await _pumpEventQueue();

      expect(harness.pushCalls, hasLength(2));
      expect(harness.pushCalls.last.state.userFoods.single.id, 'pepper');
      expect(
        harness.pushCalls.last.snapshotHash,
        _snapshotHash(finalQueuedSnapshot),
      );
      expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
    },
  );

  test(
    'coordinator subscribes itself through the persisted-state binder',
    () async {
      final initialSnapshot = _stateWithFood('tomato');
      final updatedSnapshot = _stateWithFood('cucumber');
      void Function(PersistedAppState)? harnessBoundObserver;
      var binderCallCount = 0;
      final harness = _CoordinatorHarness(
        localSnapshot: initialSnapshot,
        remoteSnapshot: RemoteSnapshot(
          state: initialSnapshot,
          updatedAt: DateTime.utc(2026, 5, 13, 9),
          snapshotHash: _snapshotHash(initialSnapshot),
        ),
        initialMetadata: SyncMetadata(
          installationId: 'installation-1',
          lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 9),
          lastSyncedSnapshotHash: _snapshotHash(initialSnapshot),
        ),
        bindPersistedStateObserver: (observer) {
          harnessBoundObserver = observer;
          binderCallCount += 1;
        },
      );

      expect(binderCallCount, 1);
      expect(harnessBoundObserver, isNotNull);

      await harness.coordinator.start();

      harnessBoundObserver!(updatedSnapshot);
      await _pumpEventQueue();

      expect(harness.pushCalls, hasLength(1));
      expect(harness.pushCalls.single.state.userFoods.single.id, 'cucumber');
    },
  );

  test('manual retry triggers a sync from the latest local snapshot', () async {
    final syncedSnapshot = _stateWithFood('tomato');
    final failedSnapshot = _stateWithFood('onion');
    final freshSnapshot = _stateWithFood('cucumber');
    var shouldFail = true;
    final harness = _CoordinatorHarness(
      localSnapshot: syncedSnapshot,
      remoteSnapshot: RemoteSnapshot(
        state: syncedSnapshot,
        updatedAt: DateTime.utc(2026, 5, 13, 8),
        snapshotHash: _snapshotHash(syncedSnapshot),
      ),
      initialMetadata: SyncMetadata(
        installationId: 'installation-1',
        lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 8),
        lastSyncedSnapshotHash: _snapshotHash(syncedSnapshot),
      ),
      onPush: (installationId, state, snapshotHash) {
        if (shouldFail) {
          shouldFail = false;
          throw StateError('offline');
        }
        return Future<RemoteSnapshot>.value(
          RemoteSnapshot(
            state: state,
            updatedAt: DateTime.utc(2026, 5, 13, 8, 2),
            snapshotHash: snapshotHash,
          ),
        );
      },
    );

    await harness.coordinator.start();

    harness.coordinator.persistedStateObserver(failedSnapshot);
    await _pumpEventQueue();
    expect(harness.coordinator.status.phase, AppStoreSyncPhase.error);

    harness.currentLocalSnapshot = freshSnapshot;
    await harness.coordinator.syncNow();

    expect(harness.pushCalls, hasLength(2));
    expect(harness.pushCalls.last.state.userFoods.single.id, 'cucumber');
    expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
  });

  test('status transitions include idle, syncing, synced, and error', () async {
    final initialSnapshot = _stateWithFood('tomato');
    final updatedSnapshot = _stateWithFood('cucumber');
    final retrySnapshot = _stateWithFood('pepper');
    var shouldFail = true;
    final harness = _CoordinatorHarness(
      localSnapshot: initialSnapshot,
      remoteSnapshot: RemoteSnapshot(
        state: initialSnapshot,
        updatedAt: DateTime.utc(2026, 5, 13, 7),
        snapshotHash: _snapshotHash(initialSnapshot),
      ),
      initialMetadata: SyncMetadata(
        installationId: 'installation-1',
        lastKnownRemoteUpdatedAt: DateTime.utc(2026, 5, 13, 7),
        lastSyncedSnapshotHash: _snapshotHash(initialSnapshot),
      ),
      onPush: (installationId, state, snapshotHash) {
        if (shouldFail) {
          shouldFail = false;
          throw StateError('offline');
        }
        return Future<RemoteSnapshot>.value(
          RemoteSnapshot(
            state: state,
            updatedAt: DateTime.utc(2026, 5, 13, 7, 3),
            snapshotHash: snapshotHash,
          ),
        );
      },
    );
    final phases = <AppStoreSyncPhase>[harness.coordinator.status.phase];
    harness.coordinator.addListener(() {
      phases.add(harness.coordinator.status.phase);
    });

    await harness.coordinator.start();
    harness.currentLocalSnapshot = updatedSnapshot;
    await harness.coordinator.syncNow();
    harness.currentLocalSnapshot = retrySnapshot;
    await harness.coordinator.syncNow();

    expect(phases, contains(AppStoreSyncPhase.idle));
    expect(phases, contains(AppStoreSyncPhase.syncing));
    expect(phases, contains(AppStoreSyncPhase.synced));
    expect(phases, contains(AppStoreSyncPhase.error));
    expect(harness.coordinator.status.phase, AppStoreSyncPhase.synced);
    expect(harness.coordinator.status.lastSyncedAt, isNotNull);
    expect(harness.coordinator.status.lastErrorMessage, isNull);
  });
}

class _CoordinatorHarness {
  _CoordinatorHarness({
    required PersistedAppState localSnapshot,
    RemoteSnapshot? remoteSnapshot,
    SyncMetadata? initialMetadata,
    Object? fetchError,
    FirebaseAppStoreSyncService? syncService,
    void Function(void Function(PersistedAppState) observer)?
    bindPersistedStateObserver,
    Future<RemoteSnapshot> Function(
      String installationId,
      PersistedAppState state,
      String snapshotHash,
    )?
    onPush,
  }) : _currentLocalSnapshot = localSnapshot,
       metadataStore = _FakeSyncMetadataStore(initialMetadata),
       installationIdStore = _FakeInstallationIdStore(),
       syncService =
           syncService ??
           _FakeFirebaseAppStoreSyncService(
             remoteSnapshot: remoteSnapshot,
             fetchError: fetchError,
             onPush: onPush,
           ) {
    pushCalls = this.syncService is _FakeFirebaseAppStoreSyncService
        ? (this.syncService as _FakeFirebaseAppStoreSyncService).pushCalls
        : const <_PushCall>[];
    coordinator = AppStoreSyncCoordinator(
      installationIdStore: installationIdStore,
      metadataStore: metadataStore,
      syncService: this.syncService,
      bindPersistedStateObserver: bindPersistedStateObserver,
      loadLocalSnapshot: () async => _currentLocalSnapshot,
      applyRemoteSnapshot: (state) async {
        appliedRemoteSnapshots.add(state);
        _currentLocalSnapshot = state;
      },
    );
  }

  final _FakeSyncMetadataStore metadataStore;
  final _FakeInstallationIdStore installationIdStore;
  final FirebaseAppStoreSyncService syncService;
  late final List<_PushCall> pushCalls;
  final List<PersistedAppState> appliedRemoteSnapshots = <PersistedAppState>[];
  late final AppStoreSyncCoordinator coordinator;
  PersistedAppState _currentLocalSnapshot;

  PersistedAppState get currentLocalSnapshot => _currentLocalSnapshot;

  set currentLocalSnapshot(PersistedAppState value) {
    _currentLocalSnapshot = value;
  }
}

class _FakeInstallationIdStore implements InstallationIdStore {
  @override
  Future<String> loadOrCreate() async => 'installation-1';
}

class _FakeSyncMetadataStore implements SharedPreferencesSyncMetadataStore {
  _FakeSyncMetadataStore(this.metadata);

  SyncMetadata? metadata;
  final List<SyncMetadata> savedMetadata = <SyncMetadata>[];

  @override
  Future<SyncMetadata?> load() async => metadata;

  @override
  Future<void> save(SyncMetadata metadata) async {
    this.metadata = metadata;
    savedMetadata.add(metadata);
  }
}

class _FakeFirebaseAppStoreSyncService implements FirebaseAppStoreSyncService {
  _FakeFirebaseAppStoreSyncService({
    this.remoteSnapshot,
    this.fetchError,
    this.onPush,
  });

  @override
  final RemoteSnapshotStore backend = _NoopRemoteSnapshotStore();

  @override
  final Set<String> knownExerciseIds = const <String>{};

  final RemoteSnapshot? remoteSnapshot;
  final Object? fetchError;
  final Future<RemoteSnapshot> Function(
    String installationId,
    PersistedAppState state,
    String snapshotHash,
  )?
  onPush;
  final List<_PushCall> pushCalls = <_PushCall>[];

  @override
  Future<RemoteSnapshot?> fetch(String installationId) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return remoteSnapshot;
  }

  @override
  Future<RemoteSnapshot> push(
    String installationId,
    PersistedAppState state,
    String snapshotHash,
  ) async {
    pushCalls.add(
      _PushCall(
        installationId: installationId,
        state: state,
        snapshotHash: snapshotHash,
      ),
    );

    if (onPush != null) {
      return onPush!(installationId, state, snapshotHash);
    }

    return RemoteSnapshot(
      state: state,
      updatedAt: DateTime.utc(2026, 5, 13, 6, pushCalls.length),
      snapshotHash: snapshotHash,
    );
  }
}

class _PushCall {
  const _PushCall({
    required this.installationId,
    required this.state,
    required this.snapshotHash,
  });

  final String installationId;
  final PersistedAppState state;
  final String snapshotHash;
}

class _NoopRemoteSnapshotStore implements RemoteSnapshotStore {
  @override
  Future<Map<String, Object?>?> fetch(String path) async => null;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}
}

class _StaticRemoteSnapshotStore implements RemoteSnapshotStore {
  _StaticRemoteSnapshotStore(this.document);

  final Map<String, Object?> document;

  @override
  Future<Map<String, Object?>?> fetch(String path) async => document;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}
}

PersistedAppState _stateWithFood(String id) {
  return PersistedAppState(
    userFoods: [_food(id)],
    userDishes: const [],
    userExercises: const [],
    userTrainingPlans: const [],
    mealEntries: const [],
    preferences: const AppPreferences.defaults(),
    activeWorkoutSession: null,
    completedWorkoutSessions: const [],
    mealEntryCounter: 0,
    workoutSessionCounter: 0,
  );
}

FoodItem _food(String id) {
  return FoodItem(
    id: id,
    name: id,
    description: 'Food $id',
    servingSizeGrams: 100,
    basis: NutritionBasis.per100g,
    nutrition: const NutritionValues(
      calories: 10,
      protein: 1,
      fat: 1,
      carbs: 1,
    ),
  );
}

String _snapshotHash(PersistedAppState state) {
  final bytes = utf8.encode(jsonEncode(PersistedAppStateCodec.encode(state)));
  var hash = 0xcbf29ce484222325;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

Future<void> _pumpEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
