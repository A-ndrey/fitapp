import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/installation_id_store.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:fitapp/state/sync/remote_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'InstallationIdStore returns a stable ID after save and reload',
    () async {
      SharedPreferences.setMockInitialValues(const {});

      final store = InstallationIdStore();
      final first = await store.loadOrCreate();
      final reloaded = await InstallationIdStore().loadOrCreate();

      expect(first, isNotEmpty);
      expect(first.length, greaterThanOrEqualTo(32));
      expect(reloaded, first);
    },
  );

  test('entity sync migrates legacy state and commits a v2 manifest', () async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = _FakeEntityRemoteSnapshotStore();
    final legacy = _stateWithFood('legacy-food');
    backend.documents['users/user-1/state/current'] = _remoteDocument(
      updatedAt: DateTime.utc(2026, 5, 13),
      snapshotHash: 'legacy-hash',
      payload: PersistedAppStateCodec.encode(legacy),
    );
    final service = FirebaseAppStoreSyncService(backend: backend);

    final beforeMigration = await service.fetch('user-1');
    expect(beforeMigration!.isLegacy, isTrue);

    final migrated = await service.push('user-1', legacy, 'ignored');
    final reloaded = await service.fetch('user-1');

    expect(migrated.isLegacy, isFalse);
    expect(reloaded!.state.userFoods.single.id, 'legacy-food');
    expect(
      backend.documents['users/user-1/sync/manifest']!['committed'],
      isTrue,
    );
    expect(backend.documents, contains('users/user-1/foods/legacy-food'));
    expect(
      backend.documents,
      contains('users/user-1/state/current'),
      reason: 'legacy rollback data must remain available',
    );
  });

  test(
    'entity sync writes tombstones instead of resurrectable deletes',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final backend = _FakeEntityRemoteSnapshotStore();
      final service = FirebaseAppStoreSyncService(backend: backend);

      await service.push('user-1', _stateWithFood('tomato'), 'ignored');
      backend.lastBatchPaths.clear();
      await service.push('user-1', const PersistedAppState.empty(), 'ignored');

      expect(backend.lastBatchPaths, contains('users/user-1/foods/tomato'));
      expect(
        backend.documents['users/user-1/foods/tomato']!['deletedAt'],
        isNotNull,
      );
      expect((await service.fetch('user-1'))!.state.userFoods, isEmpty);
    },
  );

  test('entity sync upgrades order-sensitive legacy content hashes', () async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = _FakeEntityRemoteSnapshotStore();
    final state = _stateWithFood('tomato');
    final originalPayload = PersistedAppStateCodec.encodeFoodItem(
      state.userFoods.single,
    );
    final reorderedPayload = <String, Object?>{
      for (final key in originalPayload.keys.toList().reversed)
        key: originalPayload[key],
    };
    backend.documents['users/user-1/sync/manifest'] = <String, Object?>{
      'schemaVersion': 2,
      'committed': true,
      'snapshotHash': 'legacy-snapshot-hash',
      'updatedAt': DateTime.utc(2026, 5, 13),
      'writerId': 'old-writer',
    };
    backend.documents['users/user-1/foods/tomato'] = <String, Object?>{
      'schemaVersion': 2,
      'payload': reorderedPayload,
      'contentHash': _legacyHashJson(originalPayload),
      'updatedAt': DateTime.utc(2026, 5, 13),
      'writerId': 'old-writer',
      'deletedAt': null,
    };
    final service = FirebaseAppStoreSyncService(backend: backend);

    final legacySnapshot = await service.fetch('user-1');
    expect(legacySnapshot!.isLegacy, isTrue);
    expect(legacySnapshot.state.userFoods.single.id, 'tomato');

    await service.push('user-1', legacySnapshot.state, 'ignored');
    final upgradedDocument = backend.documents['users/user-1/foods/tomato']!;
    expect(upgradedDocument['contentHashVersion'], 3);
    expect((await service.fetch('user-1'))!.isLegacy, isFalse);
  });

  test('entity sync upgrades v2 hashes after numeric normalization', () async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = _FakeEntityRemoteSnapshotStore();
    final payload = PersistedAppStateCodec.encodeFoodItem(
      _stateWithFood('tomato').userFoods.single,
    );
    final firestorePayload = _convertWholeDoublesToInts(payload);
    backend.documents['users/user-1/sync/manifest'] = <String, Object?>{
      'schemaVersion': 2,
      'committed': true,
    };
    backend.documents['users/user-1/foods/tomato'] = <String, Object?>{
      'schemaVersion': 2,
      'payload': firestorePayload,
      'contentHash': 'v2-order-only-hash',
      'contentHashVersion': 2,
      'updatedAt': DateTime.utc(2026, 5, 13),
      'deletedAt': null,
    };
    final service = FirebaseAppStoreSyncService(backend: backend);

    final v2Snapshot = await service.fetch('user-1');
    expect(v2Snapshot!.isLegacy, isTrue);
    await service.push('user-1', v2Snapshot.state, 'ignored');

    final upgradedDocument = backend.documents['users/user-1/foods/tomato']!;
    expect(upgradedDocument['contentHashVersion'], 3);
    expect((await service.fetch('user-1'))!.isLegacy, isFalse);
  });

  test('canonical hashes treat whole doubles and integers equally', () {
    expect(
      PersistedEntityBundle.hashJson({
        'servingSizeGrams': 100.0,
        'nutrition': {'calories': 123.0},
      }),
      PersistedEntityBundle.hashJson({
        'servingSizeGrams': 100,
        'nutrition': {'calories': 123},
      }),
    );
  });

  test('v3 validation canonicalizes Firestore numeric payloads', () async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = _FakeEntityRemoteSnapshotStore();
    final payload = PersistedAppStateCodec.encodeFoodItem(
      _stateWithFood('tomato').userFoods.single,
    );
    backend.documents['users/user-1/sync/manifest'] = <String, Object?>{
      'schemaVersion': 2,
      'committed': true,
    };
    backend.documents['users/user-1/foods/tomato'] = <String, Object?>{
      'schemaVersion': 2,
      'payload': _convertWholeDoublesToInts(payload),
      'contentHash': PersistedEntityBundle.hashJson(payload),
      'contentHashVersion': 3,
      'updatedAt': DateTime.utc(2026, 5, 13),
      'deletedAt': null,
    };

    final snapshot = await FirebaseAppStoreSyncService(
      backend: backend,
    ).fetch('user-1');

    expect(snapshot!.isLegacy, isFalse);
    expect(snapshot.state.userFoods.single.servingSizeGrams, 100.0);
  });

  test('entity sync rejects invalid canonical content hashes', () async {
    SharedPreferences.setMockInitialValues(const {});
    final backend = _FakeEntityRemoteSnapshotStore();
    final payload = PersistedAppStateCodec.encodeFoodItem(
      _stateWithFood('tomato').userFoods.single,
    );
    backend.documents['users/user-1/sync/manifest'] = <String, Object?>{
      'schemaVersion': 2,
      'committed': true,
    };
    backend.documents['users/user-1/foods/tomato'] = <String, Object?>{
      'schemaVersion': 2,
      'payload': payload,
      'contentHash': 'invalid',
      'contentHashVersion': 3,
      'updatedAt': DateTime.utc(2026, 5, 13),
      'deletedAt': null,
    };

    expect(
      () => FirebaseAppStoreSyncService(backend: backend).fetch('user-1'),
      throwsFormatException,
    );
  });

  test(
    'InstallationIdStore returns one ID for concurrent first-use callers',
    () async {
      final preferences = _DelayedInstallationIdPreferences();
      final generatedIds = <String>['generated-id-1', 'generated-id-2'];
      final installationIdStore = InstallationIdStore(
        preferencesLoader: () async => preferences,
        idGenerator: () => generatedIds.removeAt(0),
      );
      final firstFuture = installationIdStore.loadOrCreate();
      final secondFuture = installationIdStore.loadOrCreate();

      await preferences.waitForSetCallCount(1);
      preferences.completePendingWrites();

      final ids = await Future.wait([firstFuture, secondFuture]);

      expect(ids[0], ids[1]);
      expect(ids[0], 'generated-id-1');
      expect(preferences.setStringCallCount, 1);
    },
  );

  test(
    'InstallationIdStore serializes concurrent first-use callers across instances',
    () async {
      final preferences = _DelayedInstallationIdPreferences();
      final generatedIds = <String>['generated-id-1', 'generated-id-2'];
      final firstStore = InstallationIdStore(
        preferencesLoader: () async => preferences,
        idGenerator: () => generatedIds.removeAt(0),
      );
      final secondStore = InstallationIdStore(
        preferencesLoader: () async => preferences,
        idGenerator: () => generatedIds.removeAt(0),
      );

      final firstFuture = firstStore.loadOrCreate();
      final secondFuture = secondStore.loadOrCreate();

      await preferences.waitForSetCallCount(1);
      await Future<void>.delayed(Duration.zero);
      preferences.completePendingWrites();

      final ids = await Future.wait([firstFuture, secondFuture]);

      expect(ids[0], ids[1]);
      expect(ids[0], 'generated-id-1');
      expect(preferences.setStringCallCount, 1);
    },
  );

  test(
    'FirebaseAppStoreSyncService.push encodes and writes Firestore payload',
    () async {
      final updatedAt = DateTime.utc(2026, 5, 13, 12, 30, 45);
      final backend = _FakeRemoteSnapshotStore(
        fetchResult: _remoteDocument(
          updatedAt: updatedAt,
          snapshotHash: 'hash-123',
          payload: PersistedAppStateCodec.encode(
            const PersistedAppState.empty(),
          ),
        ),
      );
      final service = FirebaseAppStoreSyncService(
        backend: backend,
        knownExerciseIds: const {},
      );

      final snapshot = await service.push(
        'user-1',
        const PersistedAppState.empty(),
        'hash-123',
      );

      expect(backend.lastSetPath, 'users/user-1/state/current');
      expect(backend.lastSetData, isNotNull);
      expect(backend.lastSetData!['schemaVersion'], 1);
      expect(backend.lastSetData!['updatedAt'], isA<FieldValue>());
      expect(backend.lastSetData!['snapshotHash'], 'hash-123');
      expect(
        backend.lastSetData!['payload'],
        PersistedAppStateCodec.encode(const PersistedAppState.empty()),
      );
      expect(snapshot.updatedAt, updatedAt);
      expect(snapshot.snapshotHash, 'hash-123');
    },
  );

  test(
    'FirebaseAppStoreSyncService.push fails when fetched snapshot hash differs',
    () async {
      final backend = _FakeRemoteSnapshotStore(
        fetchResult: _remoteDocument(
          updatedAt: DateTime.utc(2026, 5, 13, 12, 30, 45),
          snapshotHash: 'other-hash',
          payload: PersistedAppStateCodec.encode(
            const PersistedAppState.empty(),
          ),
        ),
      );
      final service = FirebaseAppStoreSyncService(
        backend: backend,
        knownExerciseIds: const {},
      );

      expect(
        () => service.push(
          'user-1',
          const PersistedAppState.empty(),
          'expected-hash',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'FirebaseAppStoreSyncService.deleteUserState deletes the user snapshot document',
    () async {
      final backend = _FakeRemoteSnapshotStore();
      final service = FirebaseAppStoreSyncService(backend: backend);

      await service.deleteUserState('user-1');

      expect(backend.lastDeletePath, 'users/user-1/state/current');
    },
  );

  test(
    'FirebaseAppStoreSyncService.fetch decodes a valid remote snapshot',
    () async {
      final updatedAt = DateTime.utc(2026, 5, 13, 14, 15, 16);
      final backend = _FakeRemoteSnapshotStore(
        fetchResult: _remoteDocument(
          updatedAt: updatedAt,
          snapshotHash: 'hash-remote',
          payload: _persistedPayloadWithTrainingExercise('builtin-burpee'),
        ),
      );
      final service = FirebaseAppStoreSyncService(
        backend: backend,
        knownExerciseIds: const {'builtin-burpee'},
      );

      final snapshot = await service.fetch('user-77');

      expect(snapshot, isA<RemoteSnapshot>());
      expect(backend.lastFetchPath, 'users/user-77/state/current');
      expect(snapshot!.updatedAt, updatedAt);
      expect(snapshot.snapshotHash, 'hash-remote');
      expect(
        snapshot.state.userTrainingPlans.single.exercises.single.exerciseId,
        'builtin-burpee',
      );
    },
  );

  test(
    'FirebaseAppStoreSyncService throws FormatException on malformed remote data',
    () async {
      final malformedDocuments = <Map<String, Object?>>[
        {
          'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 5, 13)),
          'snapshotHash': 'hash',
          'payload': PersistedAppStateCodec.encode(
            const PersistedAppState.empty(),
          ),
        },
        {
          'schemaVersion': 1,
          'snapshotHash': 'hash',
          'payload': PersistedAppStateCodec.encode(
            const PersistedAppState.empty(),
          ),
        },
        {
          'schemaVersion': 1,
          'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 5, 13)),
          'payload': PersistedAppStateCodec.encode(
            const PersistedAppState.empty(),
          ),
        },
        {
          'schemaVersion': 1,
          'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 5, 13)),
          'snapshotHash': 'hash',
          'payload': const <Object?>[],
        },
      ];

      for (final document in malformedDocuments) {
        final service = FirebaseAppStoreSyncService(
          backend: _FakeRemoteSnapshotStore(fetchResult: document),
          knownExerciseIds: const {},
        );

        expect(() => service.fetch('user-bad'), throwsFormatException);
      }
    },
  );
}

PersistedAppState _stateWithFood(String id) {
  return PersistedAppState(
    userFoods: [
      FoodItem(
        id: id,
        name: id,
        description: id,
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues.zero,
      ),
    ],
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

Map<String, Object?> _remoteDocument({
  required DateTime updatedAt,
  required String snapshotHash,
  required Object payload,
}) {
  return <String, Object?>{
    'schemaVersion': 1,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'snapshotHash': snapshotHash,
    'payload': payload,
  };
}

String _legacyHashJson(Object? value) {
  final bytes = utf8.encode(jsonEncode(value));
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

Object? _convertWholeDoublesToInts(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: _convertWholeDoublesToInts(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_convertWholeDoublesToInts).toList(growable: false);
  }
  if (value is double && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return value;
}

Map<String, Object?> _persistedPayloadWithTrainingExercise(String exerciseId) {
  return <String, Object?>{
    'userFoods': const [],
    'userDishes': const [],
    'userExercises': const [],
    'userTrainingPlans': [
      {
        'id': 'plan-1',
        'name': 'Plan',
        'description': 'Built-in exercise plan',
        'exercises': [
          {
            'exerciseId': exerciseId,
            'sets': 3,
            'reps': 10,
            'weight': null,
            'time': null,
            'unit': 'reps',
          },
        ],
      },
    ],
    'mealEntries': const [],
    'preferences': {
      'appearance': 'system',
      'language': 'english',
      'workoutWeightUnit': 'kilograms',
      'dishWeightUnit': 'grams',
      'heightUnit': 'centimeters',
      'distanceUnit': 'kilometers',
    },
    'activeWorkoutSession': null,
    'completedWorkoutSessions': const [],
    'mealEntryCounter': 0,
    'workoutSessionCounter': 0,
  };
}

class _FakeRemoteSnapshotStore implements RemoteSnapshotStore {
  _FakeRemoteSnapshotStore({this.fetchResult});

  Map<String, Object?>? fetchResult;
  String? lastFetchPath;
  String? lastSetPath;
  String? lastDeletePath;
  Map<String, Object?>? lastSetData;

  @override
  Future<Map<String, Object?>?> fetch(String path) async {
    lastFetchPath = path;
    return fetchResult;
  }

  @override
  Future<void> set(String path, Map<String, Object?> data) async {
    lastSetPath = path;
    lastSetData = Map<String, Object?>.from(data);
  }

  @override
  Future<void> delete(String path) async {
    lastDeletePath = path;
  }
}

class _FakeEntityRemoteSnapshotStore implements EntityRemoteSnapshotStore {
  final Map<String, Map<String, Object?>> documents = {};
  final List<String> lastBatchPaths = [];
  var _clock = DateTime.utc(2026, 5, 13, 12);

  @override
  Future<Map<String, Object?>?> fetch(String path) async {
    final value = documents[path];
    return value == null ? null : Map<String, Object?>.from(value);
  }

  @override
  Future<void> set(String path, Map<String, Object?> data) async {
    documents[path] = _resolve(data);
  }

  @override
  Future<void> delete(String path) async {
    documents.remove(path);
  }

  @override
  Future<List<RemoteEntityRecord>> fetchCollection(String path) async {
    final prefix = '$path/';
    return documents.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map(
          (entry) => RemoteEntityRecord(
            path: entry.key,
            data: Map<String, Object?>.from(entry.value),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<List<RemoteEntityRecord>> watchCollection(String path) =>
      const Stream<List<RemoteEntityRecord>>.empty();

  @override
  Future<void> setAll(Map<String, Map<String, Object?>> values) async {
    lastBatchPaths.addAll(values.keys);
    for (final entry in values.entries) {
      documents[entry.key] = _resolve(entry.value);
    }
  }

  @override
  Future<bool> acquireMigrationLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
  }) async {
    documents[path] = <String, Object?>{
      'schemaVersion': 2,
      'committed': false,
      'writerId': writerId,
      'leaseExpiresAt': expiresAt,
      'updatedAt': _nextTimestamp(),
    };
    return true;
  }

  @override
  Future<bool> claimActiveWorkoutLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
    required bool force,
  }) async {
    final document = documents[path];
    if (document == null || document['deletedAt'] != null) {
      return false;
    }
    document['leaseOwnerId'] = writerId;
    document['leaseExpiresAt'] = Timestamp.fromDate(expiresAt);
    document['updatedAt'] = _nextTimestamp();
    return true;
  }

  @override
  Future<void> deleteCollection(String path) async {
    final prefix = '$path/';
    documents.removeWhere((key, _) => key.startsWith(prefix));
  }

  Map<String, Object?> _resolve(Map<String, Object?> data) {
    return data.map((key, value) {
      return MapEntry(key, value is FieldValue ? _nextTimestamp() : value);
    });
  }

  DateTime _nextTimestamp() {
    _clock = _clock.add(const Duration(seconds: 1));
    return _clock;
  }
}

class _DelayedInstallationIdPreferences implements InstallationIdPreferences {
  final Map<String, String> _values = <String, String>{};
  final List<Completer<bool>> _pendingSetCompleters = <Completer<bool>>[];
  final Completer<void> _firstSetCallCompleter = Completer<void>();
  int setStringCallCount = 0;

  Future<void> waitForSetCallCount(int count) async {
    if (setStringCallCount >= count) {
      return;
    }

    await _firstSetCallCompleter.future;
  }

  void completePendingWrites() {
    for (final completer in _pendingSetCompleters) {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }
  }

  @override
  String? getString(String key) => _values[key];

  @override
  Future<bool> setString(String key, String value) {
    setStringCallCount += 1;
    if (!_firstSetCallCompleter.isCompleted) {
      _firstSetCallCompleter.complete();
    }

    final completer = Completer<bool>();
    _pendingSetCompleters.add(completer);
    completer.future.then((didSave) {
      if (didSave) {
        _values[key] = value;
      }
    });
    return completer.future;
  }
}
