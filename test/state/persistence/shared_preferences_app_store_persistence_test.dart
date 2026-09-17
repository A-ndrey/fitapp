import 'dart:convert';

import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/app_state_components.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/persistence/persisted_state_slices.dart';
import 'package:fitapp/state/persistence/shared_preferences_app_store_persistence.dart';
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

  test('empty persistence has no device cache or owner', () async {
    SharedPreferences.setMockInitialValues(const {});
    final persistence = SharedPreferencesAppStorePersistence();

    expect(await persistence.load(), isNull);
    expect(persistence.ownerUserId, isNull);
    expect(persistence.loadError, isNull);
  });

  test('unscoped v1 state migrates without deleting rollback data', () async {
    final legacy = _stateWithFood('legacy-food');
    final legacyRaw = jsonEncode(PersistedAppStateCodec.encode(legacy));
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAppStorePersistence.storageKey: legacyRaw,
    });
    final persistence = SharedPreferencesAppStorePersistence();

    final migrated = await persistence.load();
    final preferences = await SharedPreferences.getInstance();

    expect(migrated!.userFoods.single.id, 'legacy-food');
    expect(persistence.ownerUserId, isNull);
    expect(
      preferences.getString(SharedPreferencesAppStorePersistence.storageKey),
      legacyRaw,
    );
    expect(
      preferences.getKeys(),
      contains('app_store_state_v3:device:manifest'),
    );
  });

  test('unscoped v1 async migration failure is reported', () async {
    SharedPreferences.resetStatic();
    final platformStore = _ControllableSharedPreferencesStore();
    SharedPreferencesStorePlatform.instance = platformStore;
    final preferences = await SharedPreferences.getInstance();
    final legacyRaw = jsonEncode(
      PersistedAppStateCodec.encode(_stateWithFood('legacy-food')),
    );
    await preferences.setString(
      SharedPreferencesAppStorePersistence.storageKey,
      legacyRaw,
    );
    platformStore.failDeviceManifestWrites = true;
    final persistence = SharedPreferencesAppStorePersistence();

    expect(await persistence.load(), isNull);
    expect(persistence.loadError, isA<StateError>());
    expect(
      preferences.getString(SharedPreferencesAppStorePersistence.storageKey),
      legacyRaw,
    );
  });

  test(
    'single legacy account cache becomes the device cache before first frame',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();
      await _writeLegacyV2(
        preferences,
        scope: 'guest',
        state: _stateWithFood('guest-food'),
      );
      await _writeLegacyV2(
        preferences,
        scope: 'user:user-1',
        state: _stateWithFood('account-food'),
      );
      final legacyManifest = preferences.getString(
        'app_store_state_v2:user:user-1:manifest',
      );
      final persistence = SharedPreferencesAppStorePersistence();

      final migrated = await persistence.load();

      expect(migrated!.userFoods.single.id, 'account-food');
      expect(persistence.ownerUserId, 'user-1');
      expect(
        preferences.getString('app_store_state_v2:user:user-1:manifest'),
        legacyManifest,
      );
      expect(
        preferences.getString('app_store_state_v2:guest:manifest'),
        isNotNull,
      );
    },
  );

  test('single account async migration failure is reported', () async {
    SharedPreferences.resetStatic();
    final platformStore = _ControllableSharedPreferencesStore();
    SharedPreferencesStorePlatform.instance = platformStore;
    final preferences = await SharedPreferences.getInstance();
    await _writeLegacyV2(
      preferences,
      scope: 'user:user-1',
      state: _stateWithFood('account-food'),
    );
    platformStore.failDeviceManifestWrites = true;
    final persistence = SharedPreferencesAppStorePersistence();

    expect(await persistence.load(), isNull);
    expect(persistence.loadError, isA<StateError>());
    expect(persistence.ownerUserId, isNull);
    expect(
      preferences.getString('app_store_state_v2:user:user-1:manifest'),
      isNotNull,
    );
  });

  test('multiple legacy account caches wait for authenticated user', () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    await _writeLegacyV2(
      preferences,
      scope: 'user:user-1',
      state: _stateWithFood('food-1'),
    );
    await _writeLegacyV2(
      preferences,
      scope: 'user:user-2',
      state: _stateWithFood('food-2'),
    );
    final persistence = SharedPreferencesAppStorePersistence();

    expect(await persistence.load(), isNull);
    expect(persistence.ownerUserId, isNull);

    final migrated = await persistence.migrateLegacyAccount('user-2');

    expect(migrated!.userFoods.single.id, 'food-2');
    expect(persistence.ownerUserId, 'user-2');
  });

  test('device cache owner survives save and reload', () async {
    SharedPreferences.setMockInitialValues(const {});
    final persistence = SharedPreferencesAppStorePersistence();
    await persistence.replace(_stateWithFood('tomato'), ownerUserId: 'user-1');

    final reloadedPersistence = SharedPreferencesAppStorePersistence();
    final reloaded = await reloadedPersistence.load();

    expect(reloaded!.userFoods.single.id, 'tomato');
    expect(reloadedPersistence.ownerUserId, 'user-1');
  });

  test('saving one changed slice reuses every unchanged slice', () async {
    SharedPreferences.setMockInitialValues(const {});
    final persistence = SharedPreferencesAppStorePersistence();
    await persistence.replace(_stateWithFood('first'), ownerUserId: 'user-1');
    final preferences = await SharedPreferences.getInstance();
    final firstPointers = _devicePointers(preferences);

    await persistence.save(_stateWithFood('second'));
    final secondPointers = _devicePointers(preferences);

    expect(
      secondPointers[AppStateSlice.foodLibrary.name],
      isNot(firstPointers[AppStateSlice.foodLibrary.name]),
    );
    for (final slice in AppStateSlice.values) {
      if (slice == AppStateSlice.foodLibrary) {
        continue;
      }
      expect(secondPointers[slice.name], firstPointers[slice.name]);
    }
  });

  test(
    'invalid cache is reported without throwing or overwriting it',
    () async {
      const manifestKey = 'app_store_state_v3:device:manifest';
      SharedPreferences.setMockInitialValues({manifestKey: '{'});
      final persistence = SharedPreferencesAppStorePersistence();

      expect(await persistence.load(), isNull);
      expect(persistence.loadError, isA<FormatException>());
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(manifestKey), '{');
    },
  );

  test('clear removes device and retained legacy state only', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAppStorePersistence.storageKey: '{}',
      'app_store_sync_metadata_v1:user-1': 'metadata',
    });
    final preferences = await SharedPreferences.getInstance();
    await _writeLegacyV2(
      preferences,
      scope: 'user:user-1',
      state: _stateWithFood('legacy'),
    );
    final persistence = SharedPreferencesAppStorePersistence();
    await persistence.replace(_stateWithFood('current'), ownerUserId: 'user-1');

    await persistence.clear();

    expect(
      preferences.getKeys().where((key) => key.startsWith('app_store_state')),
      isEmpty,
    );
    expect(
      preferences.getString('app_store_sync_metadata_v1:user-1'),
      'metadata',
    );
    expect(persistence.ownerUserId, isNull);
  });

  test('save failure does not commit an owner or manifest', () async {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance =
        _FailingSetValueSharedPreferencesStore();
    final persistence = SharedPreferencesAppStorePersistence();

    await expectLater(
      persistence.replace(
        const PersistedAppState.empty(),
        ownerUserId: 'user-1',
      ),
      throwsA(isA<StateError>()),
    );
    expect(persistence.ownerUserId, isNull);
  });

  test('failed manifest commit keeps the previous cache readable', () async {
    SharedPreferences.resetStatic();
    final platformStore = _ControllableSharedPreferencesStore();
    SharedPreferencesStorePlatform.instance = platformStore;
    final persistence = SharedPreferencesAppStorePersistence();
    await persistence.replace(
      _stateWithFood('previous-food'),
      ownerUserId: 'user-1',
    );
    platformStore.failDeviceManifestWrites = true;

    await expectLater(
      persistence.replace(
        _stateWithFood('replacement-food'),
        ownerUserId: 'user-2',
      ),
      throwsA(isA<StateError>()),
    );
    expect(persistence.ownerUserId, 'user-1');

    SharedPreferences.resetStatic();
    platformStore.failDeviceManifestWrites = false;
    final reloadedPersistence = SharedPreferencesAppStorePersistence();
    final reloaded = await reloadedPersistence.load();

    expect(reloaded!.userFoods.single.id, 'previous-food');
    expect(reloadedPersistence.ownerUserId, 'user-1');
  });

  test('known exercise IDs are frozen at construction', () async {
    final legacyRaw = jsonEncode(
      _persistedPayloadWithTrainingExercise('builtin-burpee'),
    );
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAppStorePersistence.storageKey: legacyRaw,
    });
    final knownExerciseIds = <String>{'builtin-burpee'};
    final persistence = SharedPreferencesAppStorePersistence(
      knownExerciseIds: knownExerciseIds,
    );
    knownExerciseIds.clear();

    final reloaded = await persistence.load();

    expect(
      reloaded!.userTrainingPlans.single.exercises.single.exerciseId,
      'builtin-burpee',
    );
  });
}

Future<void> _writeLegacyV2(
  SharedPreferences preferences, {
  required String scope,
  required PersistedAppState state,
}) async {
  final pointers = <String, String>{};
  final slices = PersistedStateSlices.encode(state);
  for (final slice in AppStateSlice.values) {
    final key = 'app_store_state_v2:$scope:test:${slice.name}';
    await preferences.setString(key, jsonEncode(slices[slice]));
    pointers[slice.name] = key;
  }
  await preferences.setString(
    'app_store_state_v2:$scope:manifest',
    jsonEncode(<String, Object?>{'schemaVersion': 2, 'slices': pointers}),
  );
}

Map<String, Object?> _devicePointers(SharedPreferences preferences) {
  final raw = preferences.getString('app_store_state_v3:device:manifest')!;
  final manifest = jsonDecode(raw) as Map<String, Object?>;
  return Map<String, Object?>.from(manifest['slices']! as Map);
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
      'dailyMacroTargets': {
        'calories': 2000.0,
        'protein': 150.0,
        'fat': 70.0,
        'carbs': 250.0,
      },
    },
    'activeWorkoutSession': null,
    'completedWorkoutSessions': const [],
    'mealEntryCounter': 0,
    'workoutSessionCounter': 0,
  };
}

class _FailingSetValueSharedPreferencesStore
    extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => <String, Object>{};

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _ControllableSharedPreferencesStore
    extends SharedPreferencesStorePlatform {
  final Map<String, Object> values = <String, Object>{};
  bool failDeviceManifestWrites = false;

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async => Map.of(values);

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failDeviceManifestWrites &&
        key.endsWith('app_store_state_v3:device:manifest')) {
      return false;
    }
    values[key] = value;
    return true;
  }
}
