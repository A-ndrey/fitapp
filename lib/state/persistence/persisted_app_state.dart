import '../../models/app_preferences.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

/// Snapshot of persisted user and runtime state only.
///
/// Bootstrapped built-in catalog data is excluded and merged separately on load.
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
  }) : userFoods = List.unmodifiable(
         userFoods.map(_cloneFoodItem),
       ),
       userDishes = List.unmodifiable(
         userDishes.map(_cloneDishItem),
       ),
       userExercises = List.unmodifiable(
         userExercises.map(_cloneExercise),
       ),
       userTrainingPlans = List.unmodifiable(
         userTrainingPlans.map(_cloneTrainingPlan),
       ),
       mealEntries = List.unmodifiable(
         mealEntries.map(_cloneMealEntry),
       ),
       preferences = _cloneAppPreferences(preferences),
       activeWorkoutSession = _cloneWorkoutSession(activeWorkoutSession),
       completedWorkoutSessions = List.unmodifiable(
         completedWorkoutSessions.map(_cloneWorkoutSession),
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
  final List<MealEntry> mealEntries;
  final AppPreferences preferences;
  final WorkoutSession? activeWorkoutSession;
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
          return DishComponent(itemId: component.itemId, grams: component.grams);
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
          return exercise.copyWith();
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
      nutrition: NutritionValues(
        calories: entry.nutrition.calories,
        protein: entry.nutrition.protein,
        fat: entry.nutrition.fat,
        carbs: entry.nutrition.carbs,
      ),
    );
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
            target: result.target.copyWith(),
            setLogs: List.unmodifiable(
              result.setLogs.map((setLog) {
                return setLog.copyWith();
              }),
            ),
          );
        }),
      ),
    );
  }
}
