import 'dart:convert';

import 'package:fitapp/state/persistence/persisted_app_state.dart';
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
