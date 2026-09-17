import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';

AppStore workoutReplacementFixture({
  bool duplicate = false,
  AppStorePersistence? persistence,
}) {
  final store = AppStore.empty(persistence: persistence);
  for (final exercise in const [
    Exercise(
      id: 'bench',
      name: 'Bench press',
      description: 'Barbell press',
      instruction: 'Press the bar.',
      muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      measurementType: ExerciseMeasurementType.strength,
    ),
    Exercise(
      id: 'pushups',
      name: 'Pushups',
      description: 'Bodyweight press',
      instruction: 'Keep your body straight.',
      muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      measurementType: ExerciseMeasurementType.bodyweight,
    ),
    Exercise(
      id: 'fly',
      name: 'Chest fly',
      description: 'Chest isolation',
      instruction: 'Bring arms together.',
      muscleGroups: [MuscleGroup.chest],
      measurementType: ExerciseMeasurementType.strength,
    ),
    Exercise(
      id: 'plank',
      name: 'Plank',
      description: 'Core hold',
      instruction: 'Hold your position.',
      muscleGroups: [MuscleGroup.core],
      measurementType: ExerciseMeasurementType.duration,
    ),
  ]) {
    store.createExercise(exercise);
  }
  store.createTrainingPlan(
    TrainingPlan(
      id: 'plan',
      name: 'Push day',
      description: 'Pressing work',
      exercises: [
        const TrainingExercise(
          exerciseId: 'bench',
          sets: 3,
          reps: 8,
          weightGrams: 60000,
        ),
        if (duplicate)
          const TrainingExercise(exerciseId: 'pushups', sets: 2, reps: 12),
      ],
    ),
  );
  store.startWorkout(trainingPlanId: 'plan');
  return store;
}
