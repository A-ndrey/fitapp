import 'dart:convert';

import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
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

  test(
    'SharedPreferencesAppStorePersistence returns null when empty',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final persistence = SharedPreferencesAppStorePersistence();

      expect(await persistence.load(), isNull);
    },
  );

  test('legacy state migrates to v2 without deleting rollback data', () async {
    final legacy = _stateWithFood('legacy-food');
    final legacyRaw = jsonEncode(PersistedAppStateCodec.encode(legacy));
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAppStorePersistence.storageKey: legacyRaw,
    });
    final persistence = SharedPreferencesAppStorePersistence();

    final migrated = await persistence.load();
    final preferences = await SharedPreferences.getInstance();

    expect(migrated!.userFoods.single.id, 'legacy-food');
    expect(
      preferences.getString(SharedPreferencesAppStorePersistence.storageKey),
      legacyRaw,
    );
    expect(
      preferences.getKeys(),
      contains('app_store_state_v2:guest:manifest'),
    );
  });

  test('guest and account caches stay isolated', () async {
    SharedPreferences.setMockInitialValues(const {});
    final persistence = SharedPreferencesAppStorePersistence();
    final guest = _stateWithFood('guest-food');
    final account = _stateWithFood('account-food');

    await persistence.save(guest);
    final seeded = await persistence.activateAccount('user-1', seed: guest);
    expect(seeded!.userFoods.single.id, 'guest-food');

    await persistence.save(account);
    final guestReloaded = await persistence.activateGuest();
    final accountReloaded = await persistence.activateAccount('user-1');

    expect(guestReloaded!.userFoods.single.id, 'guest-food');
    expect(accountReloaded!.userFoods.single.id, 'account-food');
  });

  test(
    'SharedPreferencesAppStorePersistence saves and reloads state',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final persistence = SharedPreferencesAppStorePersistence();

      await persistence.save(const PersistedAppState.empty());
      final reloaded = await persistence.load();

      expect(reloaded, isNotNull);
      expect(reloaded!.mealEntryCounter, 0);
    },
  );

  test(
    'SharedPreferencesAppStorePersistence throws when persisted value is invalid JSON',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppStorePersistence.storageKey: '{',
      });
      final persistence = SharedPreferencesAppStorePersistence();

      expect(persistence.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesAppStorePersistence throws when persisted value is not a JSON object',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppStorePersistence.storageKey: '[]',
      });
      final persistence = SharedPreferencesAppStorePersistence();

      expect(persistence.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesAppStorePersistence throws when persisted value is an empty string',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppStorePersistence.storageKey: '',
      });
      final persistence = SharedPreferencesAppStorePersistence();

      expect(persistence.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesAppStorePersistence throws when SharedPreferences save fails',
    () async {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance =
          _FailingSetValueSharedPreferencesStore();
      final persistence = SharedPreferencesAppStorePersistence();

      expect(
        () => persistence.save(const PersistedAppState.empty()),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'SharedPreferencesAppStorePersistence freezes knownExerciseIds at construction',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppStorePersistence.storageKey: jsonEncode(
          _persistedPayloadWithTrainingExercise('builtin-burpee'),
        ),
      });
      final knownExerciseIds = <String>{'builtin-burpee'};
      final persistence = SharedPreferencesAppStorePersistence(
        knownExerciseIds: knownExerciseIds,
      );
      knownExerciseIds.clear();

      final reloaded = await persistence.load();

      expect(reloaded, isNotNull);
      expect(
        reloaded!.userTrainingPlans.single.exercises.single.exerciseId,
        'builtin-burpee',
      );
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
