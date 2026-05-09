import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
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
      userDishes: const [],
      userExercises: const [
        Exercise(
          id: 'burpees',
          name: 'Burpees',
          description: 'Conditioning move',
          instruction: 'Keep pace steady.',
          muscleGroups: [MuscleGroup.cardio, MuscleGroup.fullBody],
        ),
      ],
      userTrainingPlans: const [
        TrainingPlan(
          id: 'conditioning',
          name: 'Conditioning',
          description: 'Short conditioning block',
          exercises: [
            TrainingExercise(
              exerciseId: 'burpees',
              reps: 10,
              sets: 3,
              unit: 'reps',
            ),
          ],
        ),
      ],
      mealEntries: const [],
      preferences: const AppPreferences.defaults(),
      activeWorkoutSession: WorkoutSession(
        id: 'workout-session-1',
        trainingPlanId: 'conditioning',
        trainingPlanName: 'Conditioning',
        startedAt: DateTime.utc(2026, 5, 9, 10),
        results: const [],
      ),
      completedWorkoutSessions: const [],
      mealEntryCounter: 4,
      workoutSessionCounter: 7,
    );

    final encoded = PersistedAppStateCodec.encode(state);
    final decoded = PersistedAppStateCodec.decode(encoded);

    expect(decoded.userFoods.single.name, 'Oats');
    expect(
      decoded.userExercises.single.muscleGroups,
      contains(MuscleGroup.cardio),
    );
    expect(
      decoded.activeWorkoutSession!.startedAt,
      DateTime.utc(2026, 5, 9, 10),
    );
    expect(decoded.mealEntryCounter, 4);
    expect(decoded.workoutSessionCounter, 7);
  });
}
