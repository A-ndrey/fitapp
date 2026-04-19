import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem tomato() => const FoodItem(
  id: 'tomato',
  name: 'Tomato',
  description: 'Fresh tomato',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
);

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

  test('creates training plans with existing exercises', () {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: ['Chest', 'Triceps'],
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
        muscleGroups: ['Chest', 'Triceps'],
      ),
    );

    store.updateExercise(
      const Exercise(
        id: 'pushups',
        name: 'Incline pushups',
        description: 'Updated push exercise',
        instruction: 'Use a bench and keep a rigid plank.',
        muscleGroups: ['Chest'],
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
        muscleGroups: ['Chest', 'Triceps'],
      ),
    );

    expect(
      () => store.updateExercise(
        const Exercise(
          id: '',
          name: 'Broken',
          description: 'Broken',
          instruction: 'Broken',
          muscleGroups: ['Chest'],
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
          muscleGroups: ['Chest'],
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
        muscleGroups: ['Core'],
      ),
      const Exercise(
        id: 'missing-instruction',
        name: 'Missing instruction',
        description: 'Core work',
        instruction: '',
        muscleGroups: ['Core'],
      ),
      const Exercise(
        id: 'missing-muscles',
        name: 'Missing muscles',
        description: 'Core work',
        instruction: 'Do the movement.',
        muscleGroups: [],
      ),
      const Exercise(
        id: 'blank-muscle',
        name: 'Blank muscle',
        description: 'Core work',
        instruction: 'Do the movement.',
        muscleGroups: ['Core', ''],
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
        muscleGroups: ['Chest', 'Triceps'],
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
        muscleGroups: ['Chest', 'Triceps'],
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
        muscleGroups: ['Chest', 'Triceps'],
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
        muscleGroups: ['Chest'],
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
        muscleGroups: ['Chest', 'Triceps'],
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
        muscleGroups: ['Chest'],
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
        muscleGroups: ['Chest'],
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
    final store = AppStore();

    final session = store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.updateTrainingPlan(
      store.trainingPlanById('chest-day')!.copyWith(name: 'Changed chest day'),
    );

    expect(session.trainingPlanName, 'Chest day');
    expect(session.results.first.exerciseName, 'Bench press');
    expect(session.results.first.target.weight, 60);
    expect(store.activeWorkoutSession!.trainingPlanName, 'Chest day');
    expect(
      () => store.startWorkout(
        trainingPlanId: 'leg-day',
        startedAt: DateTime(2026, 4, 19, 11),
      ),
      throwsStateError,
    );
    expect(() => store.deleteTrainingPlan('chest-day'), throwsStateError);
  });

  test('updates active workout results and finishes with stats', () {
    final store = AppStore();

    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.updateActiveWorkoutResult(
      resultIndex: 0,
      actualSets: 3,
      actualReps: 8,
      actualWeight: 62.5,
      actualTime: null,
      actualUnit: 'kg',
    );

    expect(store.activeWorkoutSession!.results.first.actualWeight, 62.5);
    expect(
      () => store.updateActiveWorkoutResult(
        resultIndex: 0,
        actualSets: double.infinity,
        actualReps: 8,
        actualWeight: 62.5,
        actualTime: null,
        actualUnit: 'kg',
      ),
      throwsArgumentError,
    );

    final finished = store.finishActiveWorkout(
      finishedAt: DateTime(2026, 4, 19, 10, 45),
    );

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions.single.id, finished.id);
    expect(finished.finishedAt, DateTime(2026, 4, 19, 10, 45));
    expect(store.workoutStats.completedCount, 1);
    expect(store.workoutStats.totalDuration, const Duration(minutes: 45));
    expect(store.workoutStats.latestSession!.trainingPlanName, 'Chest day');
    expect(() => store.finishActiveWorkout(), throwsStateError);
  });

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
}
