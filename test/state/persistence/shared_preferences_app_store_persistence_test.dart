import 'dart:convert';

import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/shared_preferences_app_store_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    'SharedPreferencesAppStorePersistence forwards knownExerciseIds to decode',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppStorePersistence.storageKey: jsonEncode({
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
                  'exerciseId': 'builtin-burpee',
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
        }),
      });

      final persistence = SharedPreferencesAppStorePersistence(
        knownExerciseIds: const {'builtin-burpee'},
      );

      final reloaded = await persistence.load();

      expect(reloaded, isNotNull);
      expect(
        reloaded!.userTrainingPlans.single.exercises.single.exerciseId,
        'builtin-burpee',
      );
    },
  );
}
