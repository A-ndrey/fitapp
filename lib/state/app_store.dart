import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_preferences.dart';
import '../models/catalog_item.dart';
import '../models/dish_item.dart';
import '../models/exercise.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/nutrition.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import 'persistence/app_store_persistence.dart';
import 'persistence/persisted_app_state.dart';

typedef PersistedAppStateObserver = void Function(PersistedAppState state);

class AppStore extends ChangeNotifier {
  AppStore({
    AppStorePersistence? persistence,
    PersistedAppStateObserver? onPersistedStateSaved,
  }) : _persistence = persistence,
       _onPersistedStateSaved = onPersistedStateSaved;

  AppStore.empty({
    AppStorePersistence? persistence,
    PersistedAppStateObserver? onPersistedStateSaved,
  }) : _persistence = persistence,
       _onPersistedStateSaved = onPersistedStateSaved,
       super();

  static Future<AppStore> hydrated({
    required AppStorePersistence persistence,
    PersistedAppStateObserver? onPersistedStateSaved,
  }) async {
    final store = AppStore(
      persistence: persistence,
      onPersistedStateSaved: onPersistedStateSaved,
    );
    final loadedState = await persistence.load();
    if (loadedState == null) {
      return store;
    }
    store._applyPersistedState(loadedState);
    return store;
  }

  final Map<String, CatalogItem> _catalog = <String, CatalogItem>{};
  final List<MealEntry> _mealEntries = <MealEntry>[];
  final Map<String, Exercise> _exercises = <String, Exercise>{};
  final List<TrainingPlan> _trainingPlans = <TrainingPlan>[];
  final List<WorkoutSession> _completedWorkoutSessions = <WorkoutSession>[];
  final Set<String> _builtInCatalogIds = <String>{};
  final Set<String> _builtInExerciseIds = <String>{};
  final Set<String> _builtInTrainingPlanIds = <String>{};
  final AppStorePersistence? _persistence;
  final PersistedAppStateObserver? _onPersistedStateSaved;
  AppPreferences _preferences = const AppPreferences.defaults();
  bool _isLoggedIn = false;
  WorkoutSession? _activeWorkoutSession;
  int _mealEntryCounter = 0;
  int _workoutSessionCounter = 0;
  Future<void> _pendingSave = Future<void>.value();
  bool _isPersistenceSuspended = false;
  int _persistedStateObserverGeneration = 0;

  Map<String, CatalogItem> get catalog => Map.unmodifiable(_catalog);

  List<CatalogItem> get items => List.unmodifiable(_catalog.values);

  List<MealEntry> get mealEntries => List.unmodifiable(_mealEntries);

  List<MealEntry> get todayMealEntries {
    final today = _localDateOnly(DateTime.now());
    return List.unmodifiable(
      _mealEntries.where((entry) => _localDateOnly(entry.loggedAt) == today),
    );
  }

  List<MealEntry> get mealEntriesNewestFirst {
    final sorted = List<MealEntry>.of(_mealEntries)
      ..sort((left, right) => right.loggedAt.compareTo(left.loggedAt));
    return List.unmodifiable(sorted);
  }

  List<MealHistoryGroup> get mealHistoryGroups {
    final groups = <MealHistoryGroup>[];
    DateTime? currentDate;
    var currentEntries = <MealEntry>[];

    for (final entry in mealEntriesNewestFirst) {
      final entryDate = _localDateOnly(entry.loggedAt);
      if (currentDate == null || entryDate != currentDate) {
        if (currentDate != null) {
          groups.add(
            MealHistoryGroup(
              date: currentDate,
              entries: List.unmodifiable(currentEntries),
            ),
          );
        }
        currentDate = entryDate;
        currentEntries = <MealEntry>[entry];
      } else {
        currentEntries.add(entry);
      }
    }

    if (currentDate != null) {
      groups.add(
        MealHistoryGroup(
          date: currentDate,
          entries: List.unmodifiable(currentEntries),
        ),
      );
    }

    return List.unmodifiable(groups);
  }

  List<Exercise> get exercises => List.unmodifiable(_exercises.values);

  List<TrainingPlan> get trainingPlans => List.unmodifiable(_trainingPlans);

  List<WorkoutSession> get completedWorkoutSessions =>
      List.unmodifiable(_completedWorkoutSessions);

  AppPreferences get preferences => _preferences;

  AppearancePreference get appearancePreference => _preferences.appearance;

  LanguagePreference get languagePreference => _preferences.language;

  WorkoutWeightUnit get workoutWeightUnit => _preferences.workoutWeightUnit;

  DishWeightUnit get dishWeightUnit => _preferences.dishWeightUnit;

  HeightUnit get heightUnit => _preferences.heightUnit;

  DistanceUnit get distanceUnit => _preferences.distanceUnit;

  NutritionValues get dailyMacroTargets => _preferences.dailyMacroTargets;

  bool get isLoggedIn => _isLoggedIn;

  WorkoutSession? get activeWorkoutSession => _activeWorkoutSession;

  void setAppearancePreference(AppearancePreference preference) {
    _preferences = _preferences.copyWith(appearance: preference);
    _didMutatePersistedState();
  }

  void setLanguagePreference(LanguagePreference preference) {
    _preferences = _preferences.copyWith(language: preference);
    _didMutatePersistedState();
  }

  void setWorkoutWeightUnit(WorkoutWeightUnit unit) {
    _preferences = _preferences.copyWith(workoutWeightUnit: unit);
    _didMutatePersistedState();
  }

  void setDishWeightUnit(DishWeightUnit unit) {
    _preferences = _preferences.copyWith(dishWeightUnit: unit);
    _didMutatePersistedState();
  }

  void setHeightUnit(HeightUnit unit) {
    _preferences = _preferences.copyWith(heightUnit: unit);
    _didMutatePersistedState();
  }

  void setDistanceUnit(DistanceUnit unit) {
    _preferences = _preferences.copyWith(distanceUnit: unit);
    _didMutatePersistedState();
  }

  void setDailyMacroTargets(NutritionValues targets) {
    _preferences = _preferences.copyWith(dailyMacroTargets: targets);
    _didMutatePersistedState();
  }

  void logIn() {
    if (_isLoggedIn) {
      return;
    }
    _isLoggedIn = true;
    _didMutateTransientState();
  }

  void logOut() {
    if (!_isLoggedIn) {
      return;
    }
    _isLoggedIn = false;
    _didMutateTransientState();
  }

  Future<void> applyExternalPersistedState(
    PersistedAppState state, {
    bool notifyPersistedStateObserver = true,
  }) async {
    _validateExternalPersistedStateCompatibility(state);
    _validatePersistedState(state);
    _persistedStateObserverGeneration += 1;
    _applyPersistedStateUnchecked(state);
    notifyListeners();
    await _schedulePersistenceSave(
      notifyPersistedStateObserver: notifyPersistedStateObserver,
    );
  }

  String formatWorkoutWeight(double kilograms) {
    final value = workoutWeightUnit == WorkoutWeightUnit.pounds
        ? kilograms * 2.2046226218
        : kilograms;
    final suffix = workoutWeightUnit == WorkoutWeightUnit.pounds ? 'lbs' : 'kg';
    return '${_formatCompactNumber(value)} $suffix';
  }

  String formatDishWeight(double grams) {
    final value = dishWeightUnit == DishWeightUnit.ounces
        ? grams / 28.349523125
        : grams;
    final suffix = dishWeightUnit == DishWeightUnit.ounces ? 'oz' : 'g';
    return '${_formatCompactNumber(value)} $suffix';
  }

  String formatHeight(double centimeters) {
    final value = heightUnit == HeightUnit.inches
        ? centimeters / 2.54
        : centimeters;
    final suffix = heightUnit == HeightUnit.inches ? 'in' : 'cm';
    return '${_formatCompactNumber(value)} $suffix';
  }

  String formatDistance(double kilometers) {
    final value = distanceUnit == DistanceUnit.miles
        ? kilometers / 1.609344
        : kilometers;
    final suffix = distanceUnit == DistanceUnit.miles ? 'miles' : 'km';
    return '${_formatCompactNumber(value)} $suffix';
  }

  List<WorkoutExerciseHistoryGroup> completedWorkoutHistoryForExercise(
    String exerciseId,
  ) {
    final groups = <WorkoutExerciseHistoryGroup>[];
    for (var i = _completedWorkoutSessions.length - 1; i >= 0; i--) {
      final session = _completedWorkoutSessions[i];
      final matchingResults = <WorkoutExerciseResult>[];
      for (final result in session.results) {
        if (result.exerciseId == exerciseId) {
          matchingResults.add(result);
        }
      }
      if (matchingResults.isEmpty) {
        continue;
      }
      groups.add(
        WorkoutExerciseHistoryGroup(
          session: session,
          results: List.unmodifiable(matchingResults),
        ),
      );
    }
    return List.unmodifiable(groups);
  }

  TodayWorkoutRecommendation? get todayWorkoutRecommendation {
    if (_trainingPlans.isEmpty) {
      return null;
    }
    return todayWorkoutRecommendationAt(DateTime.now());
  }

  TodayWorkoutRecommendation todayWorkoutRecommendationAt(DateTime now) {
    final activeSession = _activeWorkoutSession;
    if (activeSession != null) {
      final activePlan = trainingPlanById(activeSession.trainingPlanId);
      if (activePlan != null) {
        return TodayWorkoutRecommendation(
          status: TodayWorkoutStatus.active,
          plan: activePlan,
          session: activeSession,
        );
      }
    }

    final currentPlanIds = _trainingPlans.map((plan) => plan.id).toSet();
    WorkoutSession? completedToday;
    for (var i = _completedWorkoutSessions.length - 1; i >= 0; i--) {
      final session = _completedWorkoutSessions[i];
      if (!currentPlanIds.contains(session.trainingPlanId)) {
        continue;
      }
      if (_isSameDate(session.startedAt, now)) {
        completedToday = session;
        break;
      }
    }
    if (completedToday != null) {
      return TodayWorkoutRecommendation(
        status: TodayWorkoutStatus.completedToday,
        plan: trainingPlanById(completedToday.trainingPlanId)!,
        session: completedToday,
        lastCompletedAt: completedToday.startedAt,
      );
    }

    final lastCompletedByPlanId = <String, DateTime>{};
    for (var i = _completedWorkoutSessions.length - 1; i >= 0; i--) {
      final session = _completedWorkoutSessions[i];
      if (!currentPlanIds.contains(session.trainingPlanId) ||
          lastCompletedByPlanId.containsKey(session.trainingPlanId)) {
        continue;
      }
      lastCompletedByPlanId[session.trainingPlanId] = session.startedAt;
      if (lastCompletedByPlanId.length == currentPlanIds.length) {
        break;
      }
    }

    TrainingPlan? leastRecentPlan;
    DateTime? leastRecentCompletedAt;
    for (final plan in _trainingPlans) {
      final completedAt = lastCompletedByPlanId[plan.id];
      if (completedAt == null) {
        leastRecentPlan = plan;
        leastRecentCompletedAt = null;
        break;
      }
      if (leastRecentCompletedAt == null ||
          completedAt.isBefore(leastRecentCompletedAt)) {
        leastRecentPlan = plan;
        leastRecentCompletedAt = completedAt;
      }
    }

    return TodayWorkoutRecommendation(
      status: TodayWorkoutStatus.notStarted,
      plan: leastRecentPlan ?? _trainingPlans.first,
      lastCompletedAt: leastRecentCompletedAt,
    );
  }

  WorkoutStats get workoutStats {
    var totalDuration = Duration.zero;
    WorkoutSession? latest;
    for (final session in _completedWorkoutSessions) {
      totalDuration += session.duration;
      if (latest == null || session.startedAt.isAfter(latest.startedAt)) {
        latest = session;
      }
    }
    return WorkoutStats(
      completedCount: _completedWorkoutSessions.length,
      totalDuration: totalDuration,
      latestSession: latest,
    );
  }

  NutritionValues get dailyTotals {
    var total = NutritionValues.zero;
    for (final entry in todayMealEntries) {
      total = total + entry.nutrition;
    }
    return total;
  }

  CatalogItem? itemById(String id) => _catalog[id];

  Exercise? exerciseById(String id) => _exercises[id];

  TrainingPlan? trainingPlanById(String id) {
    for (final plan in _trainingPlans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }

  List<CatalogItem> searchItems(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(normalizedQuery) ||
              item.description.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  List<Exercise> searchExercises(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return exercises;
    }
    return exercises
        .where(
          (exercise) =>
              exercise.name.toLowerCase().contains(normalizedQuery) ||
              exercise.description.toLowerCase().contains(normalizedQuery) ||
              exercise.muscleGroups.any(
                (group) => group.label.toLowerCase().contains(normalizedQuery),
              ),
        )
        .toList(growable: false);
  }

  void createExercise(Exercise exercise) {
    _validateExercise(exercise);
    if (_exercises.containsKey(exercise.id)) {
      throw ArgumentError('Duplicate exercise id: ${exercise.id}');
    }
    _exercises[exercise.id] = _freezeExercise(exercise);
    _didMutatePersistedState();
  }

  void updateExercise(Exercise exercise) {
    _validateExercise(exercise);
    _assertExerciseIsUserDefined(exercise.id);
    if (!_exercises.containsKey(exercise.id)) {
      throw ArgumentError('Missing exercise id: ${exercise.id}');
    }
    final existing = _exercises[exercise.id]!;
    if (existing.measurementType != exercise.measurementType) {
      if (_hasWorkoutHistoryForExercise(exercise.id)) {
        throw ArgumentError(
          'Exercise measurement type cannot change after workout history exists.',
        );
      }
      if (_isReferencedByAnyTrainingPlan(exercise.id) ||
          _isReferencedByActiveWorkout(exercise.id)) {
        throw ArgumentError(
          'Exercise measurement type cannot change while referenced by a training plan or active workout.',
        );
      }
    }
    _exercises[exercise.id] = _freezeExercise(exercise);
    _didMutatePersistedState();
  }

  void deleteExercise(String id) {
    _assertExerciseCanBeDeleted(id);
    if (!_exercises.containsKey(id)) {
      throw ArgumentError('Missing exercise id: $id');
    }
    if (_isReferencedByAnyTrainingPlan(id)) {
      throw StateError('Exercise is used by a training plan.');
    }
    if (_isReferencedByActiveWorkout(id)) {
      throw StateError('Exercise is used by the active workout.');
    }
    if (_isReferencedByCompletedWorkoutHistory(id)) {
      throw StateError('Exercise is used by completed workout history.');
    }
    _exercises.remove(id);
    _didMutatePersistedState();
  }

  void createTrainingPlan(TrainingPlan plan) {
    _validateTrainingPlan(plan);
    if (trainingPlanById(plan.id) != null) {
      throw ArgumentError('Duplicate training plan id: ${plan.id}');
    }
    _trainingPlans.add(_freezeTrainingPlan(plan));
    _didMutatePersistedState();
  }

  void updateTrainingPlan(TrainingPlan plan) {
    _validateTrainingPlan(plan);
    _assertTrainingPlanIsUserDefined(plan.id);
    final index = _trainingPlans.indexWhere(
      (existing) => existing.id == plan.id,
    );
    if (index == -1) {
      throw ArgumentError('Missing training plan id: ${plan.id}');
    }
    _trainingPlans[index] = _freezeTrainingPlan(plan);
    _didMutatePersistedState();
  }

  void deleteTrainingPlan(String id) {
    _assertTrainingPlanCanBeDeleted(id);
    final index = _trainingPlans.indexWhere((plan) => plan.id == id);
    if (index == -1) {
      throw ArgumentError('Missing training plan id: $id');
    }
    if (_activeWorkoutSession?.trainingPlanId == id) {
      throw StateError('Training plan is used by the active workout.');
    }
    _trainingPlans.removeAt(index);
    _didMutatePersistedState();
  }

  WorkoutSession startWorkout({
    required String trainingPlanId,
    DateTime? startedAt,
  }) {
    if (_activeWorkoutSession != null) {
      throw StateError('A workout is already active.');
    }
    final plan = trainingPlanById(trainingPlanId);
    if (plan == null) {
      throw ArgumentError('Missing training plan id: $trainingPlanId');
    }
    final results = <WorkoutExerciseResult>[];
    for (final plannedExercise in plan.exercises) {
      final exercise = _exercises[plannedExercise.exerciseId];
      if (exercise == null) {
        throw ArgumentError(
          'Missing exercise id: ${plannedExercise.exerciseId}',
        );
      }
      results.add(
        WorkoutExerciseResult(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          target: plannedExercise,
          setLogs: const [],
        ),
      );
    }
    final session = WorkoutSession(
      id: _nextWorkoutSessionId(),
      trainingPlanId: plan.id,
      trainingPlanName: plan.name,
      startedAt: startedAt ?? DateTime.now(),
      results: List<WorkoutExerciseResult>.unmodifiable(results),
    );
    _activeWorkoutSession = session;
    _didMutatePersistedState();
    return session;
  }

  void addActiveWorkoutSet({
    required int resultIndex,
    required WorkoutSetLog setLog,
  }) {
    final session = _activeWorkoutSession;
    if (session == null) {
      throw StateError('No active workout.');
    }
    if (resultIndex < 0 || resultIndex >= session.results.length) {
      throw RangeError.index(resultIndex, session.results, 'resultIndex');
    }
    final exerciseId = session.results[resultIndex].exerciseId;
    final measurementType = _requireExerciseMeasurementType(exerciseId);
    _validateWorkoutSetLog(setLog, measurementType);
    final updatedResults = List<WorkoutExerciseResult>.of(session.results);
    final current = updatedResults[resultIndex];
    updatedResults[resultIndex] = WorkoutExerciseResult(
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      target: current.target,
      setLogs: List<WorkoutSetLog>.unmodifiable(<WorkoutSetLog>[
        ...current.setLogs,
        setLog,
      ]),
    );
    _activeWorkoutSession = session.copyWith(
      results: List<WorkoutExerciseResult>.unmodifiable(updatedResults),
    );
    _didMutatePersistedState();
  }

  void removeActiveWorkoutSet({
    required int resultIndex,
    required int setIndex,
  }) {
    final session = _activeWorkoutSession;
    if (session == null) {
      throw StateError('No active workout.');
    }
    if (resultIndex < 0 || resultIndex >= session.results.length) {
      throw RangeError.index(resultIndex, session.results, 'resultIndex');
    }
    final current = session.results[resultIndex];
    if (setIndex < 0 || setIndex >= current.setLogs.length) {
      throw RangeError.index(setIndex, current.setLogs, 'setIndex');
    }
    final updatedSetLogs = List<WorkoutSetLog>.of(current.setLogs)
      ..removeAt(setIndex);
    final updatedResults = List<WorkoutExerciseResult>.of(session.results);
    updatedResults[resultIndex] = WorkoutExerciseResult(
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      target: current.target,
      setLogs: List<WorkoutSetLog>.unmodifiable(updatedSetLogs),
    );
    _activeWorkoutSession = session.copyWith(
      results: List<WorkoutExerciseResult>.unmodifiable(updatedResults),
    );
    _didMutatePersistedState();
  }

  WorkoutSession finishActiveWorkout({DateTime? finishedAt}) {
    final session = _activeWorkoutSession;
    if (session == null) {
      throw StateError('No active workout.');
    }
    final finished = session.copyWith(finishedAt: finishedAt ?? DateTime.now());
    _activeWorkoutSession = null;
    _completedWorkoutSessions.add(finished);
    _didMutatePersistedState();
    return finished;
  }

  void deleteCompletedWorkoutSession(String sessionId) {
    final index = _completedWorkoutSessions.indexWhere(
      (session) => session.id == sessionId,
    );
    if (index == -1) {
      throw ArgumentError('Missing completed workout session id: $sessionId');
    }
    _completedWorkoutSessions.removeAt(index);
    _didMutatePersistedState();
  }

  void createFood(FoodItem food) {
    _validateFood(food);
    if (_catalog.containsKey(food.id)) {
      throw ArgumentError('Duplicate item id: ${food.id}');
    }
    _catalog[food.id] = CatalogItem.food(food);
    _didMutatePersistedState();
  }

  void updateFood(FoodItem food) {
    _validateFood(food);
    _assertCatalogItemIsUserDefined(food.id);
    final existing = _catalog[food.id];
    if (existing == null) {
      throw ArgumentError('Missing item id: ${food.id}');
    }
    if (!existing.isFood) {
      throw ArgumentError('Item id is not a food: ${food.id}');
    }
    _catalog[food.id] = CatalogItem.food(food);
    _didMutatePersistedState();
  }

  void createDish(DishItem dish) {
    _validateDish(dish);
    if (_catalog.containsKey(dish.id)) {
      throw ArgumentError('Duplicate item id: ${dish.id}');
    }
    _catalog[dish.id] = CatalogItem.dish(_freezeDish(dish));
    _didMutatePersistedState();
  }

  void updateDish(DishItem dish) {
    _validateDish(dish);
    _assertCatalogItemIsUserDefined(dish.id);
    final existing = _catalog[dish.id];
    if (existing == null) {
      throw ArgumentError('Missing item id: ${dish.id}');
    }
    if (!existing.isDish) {
      throw ArgumentError('Item id is not a dish: ${dish.id}');
    }
    _catalog[dish.id] = CatalogItem.dish(_freezeDish(dish));
    _didMutatePersistedState();
  }

  void deleteItem(String id) {
    _assertCatalogItemCanBeDeleted(id);
    if (!_catalog.containsKey(id)) {
      throw ArgumentError('Missing item id: $id');
    }
    if (_isReferencedByAnyDish(id)) {
      throw StateError('Item is used by a recipe.');
    }
    _catalog.remove(id);
    _didMutatePersistedState();
  }

  MealEntry addMealByGrams({
    required String itemId,
    required double grams,
    DateTime? loggedAt,
  }) {
    if (!grams.isFinite || grams <= 0) {
      throw ArgumentError.value(grams, 'grams', 'Must be greater than zero.');
    }
    final item = _catalog[itemId];
    if (item == null) {
      throw ArgumentError('Missing item id: $itemId');
    }
    final entry = MealEntry.fromItem(
      id: _nextMealEntryId(),
      item: item,
      consumedGrams: grams,
      mode: MealEntryMode.grams,
      enteredQuantity: grams,
      loggedAt: loggedAt,
      catalog: _catalog,
    );
    _mealEntries.add(entry);
    _didMutatePersistedState();
    return entry;
  }

  MealEntry addMealByServings({
    required String itemId,
    required double servings,
    DateTime? loggedAt,
  }) {
    if (!servings.isFinite || servings <= 0) {
      throw ArgumentError.value(
        servings,
        'servings',
        'Must be greater than zero.',
      );
    }
    final item = _catalog[itemId];
    if (item == null) {
      throw ArgumentError('Missing item id: $itemId');
    }
    final grams = item.servingSizeGrams * servings;
    final entry = MealEntry.fromItem(
      id: _nextMealEntryId(),
      item: item,
      consumedGrams: grams,
      mode: MealEntryMode.servings,
      enteredQuantity: servings,
      loggedAt: loggedAt,
      catalog: _catalog,
    );
    _mealEntries.add(entry);
    _didMutatePersistedState();
    return entry;
  }

  void removeMealEntry(String id) {
    final before = _mealEntries.length;
    _mealEntries.removeWhere((entry) => entry.id == id);
    if (_mealEntries.length != before) {
      _didMutatePersistedState();
    }
  }

  void _didMutatePersistedState() {
    notifyListeners();
    unawaited(_schedulePersistenceSave());
  }

  void _didMutateTransientState() {
    notifyListeners();
  }

  void _runWithoutPersistence(void Function() action) {
    final wasSuspended = _isPersistenceSuspended;
    _isPersistenceSuspended = true;
    try {
      action();
    } finally {
      _isPersistenceSuspended = wasSuspended;
    }
  }

  Future<void> _schedulePersistenceSave({
    bool notifyPersistedStateObserver = true,
  }) {
    final persistence = _persistence;
    if (persistence == null || _isPersistenceSuspended) {
      return Future<void>.value();
    }

    final snapshot = _toPersistedAppState();
    final observerGeneration = _persistedStateObserverGeneration;
    _pendingSave = _pendingSave
        .catchError((Object _, StackTrace _) {})
        .then((_) async {
          await persistence.save(snapshot);
          if (notifyPersistedStateObserver &&
              observerGeneration == _persistedStateObserverGeneration) {
            _notifyPersistedStateSaved(snapshot);
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'fitapp',
              context: ErrorDescription('while persisting AppStore state'),
            ),
          );
        });
    return _pendingSave;
  }

  PersistedAppState _toPersistedAppState() {
    final userFoods = <FoodItem>[];
    final userDishes = <DishItem>[];

    for (final item in _catalog.values) {
      if (_builtInCatalogIds.contains(item.id)) {
        continue;
      }
      if (item.isFood) {
        userFoods.add(item.food!);
      } else if (item.isDish) {
        userDishes.add(item.dish!);
      }
    }

    return PersistedAppState(
      userFoods: userFoods,
      userDishes: userDishes,
      userExercises: _exercises.entries
          .where((entry) => !_builtInExerciseIds.contains(entry.key))
          .map((entry) => entry.value)
          .toList(growable: false),
      userTrainingPlans: _trainingPlans
          .where((plan) => !_builtInTrainingPlanIds.contains(plan.id))
          .toList(growable: false),
      mealEntries: _mealEntries,
      preferences: _preferences,
      activeWorkoutSession: _activeWorkoutSession,
      completedWorkoutSessions: _completedWorkoutSessions,
      mealEntryCounter: _mealEntryCounter,
      workoutSessionCounter: _workoutSessionCounter,
    );
  }

  void _applyPersistedState(PersistedAppState state) {
    _validatePersistedState(state);
    _applyPersistedStateUnchecked(state);
  }

  void _applyPersistedStateUnchecked(PersistedAppState state) {
    _runWithoutPersistence(() {
      _resetRuntimeStateToBuiltIns();

      for (final food in state.userFoods) {
        if (_builtInCatalogIds.contains(food.id)) {
          continue;
        }
        _catalog[food.id] = CatalogItem.food(food.copyWith());
      }
      for (final dish in state.userDishes) {
        if (_builtInCatalogIds.contains(dish.id)) {
          continue;
        }
        _catalog[dish.id] = CatalogItem.dish(_freezeDish(dish));
      }
      for (final exercise in state.userExercises) {
        if (_builtInExerciseIds.contains(exercise.id)) {
          continue;
        }
        _exercises[exercise.id] = _freezeExercise(exercise);
      }

      for (final plan in state.userTrainingPlans) {
        if (_builtInTrainingPlanIds.contains(plan.id)) {
          continue;
        }
        _trainingPlans.add(_freezeTrainingPlan(plan));
      }

      _mealEntries
        ..clear()
        ..addAll(state.mealEntries);
      _preferences = state.preferences.copyWith();
      _activeWorkoutSession = state.activeWorkoutSession;
      _completedWorkoutSessions
        ..clear()
        ..addAll(state.completedWorkoutSessions);
      _mealEntryCounter = state.mealEntryCounter;
      _workoutSessionCounter = state.workoutSessionCounter;
      _isLoggedIn = false;
    });
  }

  void _validatePersistedState(PersistedAppState state) {
    final validationStore = AppStore();

    for (final food in state.userFoods) {
      validationStore.createFood(food);
    }
    for (final dish in state.userDishes) {
      validationStore.createDish(dish);
    }
    for (final exercise in state.userExercises) {
      validationStore.createExercise(exercise);
    }
    for (final plan in state.userTrainingPlans) {
      validationStore.createTrainingPlan(plan);
    }
    final activeWorkoutSession = state.activeWorkoutSession;
    if (activeWorkoutSession != null) {
      validationStore._validateWorkoutSession(activeWorkoutSession);
    }
    for (final session in state.completedWorkoutSessions) {
      validationStore._validateWorkoutSession(session);
    }
  }

  void _validateExternalPersistedStateCompatibility(PersistedAppState state) {
    for (final exercise in state.userExercises) {
      final existing = _exercises[exercise.id];
      if (existing == null) {
        continue;
      }
      if (existing.measurementType != exercise.measurementType &&
          _hasWorkoutHistoryForExercise(exercise.id)) {
        throw ArgumentError(
          'Exercise measurement type cannot change after workout history exists.',
        );
      }
    }
  }

  void _notifyPersistedStateSaved(PersistedAppState state) {
    final observer = _onPersistedStateSaved;
    if (observer == null) {
      return;
    }
    try {
      observer(state);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'fitapp',
          context: ErrorDescription(
            'while notifying persisted AppStore state observers',
          ),
        ),
      );
    }
  }

  void _assertCatalogItemIsUserDefined(String id) {
    if (_builtInCatalogIds.contains(id)) {
      throw ArgumentError('Built-in catalog items cannot be changed.');
    }
  }

  void _assertExerciseIsUserDefined(String id) {
    if (_builtInExerciseIds.contains(id)) {
      throw ArgumentError('Built-in exercises cannot be changed.');
    }
  }

  void _assertTrainingPlanIsUserDefined(String id) {
    if (_builtInTrainingPlanIds.contains(id)) {
      throw ArgumentError('Built-in training plans cannot be changed.');
    }
  }

  void _assertCatalogItemCanBeDeleted(String id) {
    if (_builtInCatalogIds.contains(id)) {
      throw StateError('Built-in catalog items cannot be deleted.');
    }
  }

  void _assertExerciseCanBeDeleted(String id) {
    if (_builtInExerciseIds.contains(id)) {
      throw StateError('Built-in exercises cannot be deleted.');
    }
  }

  void _assertTrainingPlanCanBeDeleted(String id) {
    if (_builtInTrainingPlanIds.contains(id)) {
      throw StateError('Built-in training plans cannot be deleted.');
    }
  }

  void _resetRuntimeStateToBuiltIns() {
    _catalog.removeWhere((id, _) => !_builtInCatalogIds.contains(id));
    _exercises.removeWhere((id, _) => !_builtInExerciseIds.contains(id));
    _trainingPlans.removeWhere(
      (plan) => !_builtInTrainingPlanIds.contains(plan.id),
    );
    _mealEntries.clear();
    _completedWorkoutSessions.clear();
    _preferences = const AppPreferences.defaults();
    _activeWorkoutSession = null;
    _mealEntryCounter = 0;
    _workoutSessionCounter = 0;
    _isLoggedIn = false;
  }

  String createIdFromName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    var lastWasHyphen = false;
    for (final codeUnit in normalized.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final isAlphaNumeric =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNumeric) {
        buffer.write(char);
        lastWasHyphen = false;
      } else if (!lastWasHyphen) {
        buffer.write('-');
        lastWasHyphen = true;
      }
    }
    return buffer.toString().replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static DateTime _localDateOnly(DateTime value) {
    final localValue = value.toLocal();
    return DateTime(localValue.year, localValue.month, localValue.day);
  }

  static bool _isSameDate(DateTime first, DateTime second) {
    return _localDateOnly(first) == _localDateOnly(second);
  }

  void _validateFood(FoodItem food) {
    if (food.id.trim().isEmpty) {
      throw ArgumentError('Food id must not be empty.');
    }
    if (food.name.trim().isEmpty) {
      throw ArgumentError('Food name must not be empty.');
    }
    if (!food.servingSizeGrams.isFinite || food.servingSizeGrams <= 0) {
      throw ArgumentError('Serving size must be greater than zero.');
    }
    _validateNutrition(food.nutrition);
  }

  void _validateExercise(Exercise exercise) {
    if (exercise.id.trim().isEmpty) {
      throw ArgumentError('Exercise id must not be empty.');
    }
    if (exercise.name.trim().isEmpty) {
      throw ArgumentError('Exercise name must not be empty.');
    }
    if (exercise.description.trim().isEmpty) {
      throw ArgumentError('Exercise description must not be empty.');
    }
    if (exercise.instruction.trim().isEmpty) {
      throw ArgumentError('Exercise instruction must not be empty.');
    }
    if (exercise.muscleGroups.isEmpty) {
      throw ArgumentError('Exercise must have at least one muscle group.');
    }
  }

  void _validateTrainingPlan(TrainingPlan plan) {
    if (plan.id.trim().isEmpty) {
      throw ArgumentError('Training plan id must not be empty.');
    }
    if (plan.name.trim().isEmpty) {
      throw ArgumentError('Training plan name must not be empty.');
    }
    if (plan.exercises.isEmpty) {
      throw ArgumentError('Training plan must have at least one exercise.');
    }
    for (final exercise in plan.exercises) {
      final measurementType = _requireExerciseMeasurementType(
        exercise.exerciseId,
      );
      _validateTrainingExercise(exercise, measurementType);
    }
  }

  void _validateTrainingExercise(
    TrainingExercise exercise,
    ExerciseMeasurementType measurementType,
  ) {
    _validateOptionalNonNegative(exercise.sets, 'sets');
    _validateOptionalNonNegative(exercise.reps, 'reps');
    _validateOptionalNonNegative(exercise.weightGrams, 'weightGrams');
    _validateOptionalNonNegative(exercise.durationSeconds, 'durationSeconds');
    _validateOptionalNonNegative(exercise.distanceMeters, 'distanceMeters');
    _validateOptionalNonNegative(
      exercise.assistanceWeightGrams,
      'assistanceWeightGrams',
    );

    switch (measurementType) {
      case ExerciseMeasurementType.strength:
        _requireAbsent(exercise.durationSeconds, 'durationSeconds');
        _requireAbsent(exercise.distanceMeters, 'distanceMeters');
        _requireAbsent(exercise.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.bodyweight:
        _requireAbsent(exercise.weightGrams, 'weightGrams');
        _requireAbsent(exercise.durationSeconds, 'durationSeconds');
        _requireAbsent(exercise.distanceMeters, 'distanceMeters');
        _requireAbsent(exercise.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.duration:
        _requireAbsent(exercise.reps, 'reps');
        _requireAbsent(exercise.weightGrams, 'weightGrams');
        _requireAbsent(exercise.distanceMeters, 'distanceMeters');
        _requireAbsent(exercise.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.weightedDuration:
        _requireAbsent(exercise.reps, 'reps');
        _requireAbsent(exercise.distanceMeters, 'distanceMeters');
        _requireAbsent(exercise.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.cardio:
        _requireAbsent(exercise.reps, 'reps');
        _requireAbsent(exercise.weightGrams, 'weightGrams');
        _requireAbsent(exercise.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.assisted:
        _requireAbsent(exercise.weightGrams, 'weightGrams');
        _requireAbsent(exercise.durationSeconds, 'durationSeconds');
        _requireAbsent(exercise.distanceMeters, 'distanceMeters');
        break;
    }
  }

  void _validateWorkoutSetLog(
    WorkoutSetLog setLog,
    ExerciseMeasurementType measurementType,
  ) {
    _validateOptionalNonNegative(setLog.reps, 'reps');
    _validateOptionalNonNegative(setLog.weightGrams, 'weightGrams');
    _validateOptionalNonNegative(setLog.durationSeconds, 'durationSeconds');
    _validateOptionalNonNegative(setLog.distanceMeters, 'distanceMeters');
    _validateOptionalNonNegative(
      setLog.assistanceWeightGrams,
      'assistanceWeightGrams',
    );

    switch (measurementType) {
      case ExerciseMeasurementType.strength:
        _requirePresent(setLog.reps, 'reps');
        _requirePresent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.durationSeconds, 'durationSeconds');
        _requireAbsent(setLog.distanceMeters, 'distanceMeters');
        _requireAbsent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.bodyweight:
        _requirePresent(setLog.reps, 'reps');
        _requireAbsent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.durationSeconds, 'durationSeconds');
        _requireAbsent(setLog.distanceMeters, 'distanceMeters');
        _requireAbsent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.duration:
        _requirePresent(setLog.durationSeconds, 'durationSeconds');
        _requireAbsent(setLog.reps, 'reps');
        _requireAbsent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.distanceMeters, 'distanceMeters');
        _requireAbsent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.weightedDuration:
        _requirePresent(setLog.durationSeconds, 'durationSeconds');
        _requirePresent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.reps, 'reps');
        _requireAbsent(setLog.distanceMeters, 'distanceMeters');
        _requireAbsent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.cardio:
        _requireAnyPresent([
          setLog.durationSeconds,
          setLog.distanceMeters,
        ], 'durationSeconds or distanceMeters');
        _requireAbsent(setLog.reps, 'reps');
        _requireAbsent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        break;
      case ExerciseMeasurementType.assisted:
        _requirePresent(setLog.reps, 'reps');
        _requirePresent(setLog.assistanceWeightGrams, 'assistanceWeightGrams');
        _requireAbsent(setLog.weightGrams, 'weightGrams');
        _requireAbsent(setLog.durationSeconds, 'durationSeconds');
        _requireAbsent(setLog.distanceMeters, 'distanceMeters');
        break;
    }
  }

  void _validateOptionalNonNegative(double? value, String name) {
    if (value == null) {
      return;
    }
    if (!value.isFinite || value < 0) {
      throw ArgumentError('$name must be finite and non-negative.');
    }
  }

  ExerciseMeasurementType _requireExerciseMeasurementType(String exerciseId) {
    final exercise = _exercises[exerciseId];
    if (exercise == null) {
      throw ArgumentError('Missing exercise id: $exerciseId');
    }
    return exercise.measurementType;
  }

  void _requirePresent(double? value, String name) {
    if (value == null) {
      throw ArgumentError('$name is required for this exercise type.');
    }
  }

  void _requireAbsent(double? value, String name) {
    if (value != null) {
      throw ArgumentError('$name is not allowed for this exercise type.');
    }
  }

  void _requireAnyPresent(List<double?> values, String names) {
    if (values.every((value) => value == null)) {
      throw ArgumentError('$names is required for this exercise type.');
    }
  }

  void _validateDish(DishItem dish) {
    if (dish.id.trim().isEmpty) {
      throw ArgumentError('Dish id must not be empty.');
    }
    if (dish.name.trim().isEmpty) {
      throw ArgumentError('Dish name must not be empty.');
    }
    if (!dish.servingSizeGrams.isFinite || dish.servingSizeGrams <= 0) {
      throw ArgumentError('Serving size must be greater than zero.');
    }
    if (dish.components.isEmpty) {
      throw ArgumentError('Dish must have at least one component.');
    }
    for (final component in dish.components) {
      if (!component.grams.isFinite || component.grams <= 0) {
        throw ArgumentError('Dish component grams must be greater than zero.');
      }
      if (component.itemId != dish.id &&
          !_catalog.containsKey(component.itemId)) {
        throw ArgumentError('Missing item id: ${component.itemId}');
      }
    }

    final prospectiveCatalog = Map<String, CatalogItem>.from(_catalog);
    prospectiveCatalog[dish.id] = CatalogItem.dish(dish);
    _validateNoDishCycle(dish.id, prospectiveCatalog);
  }

  void _validateNutrition(NutritionValues nutrition) {
    if (!nutrition.calories.isFinite ||
        !nutrition.protein.isFinite ||
        !nutrition.fat.isFinite ||
        !nutrition.carbs.isFinite ||
        nutrition.calories < 0 ||
        nutrition.protein < 0 ||
        nutrition.fat < 0 ||
        nutrition.carbs < 0) {
      throw ArgumentError('Nutrition values must be non-negative.');
    }
  }

  bool _isReferencedByAnyDish(String targetId) {
    for (final item in _catalog.values) {
      if (!item.isDish) {
        continue;
      }
      if (_dishReferencesTarget(item.dish!, targetId, <String>{})) {
        return true;
      }
    }
    return false;
  }

  bool _isReferencedByAnyTrainingPlan(String targetId) {
    for (final plan in _trainingPlans) {
      for (final exercise in plan.exercises) {
        if (exercise.exerciseId == targetId) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isReferencedByActiveWorkout(String exerciseId) {
    final activeSession = _activeWorkoutSession;
    if (activeSession == null) {
      return false;
    }
    return activeSession.results.any(
      (result) => result.exerciseId == exerciseId,
    );
  }

  bool _isReferencedByCompletedWorkoutHistory(String exerciseId) {
    return _completedWorkoutSessions.any(
      (session) =>
          session.results.any((result) => result.exerciseId == exerciseId),
    );
  }

  bool _hasWorkoutHistoryForExercise(String exerciseId) {
    final activeSession = _activeWorkoutSession;
    if (activeSession != null &&
        activeSession.results.any(
          (result) => result.exerciseId == exerciseId,
        )) {
      return true;
    }
    return _completedWorkoutSessions.any(
      (session) =>
          session.results.any((result) => result.exerciseId == exerciseId),
    );
  }

  void _validateWorkoutSession(WorkoutSession session) {
    for (final result in session.results) {
      final measurementType = _requireExerciseMeasurementType(
        result.exerciseId,
      );
      if (result.target.exerciseId != result.exerciseId) {
        throw ArgumentError(
          'Workout result target must reference the same exercise id.',
        );
      }
      _validateTrainingExercise(result.target, measurementType);
      for (final setLog in result.setLogs) {
        _validateWorkoutSetLog(setLog, measurementType);
      }
    }
  }

  bool _dishReferencesTarget(
    DishItem dish,
    String targetId,
    Set<String> visited,
  ) {
    if (!visited.add(dish.id)) {
      return false;
    }
    for (final component in dish.components) {
      if (component.itemId == targetId) {
        return true;
      }
      final next = _catalog[component.itemId];
      if (next != null && next.isDish) {
        if (_dishReferencesTarget(next.dish!, targetId, visited)) {
          return true;
        }
      }
    }
    return false;
  }

  void _validateNoDishCycle(
    String rootId,
    Map<String, CatalogItem> catalog, [
    Set<String>? visiting,
    Set<String>? visited,
  ]) {
    final activeVisiting = visiting ?? <String>{};
    final activeVisited = visited ?? <String>{};
    if (activeVisiting.contains(rootId)) {
      throw ArgumentError('Dish cycle detected.');
    }
    if (activeVisited.contains(rootId)) {
      return;
    }
    final item = catalog[rootId];
    if (item == null || !item.isDish) {
      activeVisited.add(rootId);
      return;
    }
    activeVisiting.add(rootId);
    for (final component in item.dish!.components) {
      final next = catalog[component.itemId];
      if (next == null) {
        continue;
      }
      if (next.isDish) {
        _validateNoDishCycle(
          component.itemId,
          catalog,
          activeVisiting,
          activeVisited,
        );
      }
      if (component.itemId == rootId) {
        throw ArgumentError('Dish cycle detected.');
      }
    }
    activeVisiting.remove(rootId);
    activeVisited.add(rootId);
  }

  String _nextMealEntryId() {
    _mealEntryCounter += 1;
    return 'meal-entry-${_mealEntryCounter.toString()}';
  }

  String _nextWorkoutSessionId() {
    _workoutSessionCounter += 1;
    return 'workout-session-${_workoutSessionCounter.toString()}';
  }

  DishItem _freezeDish(DishItem dish) {
    return DishItem(
      id: dish.id,
      name: dish.name,
      description: dish.description,
      servingSizeGrams: dish.servingSizeGrams,
      components: List<DishComponent>.unmodifiable(
        List<DishComponent>.of(dish.components),
      ),
    );
  }

  Exercise _freezeExercise(Exercise exercise) {
    return Exercise(
      id: exercise.id,
      name: exercise.name,
      description: exercise.description,
      instruction: exercise.instruction,
      muscleGroups: List<MuscleGroup>.unmodifiable(
        List<MuscleGroup>.of(exercise.muscleGroups),
      ),
      measurementType: exercise.measurementType,
    );
  }

  TrainingPlan _freezeTrainingPlan(TrainingPlan plan) {
    return TrainingPlan(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      exercises: List<TrainingExercise>.unmodifiable(
        List<TrainingExercise>.of(plan.exercises),
      ),
    );
  }

  String _formatCompactNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class MealHistoryGroup {
  const MealHistoryGroup({required this.date, required this.entries});

  final DateTime date;
  final List<MealEntry> entries;
}

class WorkoutExerciseHistoryGroup {
  const WorkoutExerciseHistoryGroup({
    required this.session,
    required this.results,
  });

  final WorkoutSession session;
  final List<WorkoutExerciseResult> results;

  WorkoutExerciseResult get result => results.first;
}
