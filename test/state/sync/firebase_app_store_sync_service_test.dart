import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/installation_id_store.dart';
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
        'installation-1',
        const PersistedAppState.empty(),
        'hash-123',
      );

      expect(backend.lastSetPath, 'installations/installation-1/state/current');
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

      final snapshot = await service.fetch('installation-77');

      expect(snapshot, isA<RemoteSnapshot>());
      expect(
        backend.lastFetchPath,
        'installations/installation-77/state/current',
      );
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

        expect(() => service.fetch('installation-bad'), throwsFormatException);
      }
    },
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
}
