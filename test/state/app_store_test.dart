import 'dart:async';

import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/meal_entry.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem tomato() => const FoodItem(
  id: 'tomato',
  name: 'Tomato',
  description: 'Fresh tomato',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
);

FoodItem cucumber() => tomato().copyWith(
  id: 'cucumber',
  name: 'Cucumber',
  description: 'Fresh cucumber',
);

class FakePersistence implements AppStorePersistence {
  FakePersistence({this.loadedState});

  PersistedAppState? loadedState;
  PersistedAppState? savedState;
  int saveCount = 0;

  @override
  Future<PersistedAppState?> load() async => loadedState;

  @override
  Future<void> save(PersistedAppState state) async {
    saveCount += 1;
    savedState = state;
    loadedState = state;
  }
}

class DecodingPersistence implements AppStorePersistence {
  DecodingPersistence({
    required this.encodedState,
    this.knownExerciseIds = const {},
  });

  final Object encodedState;
  final Set<String> knownExerciseIds;

  @override
  Future<PersistedAppState?> load() async {
    return PersistedAppStateCodec.decode(
      encodedState,
      knownExerciseIds: knownExerciseIds,
    );
  }

  @override
  Future<void> save(PersistedAppState state) async {}
}

class FlakyPersistence extends FakePersistence {
  FlakyPersistence({required this.failuresRemaining});

  int failuresRemaining;

  @override
  Future<void> save(PersistedAppState state) async {
    saveCount += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('Failed to persist app store state.');
    }
    savedState = state;
    loadedState = state;
  }
}

class DeferredPersistence extends FakePersistence {
  Completer<void> _saveCompleter = Completer<void>();

  @override
  Future<void> save(PersistedAppState state) async {
    saveCount += 1;
    savedState = state;
    loadedState = state;
    await _saveCompleter.future;
    _saveCompleter = Completer<void>();
  }

  void completeSave() {
    if (_saveCompleter.isCompleted) {
      return;
    }
    _saveCompleter.complete();
  }
}

Future<void> flushPersistenceQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('AppStore starts with exactly five sample foods', () {
    final store = AppStore();

    expect(store.items, hasLength(5));
    expect(store.searchItems('chicken').single.name, 'Chicken breast');
  });

  test('AppStore starts with sample exercises and training plans', () {
    final store = AppStore();

    expect(store.exercises, hasLength(greaterThanOrEqualTo(5)));
    expect(store.searchExercises('push').single.name, 'Pushups');
    expect(store.searchExercises('cardio'), isNotEmpty);
    expect(store.searchExercises('legs'), isNotEmpty);
    expect(
      store.exerciseById('pushups')!.muscleGroups,
      contains(MuscleGroup.chest),
    );
    expect(store.trainingPlans, hasLength(greaterThanOrEqualTo(2)));
    expect(store.trainingPlans.any((plan) => plan.name == 'Chest day'), isTrue);
  });

  test('AppStore.empty starts without exercises or training plans', () {
    final store = AppStore.empty();

    expect(store.exercises, isEmpty);
    expect(store.trainingPlans, isEmpty);
    expect(store.completedWorkoutSessions, isEmpty);
    expect(store.activeWorkoutSession, isNull);
  });

  test(
    'AppStore.hydrated merges built-ins with persisted user state',
    () async {
      final persistence = FakePersistence(
        loadedState: PersistedAppState(
          userFoods: [tomato()],
          userDishes: const [],
          userExercises: const [],
          userTrainingPlans: const [],
          mealEntries: const [],
          preferences: const AppPreferences.defaults(),
          activeWorkoutSession: null,
          completedWorkoutSessions: const [],
          mealEntryCounter: 0,
          workoutSessionCounter: 0,
        ),
      );

      final store = await AppStore.hydrated(persistence: persistence);

      expect(store.items, hasLength(6));
      expect(store.itemById('carrot'), isNotNull);
      expect(store.itemById('tomato'), isNotNull);
    },
  );

  test(
    'AppStore.hydrated relies on persistence decode for built-in exercise references',
    () async {
      final persistedState = PersistedAppState(
        userFoods: const [],
        userDishes: const [],
        userExercises: const [],
        userTrainingPlans: const [
          TrainingPlan(
            id: 'builtin-pushups-plan',
            name: 'Builtin pushups plan',
            description: 'References a built-in exercise.',
            exercises: [
              TrainingExercise(exerciseId: 'pushups', reps: 15, unit: 'reps'),
            ],
          ),
        ],
        mealEntries: const [],
        preferences: const AppPreferences.defaults(),
        activeWorkoutSession: null,
        completedWorkoutSessions: const [],
        mealEntryCounter: 0,
        workoutSessionCounter: 0,
      );
      final persistence = DecodingPersistence(
        encodedState: PersistedAppStateCodec.encode(persistedState),
        knownExerciseIds: const {'pushups'},
      );

      final store = await AppStore.hydrated(persistence: persistence);

      expect(store.trainingPlanById('builtin-pushups-plan'), isNotNull);
    },
  );

  test('AppStore persists after persisted-state mutations only', () async {
    final persistence = FakePersistence();
    final store = AppStore.empty(persistence: persistence);

    store.createFood(tomato());
    await flushPersistenceQueue();

    expect(persistence.saveCount, 1);
    expect(persistence.savedState!.userFoods.single.id, 'tomato');

    store.logIn();
    await flushPersistenceQueue();

    expect(persistence.saveCount, 1);
    expect(persistence.savedState!.userFoods.single.id, 'tomato');
  });

  test(
    'AppStore post-save observer runs only after durable persisted mutations',
    () async {
      final persistence = DeferredPersistence();
      final observedStates = <PersistedAppState>[];
      final store = AppStore.empty(
        persistence: persistence,
        onPersistedStateSaved: observedStates.add,
      );

      store.createFood(tomato());
      await Future<void>.delayed(Duration.zero);

      expect(persistence.saveCount, 1);
      expect(observedStates, isEmpty);

      persistence.completeSave();
      await flushPersistenceQueue();

      expect(observedStates, hasLength(1));
      expect(observedStates.single.userFoods.single.id, 'tomato');

      store.createFood(cucumber());
      await Future<void>.delayed(Duration.zero);

      expect(observedStates, hasLength(1));

      persistence.completeSave();
      await flushPersistenceQueue();

      expect(observedStates, hasLength(2));
      expect(observedStates.last.userFoods.map((food) => food.id).toList(), [
        'tomato',
        'cucumber',
      ]);
    },
  );

  test(
    'AppStore post-save observer is not fired for transient auth changes',
    () async {
      final persistence = FakePersistence();
      final observedStates = <PersistedAppState>[];
      final store = AppStore.empty(
        persistence: persistence,
        onPersistedStateSaved: observedStates.add,
      );

      store.logIn();
      store.logOut();
      await flushPersistenceQueue();

      expect(persistence.saveCount, 0);
      expect(observedStates, isEmpty);
    },
  );

  test('AppStore does not persist auth flag', () async {
    final persistence = FakePersistence();
    final store = AppStore.empty(persistence: persistence);

    store.createFood(tomato());
    store.logIn();
    await flushPersistenceQueue();

    expect(store.isLoggedIn, isTrue);
    expect(persistence.savedState, isNotNull);

    final restored = await AppStore.hydrated(persistence: persistence);

    expect(restored.itemById('tomato'), isNotNull);
    expect(restored.isLoggedIn, isFalse);
  });

  test('built-in records cannot be mutated or deleted', () {
    final store = AppStore();

    expect(
      () => store.updateFood(
        const FoodItem(
          id: 'carrot',
          name: 'Updated carrot',
          description: 'Updated built-in food',
          servingSizeGrams: 100,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: 50,
            protein: 1,
            fat: 0.2,
            carbs: 11,
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(() => store.deleteItem('carrot'), throwsStateError);
    expect(
      () => store.updateExercise(
        const Exercise(
          id: 'pushups',
          name: 'Updated pushups',
          description: 'Updated built-in exercise',
          instruction: 'Updated built-in instruction.',
          muscleGroups: [MuscleGroup.chest],
        ),
      ),
      throwsArgumentError,
    );
    expect(() => store.deleteExercise('pushups'), throwsStateError);
    expect(
      () => store.updateTrainingPlan(
        const TrainingPlan(
          id: 'chest-day',
          name: 'Updated chest day',
          description: 'Updated built-in plan',
          exercises: [
            TrainingExercise(
              exerciseId: 'bench-press',
              sets: 3,
              reps: 8,
              weight: 60,
              unit: 'kg',
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(() => store.deleteTrainingPlan('chest-day'), throwsStateError);
  });

  test(
    'applying an external snapshot replaces persisted state and re-persists it',
    () async {
      final persistence = FakePersistence();
      final observedStates = <PersistedAppState>[];
      final store = AppStore(
        persistence: persistence,
        onPersistedStateSaved: observedStates.add,
      );
      var listenerNotifications = 0;
      store.addListener(() {
        listenerNotifications += 1;
      });

      store.createFood(tomato());
      store.setAppearancePreference(AppearancePreference.dark);
      await flushPersistenceQueue();

      listenerNotifications = 0;
      observedStates.clear();

      final externalSnapshot = PersistedAppState(
        userFoods: [cucumber()],
        userDishes: const [],
        userExercises: const [],
        userTrainingPlans: const [
          TrainingPlan(
            id: 'remote-plan',
            name: 'Remote plan',
            description: 'References a built-in exercise.',
            exercises: [
              TrainingExercise(
                exerciseId: 'pushups',
                sets: 4,
                reps: 10,
                unit: 'reps',
              ),
            ],
          ),
        ],
        mealEntries: const [
          MealEntry(
            id: 'meal-entry-8',
            sourceItemId: 'cucumber',
            itemName: 'Cucumber',
            itemType: CatalogItemType.food,
            servingSizeGrams: 100,
            consumedGrams: 150,
            mode: MealEntryMode.grams,
            enteredQuantity: 150,
            nutrition: NutritionValues(
              calories: 18,
              protein: 0.9,
              fat: 0.2,
              carbs: 3.9,
            ),
          ),
        ],
        preferences: const AppPreferences(
          appearance: AppearancePreference.light,
          language: LanguagePreference.english,
          workoutWeightUnit: WorkoutWeightUnit.kilograms,
          dishWeightUnit: DishWeightUnit.grams,
          heightUnit: HeightUnit.centimeters,
          distanceUnit: DistanceUnit.kilometers,
        ),
        activeWorkoutSession: WorkoutSession(
          id: 'workout-session-4',
          trainingPlanId: 'chest-day',
          trainingPlanName: 'Chest day',
          startedAt: DateTime(2026, 4, 20, 10),
          results: const [
            WorkoutExerciseResult(
              exerciseId: 'bench-press',
              exerciseName: 'Bench press',
              target: TrainingExercise(
                exerciseId: 'bench-press',
                sets: 3,
                reps: 8,
                weight: 60,
                unit: 'kg',
              ),
              setLogs: [WorkoutSetLog(reps: 8, weight: 60)],
            ),
          ],
        ),
        completedWorkoutSessions: const [],
        mealEntryCounter: 8,
        workoutSessionCounter: 4,
      );

      await store.applyExternalPersistedState(externalSnapshot);

      expect(listenerNotifications, 1);
      expect(store.itemById('carrot'), isNotNull);
      expect(store.exerciseById('pushups'), isNotNull);
      expect(store.trainingPlanById('chest-day'), isNotNull);
      expect(store.itemById('tomato'), isNull);
      expect(store.itemById('cucumber'), isNotNull);
      expect(store.trainingPlanById('remote-plan'), isNotNull);
      expect(store.mealEntries.single.id, 'meal-entry-8');
      expect(store.preferences.appearance, AppearancePreference.light);
      expect(store.activeWorkoutSession!.id, 'workout-session-4');
      expect(observedStates, hasLength(1));
      expect(persistence.saveCount, 3);
      expect(persistence.savedState!.userFoods.single.id, 'cucumber');
      expect(
        persistence
            .savedState!
            .userTrainingPlans
            .single
            .exercises
            .single
            .exerciseId,
        'pushups',
      );
    },
  );

  test(
    'applying an external snapshot can suppress the post-save observer',
    () async {
      final persistence = FakePersistence();
      final observedStates = <PersistedAppState>[];
      final store = AppStore.empty(
        persistence: persistence,
        onPersistedStateSaved: observedStates.add,
      );
      final externalSnapshot = PersistedAppState(
        userFoods: [cucumber()],
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

      await store.applyExternalPersistedState(
        externalSnapshot,
        notifyPersistedStateObserver: false,
      );

      expect(observedStates, isEmpty);
      expect(persistence.saveCount, 1);
      expect(persistence.savedState!.userFoods.single.id, 'cucumber');
    },
  );

  test(
    'save failures are reported and later callbacks still succeed',
    () async {
      final persistence = FlakyPersistence(failuresRemaining: 1);
      final observedStates = <PersistedAppState>[];
      final store = AppStore.empty(
        persistence: persistence,
        onPersistedStateSaved: observedStates.add,
      );
      final originalOnError = FlutterError.onError;
      final reportedErrors = <FlutterErrorDetails>[];
      FlutterError.onError = reportedErrors.add;
      addTearDown(() {
        FlutterError.onError = originalOnError;
      });

      store.createFood(tomato());
      await flushPersistenceQueue();

      expect(persistence.saveCount, 1);
      expect(reportedErrors, hasLength(1));
      expect(persistence.savedState, isNull);
      expect(observedStates, isEmpty);

      store.createFood(cucumber());
      await flushPersistenceQueue();

      expect(persistence.saveCount, 2);
      expect(reportedErrors, hasLength(1));
      expect(observedStates, hasLength(1));
      expect(observedStates.single.userFoods.map((food) => food.id).toList(), [
        'tomato',
        'cucumber',
      ]);
      expect(
        persistence.savedState!.userFoods.map((food) => food.id).toList(),
        ['tomato', 'cucumber'],
      );
    },
  );

  test('AppStore.hydrated restores counters and runtime state', () async {
    final persistence = FakePersistence(
      loadedState: PersistedAppState(
        userFoods: [tomato()],
        userDishes: const [],
        userExercises: const [],
        userTrainingPlans: const [],
        mealEntries: const [
          MealEntry(
            id: 'meal-entry-2',
            sourceItemId: 'tomato',
            itemName: 'Tomato',
            itemType: CatalogItemType.food,
            servingSizeGrams: 100,
            consumedGrams: 100,
            mode: MealEntryMode.grams,
            enteredQuantity: 100,
            nutrition: NutritionValues(
              calories: 18,
              protein: 0.9,
              fat: 0.2,
              carbs: 3.9,
            ),
          ),
        ],
        preferences: const AppPreferences(
          appearance: AppearancePreference.dark,
          language: LanguagePreference.english,
          workoutWeightUnit: WorkoutWeightUnit.pounds,
          dishWeightUnit: DishWeightUnit.ounces,
          heightUnit: HeightUnit.inches,
          distanceUnit: DistanceUnit.miles,
        ),
        activeWorkoutSession: WorkoutSession(
          id: 'workout-session-3',
          trainingPlanId: 'chest-day',
          trainingPlanName: 'Chest day',
          startedAt: DateTime(2026, 4, 19, 10),
          results: const [
            WorkoutExerciseResult(
              exerciseId: 'bench-press',
              exerciseName: 'Bench press',
              target: TrainingExercise(
                exerciseId: 'bench-press',
                sets: 3,
                reps: 8,
                weight: 60,
                unit: 'kg',
              ),
              setLogs: [WorkoutSetLog(reps: 8, weight: 60)],
            ),
          ],
        ),
        completedWorkoutSessions: [
          WorkoutSession(
            id: 'workout-session-2',
            trainingPlanId: 'leg-day',
            trainingPlanName: 'Leg day',
            startedAt: DateTime(2026, 4, 18, 9),
            finishedAt: DateTime(2026, 4, 18, 9, 45),
            results: [
              WorkoutExerciseResult(
                exerciseId: 'squat',
                exerciseName: 'Squat',
                target: TrainingExercise(
                  exerciseId: 'squat',
                  sets: 4,
                  reps: 6,
                  weight: 80,
                  unit: 'kg',
                ),
                setLogs: [WorkoutSetLog(reps: 6, weight: 80)],
              ),
            ],
          ),
        ],
        mealEntryCounter: 2,
        workoutSessionCounter: 3,
      ),
    );

    final store = await AppStore.hydrated(persistence: persistence);
    final nextMeal = store.addMealByGrams(itemId: 'tomato', grams: 50);

    expect(store.preferences.appearance, AppearancePreference.dark);
    expect(store.activeWorkoutSession!.id, 'workout-session-3');
    expect(store.completedWorkoutSessions.single.id, 'workout-session-2');
    expect(nextMeal.id, 'meal-entry-3');
    expect(
      () => store.startWorkout(
        trainingPlanId: 'chest-day',
        startedAt: DateTime(2026, 4, 19, 11),
      ),
      throwsStateError,
    );

    final finished = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 19, 10, 30),
    );
    final newSession = store.startWorkout(
      trainingPlanId: 'leg-day',
      startedAt: DateTime(2026, 4, 20, 10),
    );

    expect(finished.id, 'workout-session-3');
    expect(newSession.id, 'workout-session-4');
  });

  test('creates training plans with existing exercises', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );

    store.createTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Home chest',
        description: 'Bodyweight chest work',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 3,
            reps: 12,
            unit: 'reps',
          ),
        ],
      ),
    );

    expect(store.trainingPlans.single.name, 'Home chest');
    expect(store.trainingPlanById('home-chest')!.exercises.single.reps, 12);
  });

  test('updates exercises by id', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );

    store.updateExercise(
      const Exercise(
        id: 'pushups',
        name: 'Incline pushups',
        description: 'Updated push exercise',
        instruction: 'Use a bench and keep a rigid plank.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );

    expect(store.exerciseById('pushups')!.name, 'Incline pushups');
    expect(store.exerciseById('pushups')!.description, 'Updated push exercise');
  });

  test('rejects invalid exercise updates', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );

    expect(
      () => store.updateExercise(
        const Exercise(
          id: '',
          name: 'Broken',
          description: 'Broken',
          instruction: 'Broken',
          muscleGroups: [MuscleGroup.chest],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.updateExercise(
        const Exercise(
          id: 'missing',
          name: 'Missing',
          description: 'Missing',
          instruction: 'Missing',
          muscleGroups: [MuscleGroup.chest],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects exercises with incomplete metadata', () {
    final store = AppStore.empty();

    for (final exercise in [
      const Exercise(
        id: 'missing-description',
        name: 'Missing description',
        description: '',
        instruction: 'Do the movement.',
        muscleGroups: [MuscleGroup.core],
      ),
      const Exercise(
        id: 'missing-instruction',
        name: 'Missing instruction',
        description: 'Core work',
        instruction: '',
        muscleGroups: [MuscleGroup.core],
      ),
      const Exercise(
        id: 'missing-muscles',
        name: 'Missing muscles',
        description: 'Core work',
        instruction: 'Do the movement.',
        muscleGroups: [],
      ),
    ]) {
      expect(() => store.createExercise(exercise), throwsArgumentError);
    }
  });

  test('deletes exercises when no training plan references them', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );

    expect(() => store.deleteExercise('missing'), throwsArgumentError);
    store.deleteExercise('pushups');

    expect(store.exerciseById('pushups'), isNull);
    expect(store.exercises, isEmpty);
  });

  test('rejects deleting exercises referenced by training plans', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Home chest',
        description: 'Bodyweight chest work',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 3,
            reps: 12,
            unit: 'reps',
          ),
        ],
      ),
    );

    expect(() => store.deleteExercise('pushups'), throwsStateError);
  });

  test('updating exercises changes future workout snapshots only', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Home chest',
        description: 'Bodyweight chest work',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 3,
            reps: 12,
            unit: 'reps',
          ),
        ],
      ),
    );

    final firstSession = store.startWorkout(
      trainingPlanId: 'home-chest',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 30));

    store.updateExercise(
      const Exercise(
        id: 'pushups',
        name: 'Incline pushups',
        description: 'Updated push exercise',
        instruction: 'Use a bench and keep a rigid plank.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );

    final secondSession = store.startWorkout(
      trainingPlanId: 'home-chest',
      startedAt: DateTime(2026, 4, 19, 11),
    );

    expect(firstSession.results.first.exerciseName, 'Pushups');
    expect(secondSession.results.first.exerciseName, 'Incline pushups');
  });

  test('deleting exercises after workout history is retained is allowed', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Home chest',
        description: 'Bodyweight chest work',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 3,
            reps: 12,
            unit: 'reps',
          ),
        ],
      ),
    );

    final session = store.startWorkout(
      trainingPlanId: 'home-chest',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 30));
    store.deleteTrainingPlan('home-chest');
    store.deleteExercise('pushups');

    expect(store.exerciseById('pushups'), isNull);
    expect(session.results.first.exerciseName, 'Pushups');
    expect(
      store.completedWorkoutSessions.single.results.first.exerciseName,
      'Pushups',
    );
  });

  test('updates and deletes training plans', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Home chest',
        description: 'Bodyweight chest work',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 3,
            reps: 12,
            unit: 'reps',
          ),
        ],
      ),
    );

    store.updateTrainingPlan(
      const TrainingPlan(
        id: 'home-chest',
        name: 'Push day',
        description: 'Updated',
        exercises: [
          TrainingExercise(
            exerciseId: 'pushups',
            sets: 4,
            reps: 10,
            unit: 'reps',
          ),
        ],
      ),
    );

    expect(store.trainingPlanById('home-chest')!.name, 'Push day');
    expect(store.trainingPlanById('home-chest')!.exercises.single.sets, 4);

    store.deleteTrainingPlan('home-chest');

    expect(store.trainingPlans, isEmpty);
  });

  test('rejects invalid training plans', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );
    const validPlan = TrainingPlan(
      id: 'home-chest',
      name: 'Home chest',
      description: 'Bodyweight chest work',
      exercises: [
        TrainingExercise(
          exerciseId: 'pushups',
          sets: 3,
          reps: 12,
          unit: 'reps',
        ),
      ],
    );
    store.createTrainingPlan(validPlan);

    expect(() => store.createTrainingPlan(validPlan), throwsArgumentError);
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(id: '', name: 'Missing id'),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(id: 'missing-name', name: ''),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(id: 'empty', exercises: []),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(
          id: 'missing-exercise',
          exercises: [
            const TrainingExercise(
              exerciseId: 'missing',
              reps: 10,
              unit: 'reps',
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(
          id: 'bad-number',
          exercises: [
            const TrainingExercise(
              exerciseId: 'pushups',
              reps: double.nan,
              unit: 'reps',
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(
          id: 'negative',
          exercises: [
            const TrainingExercise(
              exerciseId: 'pushups',
              reps: -1,
              unit: 'reps',
            ),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.createTrainingPlan(
        validPlan.copyWith(
          id: 'blank-unit',
          exercises: [
            const TrainingExercise(exerciseId: 'pushups', reps: 10, unit: ''),
          ],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.updateTrainingPlan(validPlan.copyWith(id: 'missing')),
      throwsArgumentError,
    );
    expect(() => store.deleteTrainingPlan('missing'), throwsArgumentError);
  });

  test('starts one active workout and snapshots plan data', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'bench-press',
        name: 'Bench press',
        description: 'Barbell chest press',
        instruction: 'Keep shoulder blades set and press the bar vertically.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'push-day',
        name: 'Push day',
        description: 'Pressing work',
        exercises: [
          TrainingExercise(
            exerciseId: 'bench-press',
            sets: 3,
            reps: 8,
            weight: 60,
            unit: 'kg',
          ),
        ],
      ),
    );

    final session = store.startWorkout(
      trainingPlanId: 'push-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.updateTrainingPlan(
      store.trainingPlanById('push-day')!.copyWith(name: 'Changed push day'),
    );

    expect(session.trainingPlanName, 'Push day');
    expect(session.results.first.exerciseName, 'Bench press');
    expect(session.results.first.target.weight, 60);
    expect(session.results.first.setLogs, isEmpty);
    expect(store.activeWorkoutSession!.trainingPlanName, 'Push day');
    expect(
      () => store.startWorkout(
        trainingPlanId: 'push-day',
        startedAt: DateTime(2026, 4, 19, 11),
      ),
      throwsStateError,
    );
    expect(() => store.deleteTrainingPlan('push-day'), throwsStateError);
  });

  test('appends multiple set logs to one workout result', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weight: 62.5),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 6, weight: 65),
    );

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(2));
    expect(store.activeWorkoutSession!.results.first.setLogs.first.reps, 8);
    expect(
      store.activeWorkoutSession!.results.first.setLogs.first.weight,
      62.5,
    );
    expect(store.activeWorkoutSession!.results.first.setLogs.last.reps, 6);
    expect(store.activeWorkoutSession!.results.first.setLogs.last.weight, 65);
  });

  test('rejects invalid workout set logs', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    expect(
      () => store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(reps: double.infinity),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(weight: -1),
      ),
      throwsArgumentError,
    );
    expect(
      () => store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(time: double.nan),
      ),
      throwsArgumentError,
    );
  });

  test('finished history preserves workout set logs', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weight: 62.5),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 6, weight: 65),
    );

    final finished = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 19, 10, 45),
    );

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions.single.id, finished.id);
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs,
      hasLength(2),
    );
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs.first.reps,
      8,
    );
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs.last.weight,
      65,
    );
    expect(finished.finishedAt, DateTime(2026, 4, 19, 10, 45));
    expect(store.workoutStats.completedCount, 1);
    expect(store.workoutStats.totalDuration, const Duration(minutes: 45));
    expect(store.workoutStats.latestSession!.trainingPlanName, 'Chest day');
    expect(() => store.finishActiveWorkout(), throwsStateError);
  });

  test('completed workout history returns matching sessions newest first', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    final firstCompleted = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 19, 10, 30),
    );

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 20, 10),
    );
    final secondCompleted = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 20, 10, 45),
    );

    final history = store.completedWorkoutHistoryForExercise('bench-press');

    expect(history, hasLength(2));
    expect(history.first.session.id, secondCompleted.id);
    expect(history.last.session.id, firstCompleted.id);
    expect(history.first.result.exerciseName, 'Bench press');
    expect(history.last.result.exerciseName, 'Bench press');
  });

  test('completed workout history excludes the active workout', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    expect(store.completedWorkoutHistoryForExercise('bench-press'), isEmpty);
  });

  test('completed workout history preserves set logs', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weight: 62.5),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 6, weight: 65),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 45));

    final history = store.completedWorkoutHistoryForExercise('bench-press');

    expect(history, hasLength(1));
    expect(history.single.session.results.first.setLogs, hasLength(2));
    expect(history.single.result.setLogs.first.reps, 8);
    expect(history.single.result.setLogs.first.weight, 62.5);
    expect(history.single.result.setLogs.last.reps, 6);
    expect(history.single.result.setLogs.last.weight, 65);
  });

  test(
    'completed workout history keeps duplicate exercise results grouped',
    () {
      final store = AppStore.empty();
      store.createExercise(
        const Exercise(
          id: 'pushups',
          name: 'Pushups',
          description: 'Bodyweight push exercise',
          instruction: 'Keep a straight line from shoulders to heels.',
          muscleGroups: [MuscleGroup.chest],
        ),
      );
      store.createTrainingPlan(
        const TrainingPlan(
          id: 'repeat-pushups',
          name: 'Repeat pushups',
          description: 'Same exercise twice',
          exercises: [
            TrainingExercise(exerciseId: 'pushups', reps: 10, unit: 'reps'),
            TrainingExercise(exerciseId: 'pushups', reps: 8, unit: 'reps'),
          ],
        ),
      );

      store.startWorkout(
        trainingPlanId: 'repeat-pushups',
        startedAt: DateTime(2026, 4, 19, 10),
      );
      store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(reps: 10),
      );
      store.addActiveWorkoutSet(
        resultIndex: 1,
        setLog: const WorkoutSetLog(reps: 8),
      );
      store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 30));

      final history = store.completedWorkoutHistoryForExercise('pushups');

      expect(history, hasLength(1));
      expect(history.single.results, hasLength(2));
      expect(history.single.results.first.setLogs.single.reps, 10);
      expect(history.single.results.last.setLogs.single.reps, 8);
    },
  );

  test('deletes completed workout sessions by id', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 18, 9),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weight: 62.5),
    );
    final first = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 18, 9, 45),
    );

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    final second = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 19, 10, 30),
    );

    store.deleteCompletedWorkoutSession(first.id);

    expect(store.completedWorkoutSessions, hasLength(1));
    expect(store.completedWorkoutSessions.single.id, second.id);
    expect(store.workoutStats.completedCount, 1);
    expect(
      store.completedWorkoutHistoryForExercise('bench-press'),
      hasLength(1),
    );
    expect(
      () => store.deleteCompletedWorkoutSession(first.id),
      throwsArgumentError,
    );
  });

  test(
    'exercise rename after start does not change active or completed names',
    () {
      final store = AppStore.empty();
      store.createExercise(
        const Exercise(
          id: 'bench-press',
          name: 'Bench press',
          description: 'Barbell chest press',
          instruction: 'Keep shoulder blades set and press the bar vertically.',
          muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        ),
      );
      store.createTrainingPlan(
        const TrainingPlan(
          id: 'push-day',
          name: 'Push day',
          description: 'Pressing work',
          exercises: [
            TrainingExercise(
              exerciseId: 'bench-press',
              sets: 3,
              reps: 8,
              weight: 60,
              unit: 'kg',
            ),
          ],
        ),
      );

      final session = store.startWorkout(
        trainingPlanId: 'push-day',
        startedAt: DateTime(2026, 4, 19, 10),
      );
      store.updateExercise(
        store
            .exerciseById('bench-press')!
            .copyWith(name: 'Changed bench press'),
      );

      expect(session.results.first.exerciseName, 'Bench press');
      expect(
        store.activeWorkoutSession!.results.first.exerciseName,
        'Bench press',
      );

      store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 30));

      expect(
        store.completedWorkoutSessions.single.results.first.exerciseName,
        'Bench press',
      );
    },
  );

  test('AppStore.empty creates food and searches by name or description', () {
    final store = AppStore.empty();

    store.createFood(tomato());

    expect(store.searchItems('tomato').single.id, 'tomato');
    expect(store.searchItems('fresh').single.id, 'tomato');
  });

  test('meal entries store snapshots across food updates', () {
    final store = AppStore.empty();
    store.createFood(tomato());

    final gramsEntry = store.addMealByGrams(itemId: 'tomato', grams: 200);
    final servingsEntry = store.addMealByServings(
      itemId: 'tomato',
      servings: 0.5,
    );

    store.updateFood(
      tomato().copyWith(
        nutrition: const NutritionValues(
          calories: 100,
          protein: 1,
          fat: 1,
          carbs: 1,
        ),
      ),
    );

    expect(gramsEntry.itemName, 'Tomato');
    expect(gramsEntry.nutrition.calories, 36);
    expect(servingsEntry.itemName, 'Tomato');
    expect(servingsEntry.nutrition.calories, 9);
    expect(store.dailyTotals.calories, 45);
  });

  test('updating a dish id with an existing food id is rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      () => store.updateDish(
        const DishItem(
          id: 'tomato',
          name: 'Tomato salad',
          description: 'Wrong type',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'tomato', grams: 100)],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('updating a food id with an existing dish id is rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      () => store.updateFood(
        const FoodItem(
          id: 'salad',
          name: 'Salad',
          description: 'Wrong type',
          servingSizeGrams: 100,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: 10,
            protein: 1,
            fat: 1,
            carbs: 1,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('dish nutrition is live and deleting referenced food is blocked', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      store.itemById('salad')!.nutritionPerServing(store.catalog).calories,
      18,
    );
    expect(() => store.deleteItem('tomato'), throwsStateError);
  });

  test('deleting items used only by meal snapshots is allowed', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.addMealByGrams(itemId: 'tomato', grams: 100);

    store.deleteItem('tomato');

    expect(store.itemById('tomato'), isNull);
    expect(store.mealEntries.single.itemName, 'Tomato');
    expect(store.dailyTotals.calories, 18);
  });

  test('dish cycles are rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());

    expect(
      () => store.createDish(
        const DishItem(
          id: 'bad',
          name: 'Bad',
          description: 'Bad dish',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'bad', grams: 100)],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    store.createDish(
      const DishItem(
        id: 'base',
        name: 'Base',
        description: 'Base dish',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );
    store.createDish(
      const DishItem(
        id: 'wrapper',
        name: 'Wrapper',
        description: 'Wrapper dish',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'base', grams: 100)],
      ),
    );

    expect(
      () => store.updateDish(
        const DishItem(
          id: 'base',
          name: 'Base',
          description: 'Base dish',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'wrapper', grams: 100)],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'stored dishes are isolated from caller-side component list mutation',
    () {
      final store = AppStore.empty();
      store.createFood(tomato());
      final components = <DishComponent>[
        const DishComponent(itemId: 'tomato', grams: 100),
      ];

      store.createDish(
        DishItem(
          id: 'salad',
          name: 'Salad',
          description: 'Tomato salad',
          servingSizeGrams: 100,
          components: components,
        ),
      );

      components.clear();
      components.add(const DishComponent(itemId: 'missing', grams: 50));

      expect(
        store.itemById('salad')!.nutritionPerServing(store.catalog).calories,
        18,
      );
      expect(() => store.deleteItem('tomato'), throwsStateError);
    },
  );

  test('rejects non-finite numeric values', () {
    final store = AppStore.empty();

    expect(
      () => store.createFood(
        const FoodItem(
          id: 'bad-food',
          name: 'Bad food',
          description: 'Bad',
          servingSizeGrams: 100,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: double.nan,
            protein: 1,
            fat: 1,
            carbs: 1,
          ),
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => store.createFood(
        const FoodItem(
          id: 'bad-serving',
          name: 'Bad serving',
          description: 'Bad',
          servingSizeGrams: double.infinity,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(calories: 1, protein: 1, fat: 1, carbs: 1),
        ),
      ),
      throwsArgumentError,
    );

    store.createFood(tomato());

    expect(
      () => store.createDish(
        const DishItem(
          id: 'bad-dish',
          name: 'Bad dish',
          description: 'Bad',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'tomato', grams: double.nan)],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => store.addMealByGrams(itemId: 'tomato', grams: double.infinity),
      throwsArgumentError,
    );
    expect(
      () => store.addMealByServings(itemId: 'tomato', servings: double.nan),
      throwsArgumentError,
    );
  });

  test('AppStore exposes metric English defaults for preferences', () {
    final store = AppStore.empty();

    expect(
      store.preferences,
      const AppPreferences(
        appearance: AppearancePreference.system,
        language: LanguagePreference.english,
        workoutWeightUnit: WorkoutWeightUnit.kilograms,
        dishWeightUnit: DishWeightUnit.grams,
        heightUnit: HeightUnit.centimeters,
        distanceUnit: DistanceUnit.kilometers,
      ),
    );
    expect(store.appearancePreference, AppearancePreference.system);
    expect(store.languagePreference, LanguagePreference.english);
    expect(store.workoutWeightUnit, WorkoutWeightUnit.kilograms);
    expect(store.dishWeightUnit, DishWeightUnit.grams);
    expect(store.heightUnit, HeightUnit.centimeters);
    expect(store.distanceUnit, DistanceUnit.kilometers);
  });

  test('preference setters update state and notify listeners', () {
    final store = AppStore.empty();
    var notifications = 0;
    store.addListener(() {
      notifications++;
    });

    store.setAppearancePreference(AppearancePreference.dark);
    store.setLanguagePreference(LanguagePreference.english);
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);
    store.setDishWeightUnit(DishWeightUnit.ounces);
    store.setHeightUnit(HeightUnit.inches);
    store.setDistanceUnit(DistanceUnit.miles);

    expect(
      store.preferences,
      const AppPreferences(
        appearance: AppearancePreference.dark,
        language: LanguagePreference.english,
        workoutWeightUnit: WorkoutWeightUnit.pounds,
        dishWeightUnit: DishWeightUnit.ounces,
        heightUnit: HeightUnit.inches,
        distanceUnit: DistanceUnit.miles,
      ),
    );
    expect(notifications, 6);
  });

  test('formatting helpers convert canonical values into display units', () {
    final store = AppStore.empty();

    expect(store.formatWorkoutWeight(60), '60 kg');
    expect(store.formatDishWeight(100), '100 g');
    expect(store.formatHeight(180), '180 cm');
    expect(store.formatDistance(5), '5 km');

    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);
    store.setDishWeightUnit(DishWeightUnit.ounces);
    store.setHeightUnit(HeightUnit.inches);
    store.setDistanceUnit(DistanceUnit.miles);

    expect(store.formatWorkoutWeight(100), '220.5 lbs');
    expect(store.formatDishWeight(100), '3.5 oz');
    expect(store.formatHeight(180), '70.9 in');
    expect(store.formatDistance(5), '3.1 miles');
  });

  test('login state toggles in memory and notifies listeners', () {
    final store = AppStore.empty();
    var notifications = 0;
    store.addListener(() {
      notifications++;
    });

    expect(store.isLoggedIn, isFalse);

    store.logIn();
    expect(store.isLoggedIn, isTrue);

    store.logOut();
    expect(store.isLoggedIn, isFalse);
    expect(notifications, 2);
  });
}
