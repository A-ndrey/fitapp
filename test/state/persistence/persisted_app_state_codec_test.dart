import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/meal_entry.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PersistedAppState codec round-trips runtime and user data', () {
    final state = PersistedAppState(
      userFoods: const [
        FoodItem(
          id: 'oats',
          name: 'Oats',
          description: 'Dry oats',
          servingSizeGrams: 40,
          basis: NutritionBasis.perServing,
          nutrition: NutritionValues(
            calories: 150,
            protein: 5,
            fat: 3,
            carbs: 27,
          ),
        ),
      ],
      userDishes: const [
        DishItem(
          id: 'oats-bowl',
          name: 'Oats Bowl',
          description: 'Oats with water',
          servingSizeGrams: 250,
          components: const [DishComponent(itemId: 'oats', grams: 40)],
        ),
      ],
      userExercises: const [
        Exercise(
          id: 'burpees',
          name: 'Burpees',
          description: 'Conditioning move',
          instruction: 'Keep pace steady.',
          muscleGroups: const [MuscleGroup.cardio, MuscleGroup.fullBody],
        ),
      ],
      userTrainingPlans: const [
        TrainingPlan(
          id: 'conditioning',
          name: 'Conditioning',
          description: 'Short conditioning block',
          exercises: const [
            TrainingExercise(
              exerciseId: 'burpees',
              reps: 10,
              sets: 3,
              unit: 'reps',
            ),
          ],
        ),
      ],
      mealEntries: const [
        MealEntry(
          id: 'meal-entry-3',
          sourceItemId: 'oats-bowl',
          itemName: 'Oats Bowl',
          itemType: CatalogItemType.dish,
          servingSizeGrams: 250,
          consumedGrams: 125,
          mode: MealEntryMode.grams,
          enteredQuantity: 125,
          nutrition: NutritionValues(
            calories: 75,
            protein: 2.5,
            fat: 1.5,
            carbs: 13.5,
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
        id: 'workout-session-1',
        trainingPlanId: 'conditioning',
        trainingPlanName: 'Conditioning',
        startedAt: DateTime.utc(2026, 5, 9, 10),
        results: const [
          WorkoutExerciseResult(
            exerciseId: 'burpees',
            exerciseName: 'Burpees',
            target: TrainingExercise(
              exerciseId: 'burpees',
              reps: 10,
              sets: 3,
              unit: 'reps',
            ),
            setLogs: const [
              WorkoutSetLog(reps: 10, weight: 0, time: 45),
            ],
          ),
        ],
      ),
      completedWorkoutSessions: [
        WorkoutSession(
          id: 'workout-session-0',
          trainingPlanId: 'conditioning',
          trainingPlanName: 'Conditioning',
          startedAt: DateTime.utc(2026, 5, 8, 10),
          finishedAt: DateTime.utc(2026, 5, 8, 10, 20),
          results: const [
            WorkoutExerciseResult(
              exerciseId: 'burpees',
              exerciseName: 'Burpees',
              target: TrainingExercise(
                exerciseId: 'burpees',
                reps: 8,
                sets: 2,
                unit: 'reps',
              ),
              setLogs: const [WorkoutSetLog(reps: 8, weight: 0, time: 40)],
            ),
          ],
        ),
      ],
      mealEntryCounter: 4,
      workoutSessionCounter: 7,
    );

    final encoded = PersistedAppStateCodec.encode(state);
    final decoded = PersistedAppStateCodec.decode(encoded);

    expect(decoded.userFoods.single.name, 'Oats');
    expect(decoded.userFoods.single.nutrition.carbs, 27);
    expect(decoded.userDishes.single.name, 'Oats Bowl');
    expect(decoded.userDishes.single.components.single.itemId, 'oats');
    expect(
      decoded.userExercises.single.muscleGroups,
      contains(MuscleGroup.cardio),
    );
    expect(decoded.userExercises.single.instruction, 'Keep pace steady.');
    expect(decoded.userTrainingPlans.single.name, 'Conditioning');
    expect(
      decoded.userTrainingPlans.single.exercises.single.exerciseId,
      'burpees',
    );
    expect(decoded.mealEntries.single.id, 'meal-entry-3');
    expect(decoded.mealEntries.single.itemType, CatalogItemType.dish);
    expect(decoded.mealEntries.single.mode, MealEntryMode.grams);
    expect(decoded.mealEntries.single.nutrition.calories, 75);
    expect(decoded.preferences.appearance, AppearancePreference.dark);
    expect(decoded.preferences.workoutWeightUnit, WorkoutWeightUnit.pounds);
    expect(decoded.preferences.dishWeightUnit, DishWeightUnit.ounces);
    expect(decoded.preferences.heightUnit, HeightUnit.inches);
    expect(decoded.preferences.distanceUnit, DistanceUnit.miles);
    expect(
      decoded.activeWorkoutSession!.startedAt,
      DateTime.utc(2026, 5, 9, 10),
    );
    expect(decoded.activeWorkoutSession!.results.single.exerciseName, 'Burpees');
    expect(decoded.activeWorkoutSession!.results.single.setLogs.single.time, 45);
    expect(decoded.completedWorkoutSessions.single.id, 'workout-session-0');
    expect(
      decoded.completedWorkoutSessions.single.finishedAt,
      DateTime.utc(2026, 5, 8, 10, 20),
    );
    expect(
      decoded.completedWorkoutSessions.single.results.single.target.sets,
      2,
    );
    expect(decoded.mealEntryCounter, 4);
    expect(decoded.workoutSessionCounter, 7);
  });
}
