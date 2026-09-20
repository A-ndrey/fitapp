import '../../models/app_preferences.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

/// Snapshot of persisted user and runtime state.
class PersistedAppState {
  PersistedAppState({
    required List<FoodItem> userFoods,
    required List<DishItem> userDishes,
    required List<Exercise> userExercises,
    required List<TrainingPlan> userTrainingPlans,
    required List<MealEntry> mealEntries,
    required AppPreferences preferences,
    required WorkoutSession? activeWorkoutSession,
    required List<WorkoutSession> completedWorkoutSessions,
    required this.mealEntryCounter,
    required this.workoutSessionCounter,
  }) : userFoods = List.unmodifiable(userFoods.map(_cloneFoodItem)),
       userDishes = List.unmodifiable(userDishes.map(_cloneDishItem)),
       userExercises = List.unmodifiable(userExercises.map(_cloneExercise)),
       userTrainingPlans = List.unmodifiable(
         userTrainingPlans.map(_cloneTrainingPlan),
       ),
       mealEntries = _cloneMealEntriesInChronologicalOrder(mealEntries),
       preferences = _cloneAppPreferences(preferences),
       activeWorkoutSession = _cloneWorkoutSession(activeWorkoutSession),
       completedWorkoutSessions = _cloneWorkoutSessionsInChronologicalOrder(
         completedWorkoutSessions,
       );

  const PersistedAppState.empty()
    : userFoods = const [],
      userDishes = const [],
      userExercises = const [],
      userTrainingPlans = const [],
      mealEntries = const [],
      preferences = const AppPreferences.defaults(),
      activeWorkoutSession = null,
      completedWorkoutSessions = const [],
      mealEntryCounter = 0,
      workoutSessionCounter = 0;

  final List<FoodItem> userFoods;
  final List<DishItem> userDishes;
  final List<Exercise> userExercises;
  final List<TrainingPlan> userTrainingPlans;

  /// Logged meals ordered from oldest to newest.
  final List<MealEntry> mealEntries;

  final AppPreferences preferences;
  final WorkoutSession? activeWorkoutSession;

  /// Completed workouts ordered from oldest to newest.
  final List<WorkoutSession> completedWorkoutSessions;

  final int mealEntryCounter;
  final int workoutSessionCounter;

  static FoodItem _cloneFoodItem(FoodItem item) {
    return item.copyWith();
  }

  static DishItem _cloneDishItem(DishItem item) {
    return item.copyWith(
      components: List.unmodifiable(
        item.components.map((component) {
          return DishComponent(
            itemId: component.itemId,
            grams: component.grams,
          );
        }),
      ),
    );
  }

  static Exercise _cloneExercise(Exercise exercise) {
    return exercise.copyWith(
      muscleGroups: List.unmodifiable(exercise.muscleGroups),
    );
  }

  static TrainingPlan _cloneTrainingPlan(TrainingPlan plan) {
    return plan.copyWith(
      exercises: List.unmodifiable(
        plan.exercises.map((exercise) {
          return _cloneTrainingExercise(exercise);
        }),
      ),
    );
  }

  static MealEntry _cloneMealEntry(MealEntry entry) {
    return MealEntry(
      id: entry.id,
      sourceItemId: entry.sourceItemId,
      itemName: entry.itemName,
      itemType: entry.itemType,
      servingSizeGrams: entry.servingSizeGrams,
      consumedGrams: entry.consumedGrams,
      mode: entry.mode,
      enteredQuantity: entry.enteredQuantity,
      loggedAt: entry.loggedAt,
      nutrition: NutritionValues(
        calories: entry.nutrition.calories,
        protein: entry.nutrition.protein,
        fat: entry.nutrition.fat,
        carbs: entry.nutrition.carbs,
      ),
    );
  }

  static List<MealEntry> _cloneMealEntriesInChronologicalOrder(
    Iterable<MealEntry> entries,
  ) {
    final sorted = entries.map(_cloneMealEntry).toList(growable: false)
      ..sort((left, right) {
        final timestampComparison = left.loggedAt.compareTo(right.loggedAt);
        return timestampComparison != 0
            ? timestampComparison
            : left.id.compareTo(right.id);
      });
    return List.unmodifiable(sorted);
  }

  static List<WorkoutSession> _cloneWorkoutSessionsInChronologicalOrder(
    Iterable<WorkoutSession> sessions,
  ) {
    final sorted =
        sessions
            .map((session) => _cloneWorkoutSession(session)!)
            .toList(growable: false)
          ..sort((left, right) {
            final timestampComparison = left.startedAt.compareTo(
              right.startedAt,
            );
            return timestampComparison != 0
                ? timestampComparison
                : left.id.compareTo(right.id);
          });
    return List.unmodifiable(sorted);
  }

  static AppPreferences _cloneAppPreferences(AppPreferences preferences) {
    return preferences.copyWith();
  }

  static WorkoutSession? _cloneWorkoutSession(WorkoutSession? session) {
    if (session == null) {
      return null;
    }
    return session.copyWith(
      results: List.unmodifiable(
        session.results.map((result) {
          return result.copyWith(
            muscleGroups: result.muscleGroups == null
                ? null
                : List.unmodifiable(result.muscleGroups!),
            target: result.target.copyWith(),
            setLogs: List.unmodifiable(
              result.setLogs.map((setLog) {
                return _cloneWorkoutSetLog(setLog);
              }),
            ),
          );
        }),
      ),
    );
  }

  static TrainingExercise _cloneTrainingExercise(TrainingExercise exercise) {
    return exercise.copyWith();
  }

  static WorkoutSetLog _cloneWorkoutSetLog(WorkoutSetLog setLog) {
    return setLog.copyWith();
  }
}
