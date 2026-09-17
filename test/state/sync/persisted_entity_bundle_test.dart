import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/meal_entry.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entity decode restores chronological history instead of ID order', () {
    final oldMeal = _mealEntry('z-old-meal', DateTime.utc(2026, 5, 16));
    final newMeal = _mealEntry('a-new-meal', DateTime.utc(2026, 5, 18));
    final oldWorkout = _workoutSession(
      'z-old-workout',
      DateTime.utc(2026, 5, 14, 9),
    );
    final newWorkout = _workoutSession(
      'a-new-workout',
      DateTime.utc(2026, 5, 17, 9),
    );
    final state = PersistedEntityBundle.decode({
      'mealEntries/${newMeal.id}': PersistedAppStateCodec.encodeMealEntry(
        newMeal,
      ),
      'mealEntries/${oldMeal.id}': PersistedAppStateCodec.encodeMealEntry(
        oldMeal,
      ),
      'workoutSessions/${newWorkout.id}':
          PersistedAppStateCodec.encodeWorkoutSession(newWorkout),
      'workoutSessions/${oldWorkout.id}':
          PersistedAppStateCodec.encodeWorkoutSession(oldWorkout),
    });

    expect(state.mealEntries.map((entry) => entry.id), [
      'z-old-meal',
      'a-new-meal',
    ]);
    expect(state.completedWorkoutSessions.map((session) => session.id), [
      'z-old-workout',
      'a-new-workout',
    ]);
  });

  test('entity merge preserves chronological history instead of ID order', () {
    final local = _stateWithHistory(
      meal: _mealEntry('z-old-meal', DateTime.utc(2026, 5, 16)),
      workout: _workoutSession('z-old-workout', DateTime.utc(2026, 5, 14, 9)),
    );
    final remote = _stateWithHistory(
      meal: _mealEntry('a-new-meal', DateTime.utc(2026, 5, 18)),
      workout: _workoutSession('a-new-workout', DateTime.utc(2026, 5, 17, 9)),
    );

    final merged = PersistedEntityBundle.merge(
      local,
      remote,
      preferRemote: true,
    );

    expect(merged.mealEntries.map((entry) => entry.id), [
      'z-old-meal',
      'a-new-meal',
    ]);
    expect(merged.completedWorkoutSessions.map((session) => session.id), [
      'z-old-workout',
      'a-new-workout',
    ]);
  });
}

PersistedAppState _stateWithHistory({
  required MealEntry meal,
  required WorkoutSession workout,
}) {
  return PersistedAppState(
    userFoods: const [],
    userDishes: const [],
    userExercises: const [],
    userTrainingPlans: const [],
    mealEntries: [meal],
    preferences: const AppPreferences.defaults(),
    activeWorkoutSession: null,
    completedWorkoutSessions: [workout],
    mealEntryCounter: 0,
    workoutSessionCounter: 0,
  );
}

MealEntry _mealEntry(String id, DateTime loggedAt) {
  return MealEntry(
    id: id,
    sourceItemId: 'food',
    itemName: 'Food',
    itemType: CatalogItemType.food,
    servingSizeGrams: 100,
    consumedGrams: 100,
    mode: MealEntryMode.grams,
    enteredQuantity: 100,
    loggedAt: loggedAt,
    nutrition: NutritionValues.zero,
  );
}

WorkoutSession _workoutSession(String id, DateTime startedAt) {
  return WorkoutSession(
    id: id,
    trainingPlanId: 'plan',
    trainingPlanName: 'Plan',
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 1)),
    results: const [],
  );
}
