import '../../models/app_preferences.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_entry.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';

class PersistedAppState {
  const PersistedAppState({
    required this.userFoods,
    required this.userDishes,
    required this.userExercises,
    required this.userTrainingPlans,
    required this.mealEntries,
    required this.preferences,
    required this.activeWorkoutSession,
    required this.completedWorkoutSessions,
    required this.mealEntryCounter,
    required this.workoutSessionCounter,
  });

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
