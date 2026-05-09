import '../../models/app_preferences.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_entry.dart';
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
    required this.preferences,
    required this.activeWorkoutSession,
    required List<WorkoutSession> completedWorkoutSessions,
    required this.mealEntryCounter,
    required this.workoutSessionCounter,
  }) : userFoods = List.unmodifiable(userFoods),
       userDishes = List.unmodifiable(userDishes),
       userExercises = List.unmodifiable(userExercises),
       userTrainingPlans = List.unmodifiable(userTrainingPlans),
       mealEntries = List.unmodifiable(mealEntries),
       completedWorkoutSessions = List.unmodifiable(completedWorkoutSessions);

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
}
