import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import '../models/catalog_item.dart';
import '../models/exercise.dart';
import '../models/meal_entry.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';

/// Independently persisted and synchronized portions of application state.
enum AppStateSlice {
  foodLibrary,
  trainingLibrary,
  nutritionHistory,
  workout,
  preferences,
}

/// Base listenable for a state component owned by [AppStore].
abstract class AppStateComponent extends ChangeNotifier {
  int _revision = 0;

  /// Increases whenever this component changes.
  int get revision => _revision;

  void markChanged() {
    _revision += 1;
    notifyListeners();
  }
}

/// Reusable foods and recipes.
class FoodLibraryState extends AppStateComponent {
  final Map<String, CatalogItem> mutableCatalog = <String, CatalogItem>{};

  final Set<String> builtInIds = <String>{};

  Map<String, CatalogItem> get catalog => Map.unmodifiable(mutableCatalog);
}

/// Reusable exercises and training plans.
class TrainingLibraryState extends AppStateComponent {
  final Map<String, Exercise> mutableExercises = <String, Exercise>{};

  final List<TrainingPlan> mutableTrainingPlans = <TrainingPlan>[];

  final Set<String> builtInExerciseIds = <String>{};

  final Set<String> builtInTrainingPlanIds = <String>{};

  Map<String, Exercise> get exercises => Map.unmodifiable(mutableExercises);

  List<TrainingPlan> get trainingPlans =>
      List.unmodifiable(mutableTrainingPlans);
}

/// Logged nutrition activity.
class NutritionHistoryState extends AppStateComponent {
  final List<MealEntry> mutableEntries = <MealEntry>[];

  int legacyCounter = 0;

  List<MealEntry> get entries => List.unmodifiable(mutableEntries);
}

/// The active workout and completed workout history.
class WorkoutState extends AppStateComponent {
  WorkoutSession? mutableActiveSession;

  final List<WorkoutSession> mutableCompletedSessions = <WorkoutSession>[];

  int legacyCounter = 0;

  WorkoutSession? get activeSession => mutableActiveSession;

  List<WorkoutSession> get completedSessions =>
      List.unmodifiable(mutableCompletedSessions);
}

/// Appearance, language, units, and nutrition targets.
class PreferencesState extends AppStateComponent {
  AppPreferences mutableValue = const AppPreferences.defaults();

  AppPreferences get value => mutableValue;
}
