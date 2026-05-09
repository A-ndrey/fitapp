import '../../models/app_preferences.dart';
import '../../models/catalog_item.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import 'persisted_app_state.dart';

class PersistedAppStateCodec {
  static Object encode(PersistedAppState state) {
    return <String, Object?>{
      'userFoods': state.userFoods.map(_encodeFoodItem).toList(growable: false),
      'userDishes': state.userDishes
          .map(_encodeDishItem)
          .toList(growable: false),
      'userExercises': state.userExercises
          .map(_encodeExercise)
          .toList(growable: false),
      'userTrainingPlans': state.userTrainingPlans
          .map(_encodeTrainingPlan)
          .toList(growable: false),
      'mealEntries': state.mealEntries
          .map(_encodeMealEntry)
          .toList(growable: false),
      'preferences': _encodePreferences(state.preferences),
      'activeWorkoutSession': _encodeWorkoutSession(state.activeWorkoutSession),
      'completedWorkoutSessions': state.completedWorkoutSessions
          .map(_encodeWorkoutSession)
          .toList(growable: false),
      'mealEntryCounter': state.mealEntryCounter,
      'workoutSessionCounter': state.workoutSessionCounter,
    };
  }

  static PersistedAppState decode(Object encoded) {
    final payload = _asMap(encoded, 'PersistedAppState');

    final exercises = _readList(
      payload,
      'userExercises',
    ).map((entry) => _decodeExercise(entry)).toList(growable: false);
    final exerciseIds = exercises.map((exercise) => exercise.id).toSet();

    return PersistedAppState(
      userFoods: _readList(
        payload,
        'userFoods',
      ).map((entry) => _decodeFoodItem(entry)).toList(growable: false),
      userDishes: _readList(
        payload,
        'userDishes',
      ).map((entry) => _decodeDishItem(entry)).toList(growable: false),
      userExercises: exercises,
      userTrainingPlans: _readList(payload, 'userTrainingPlans')
          .map((entry) => _decodeTrainingPlan(entry, exerciseIds))
          .toList(growable: false),
      mealEntries: _readList(
        payload,
        'mealEntries',
      ).map((entry) => _decodeMealEntry(entry)).toList(growable: false),
      preferences: _decodePreferences(payload['preferences']),
      activeWorkoutSession: _decodeWorkoutSession(
        payload['activeWorkoutSession'],
      ),
      completedWorkoutSessions: _readList(
        payload,
        'completedWorkoutSessions',
      ).map((entry) => _decodeWorkoutSession(entry)!).toList(growable: false),
      mealEntryCounter: _readInt(payload, 'mealEntryCounter'),
      workoutSessionCounter: _readInt(payload, 'workoutSessionCounter'),
    );
  }

  static Map<String, Object?> _encodeFoodItem(FoodItem item) {
    return <String, Object?>{
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'servingSizeGrams': item.servingSizeGrams,
      'basis': item.basis.name,
      'nutrition': _encodeNutritionValues(item.nutrition),
    };
  }

  static FoodItem _decodeFoodItem(Object? encoded) {
    final payload = _asMap(encoded, 'FoodItem');
    return FoodItem(
      id: _readString(payload, 'id'),
      name: _readString(payload, 'name'),
      description: _readString(payload, 'description'),
      servingSizeGrams: _readDouble(payload, 'servingSizeGrams'),
      basis: _readEnum(
        _readString(payload, 'basis'),
        NutritionBasis.values,
        'FoodItem.basis',
      ),
      nutrition: _decodeNutritionValues(payload['nutrition']),
    );
  }

  static Map<String, Object?> _encodeDishItem(DishItem item) {
    return <String, Object?>{
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'servingSizeGrams': item.servingSizeGrams,
      'components': item.components
          .map(_encodeDishComponent)
          .toList(growable: false),
    };
  }

  static DishItem _decodeDishItem(Object? encoded) {
    final payload = _asMap(encoded, 'DishItem');
    return DishItem(
      id: _readString(payload, 'id'),
      name: _readString(payload, 'name'),
      description: _readString(payload, 'description'),
      servingSizeGrams: _readDouble(payload, 'servingSizeGrams'),
      components: _readList(
        payload,
        'components',
      ).map((entry) => _decodeDishComponent(entry)).toList(growable: false),
    );
  }

  static Map<String, Object?> _encodeDishComponent(DishComponent component) {
    return <String, Object?>{
      'itemId': component.itemId,
      'grams': component.grams,
    };
  }

  static DishComponent _decodeDishComponent(Object? encoded) {
    final payload = _asMap(encoded, 'DishComponent');
    return DishComponent(
      itemId: _readString(payload, 'itemId'),
      grams: _readDouble(payload, 'grams'),
    );
  }

  static Map<String, Object?> _encodeExercise(Exercise exercise) {
    return <String, Object?>{
      'id': exercise.id,
      'name': exercise.name,
      'description': exercise.description,
      'instruction': exercise.instruction,
      'muscleGroups': exercise.muscleGroups
          .map((group) => group.name)
          .toList(growable: false),
    };
  }

  static Exercise _decodeExercise(Object? encoded) {
    final payload = _asMap(encoded, 'Exercise');
    return Exercise(
      id: _readString(payload, 'id'),
      name: _readString(payload, 'name'),
      description: _readString(payload, 'description'),
      instruction: _readString(payload, 'instruction'),
      muscleGroups: _readList(payload, 'muscleGroups')
          .map(
            (entry) => _readEnum(
              _asString(entry, 'Exercise.muscleGroups'),
              MuscleGroup.values,
              'Exercise.muscleGroups',
            ),
          )
          .toList(growable: false),
    );
  }

  static Map<String, Object?> _encodeTrainingPlan(TrainingPlan plan) {
    return <String, Object?>{
      'id': plan.id,
      'name': plan.name,
      'description': plan.description,
      'exercises': plan.exercises
          .map(_encodeTrainingExercise)
          .toList(growable: false),
    };
  }

  static TrainingPlan _decodeTrainingPlan(
    Object? encoded,
    Set<String> exerciseIds,
  ) {
    final payload = _asMap(encoded, 'TrainingPlan');
    final exercises = _readList(
      payload,
      'exercises',
    ).map((entry) => _decodeTrainingExercise(entry)).toList(growable: false);

    for (final exercise in exercises) {
      if (!exerciseIds.contains(exercise.exerciseId)) {
        throw FormatException(
          'TrainingPlan references unknown exerciseId "${exercise.exerciseId}"',
        );
      }
    }

    return TrainingPlan(
      id: _readString(payload, 'id'),
      name: _readString(payload, 'name'),
      description: _readString(payload, 'description'),
      exercises: exercises,
    );
  }

  static Map<String, Object?> _encodeTrainingExercise(
    TrainingExercise exercise,
  ) {
    return <String, Object?>{
      'exerciseId': exercise.exerciseId,
      'sets': exercise.sets,
      'reps': exercise.reps,
      'weight': exercise.weight,
      'time': exercise.time,
      'unit': exercise.unit,
    };
  }

  static TrainingExercise _decodeTrainingExercise(Object? encoded) {
    final payload = _asMap(encoded, 'TrainingExercise');
    return TrainingExercise(
      exerciseId: _readString(payload, 'exerciseId'),
      sets: _readNullableDouble(payload, 'sets'),
      reps: _readNullableDouble(payload, 'reps'),
      weight: _readNullableDouble(payload, 'weight'),
      time: _readNullableDouble(payload, 'time'),
      unit: _readString(payload, 'unit'),
    );
  }

  static Map<String, Object?> _encodeMealEntry(MealEntry entry) {
    return <String, Object?>{
      'id': entry.id,
      'sourceItemId': entry.sourceItemId,
      'itemName': entry.itemName,
      'itemType': entry.itemType.name,
      'servingSizeGrams': entry.servingSizeGrams,
      'consumedGrams': entry.consumedGrams,
      'mode': entry.mode.name,
      'enteredQuantity': entry.enteredQuantity,
      'nutrition': _encodeNutritionValues(entry.nutrition),
    };
  }

  static MealEntry _decodeMealEntry(Object? encoded) {
    final payload = _asMap(encoded, 'MealEntry');
    return MealEntry(
      id: _readString(payload, 'id'),
      sourceItemId: _readString(payload, 'sourceItemId'),
      itemName: _readString(payload, 'itemName'),
      itemType: _readEnum(
        _readString(payload, 'itemType'),
        CatalogItemType.values,
        'MealEntry.itemType',
      ),
      servingSizeGrams: _readDouble(payload, 'servingSizeGrams'),
      consumedGrams: _readDouble(payload, 'consumedGrams'),
      mode: _readEnum(
        _readString(payload, 'mode'),
        MealEntryMode.values,
        'MealEntry.mode',
      ),
      enteredQuantity: _readDouble(payload, 'enteredQuantity'),
      nutrition: _decodeNutritionValues(payload['nutrition']),
    );
  }

  static Map<String, Object?> _encodePreferences(AppPreferences preferences) {
    return <String, Object?>{
      'appearance': preferences.appearance.name,
      'language': preferences.language.name,
      'workoutWeightUnit': preferences.workoutWeightUnit.name,
      'dishWeightUnit': preferences.dishWeightUnit.name,
      'heightUnit': preferences.heightUnit.name,
      'distanceUnit': preferences.distanceUnit.name,
    };
  }

  static AppPreferences _decodePreferences(Object? encoded) {
    final payload = _asMap(encoded, 'AppPreferences');
    return AppPreferences(
      appearance: _readEnum(
        _readString(payload, 'appearance'),
        AppearancePreference.values,
        'AppPreferences.appearance',
      ),
      language: _readEnum(
        _readString(payload, 'language'),
        LanguagePreference.values,
        'AppPreferences.language',
      ),
      workoutWeightUnit: _readEnum(
        _readString(payload, 'workoutWeightUnit'),
        WorkoutWeightUnit.values,
        'AppPreferences.workoutWeightUnit',
      ),
      dishWeightUnit: _readEnum(
        _readString(payload, 'dishWeightUnit'),
        DishWeightUnit.values,
        'AppPreferences.dishWeightUnit',
      ),
      heightUnit: _readEnum(
        _readString(payload, 'heightUnit'),
        HeightUnit.values,
        'AppPreferences.heightUnit',
      ),
      distanceUnit: _readEnum(
        _readString(payload, 'distanceUnit'),
        DistanceUnit.values,
        'AppPreferences.distanceUnit',
      ),
    );
  }

  static Object? _encodeWorkoutSession(WorkoutSession? session) {
    if (session == null) {
      return null;
    }

    return <String, Object?>{
      'id': session.id,
      'trainingPlanId': session.trainingPlanId,
      'trainingPlanName': session.trainingPlanName,
      'startedAt': session.startedAt.toIso8601String(),
      'finishedAt': session.finishedAt?.toIso8601String(),
      'results': session.results
          .map(_encodeWorkoutExerciseResult)
          .toList(growable: false),
    };
  }

  static WorkoutSession? _decodeWorkoutSession(Object? encoded) {
    if (encoded == null) {
      return null;
    }

    final payload = _asMap(encoded, 'WorkoutSession');
    return WorkoutSession(
      id: _readString(payload, 'id'),
      trainingPlanId: _readString(payload, 'trainingPlanId'),
      trainingPlanName: _readString(payload, 'trainingPlanName'),
      startedAt: _readDateTime(payload, 'startedAt'),
      finishedAt: _readNullableDateTime(payload, 'finishedAt'),
      results: _readList(payload, 'results')
          .map((entry) => _decodeWorkoutExerciseResult(entry))
          .toList(growable: false),
    );
  }

  static Map<String, Object?> _encodeWorkoutExerciseResult(
    WorkoutExerciseResult result,
  ) {
    return <String, Object?>{
      'exerciseId': result.exerciseId,
      'exerciseName': result.exerciseName,
      'target': _encodeTrainingExercise(result.target),
      'setLogs': result.setLogs
          .map(_encodeWorkoutSetLog)
          .toList(growable: false),
    };
  }

  static WorkoutExerciseResult _decodeWorkoutExerciseResult(Object? encoded) {
    final payload = _asMap(encoded, 'WorkoutExerciseResult');
    return WorkoutExerciseResult(
      exerciseId: _readString(payload, 'exerciseId'),
      exerciseName: _readString(payload, 'exerciseName'),
      target: _decodeTrainingExercise(payload['target']),
      setLogs: _readList(
        payload,
        'setLogs',
      ).map((entry) => _decodeWorkoutSetLog(entry)).toList(growable: false),
    );
  }

  static Map<String, Object?> _encodeWorkoutSetLog(WorkoutSetLog setLog) {
    return <String, Object?>{
      'reps': setLog.reps,
      'weight': setLog.weight,
      'time': setLog.time,
    };
  }

  static WorkoutSetLog _decodeWorkoutSetLog(Object? encoded) {
    final payload = _asMap(encoded, 'WorkoutSetLog');
    return WorkoutSetLog(
      reps: _readNullableDouble(payload, 'reps'),
      weight: _readNullableDouble(payload, 'weight'),
      time: _readNullableDouble(payload, 'time'),
    );
  }

  static Map<String, Object?> _encodeNutritionValues(NutritionValues values) {
    return <String, Object?>{
      'calories': values.calories,
      'protein': values.protein,
      'fat': values.fat,
      'carbs': values.carbs,
    };
  }

  static NutritionValues _decodeNutritionValues(Object? encoded) {
    final payload = _asMap(encoded, 'NutritionValues');
    return NutritionValues(
      calories: _readDouble(payload, 'calories'),
      protein: _readDouble(payload, 'protein'),
      fat: _readDouble(payload, 'fat'),
      carbs: _readDouble(payload, 'carbs'),
    );
  }

  static Map<String, Object?> _asMap(Object? value, String context) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, entry) =>
            MapEntry(_asString(key, '$context.key'), entry as Object?),
      );
    }
    throw FormatException('Expected $context to be a JSON object.');
  }

  static List<Object?> _readList(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    throw FormatException('Expected "$key" to be a JSON array.');
  }

  static String _readString(Map<String, Object?> payload, String key) {
    return _asString(payload[key], key);
  }

  static String _asString(Object? value, String context) {
    if (value is String) {
      return value;
    }
    throw FormatException('Expected "$context" to be a string.');
  }

  static double _readDouble(Map<String, Object?> payload, String key) {
    return _asDouble(payload[key], key);
  }

  static double? _readNullableDouble(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    return _asDouble(value, key);
  }

  static double _asDouble(Object? value, String context) {
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('Expected "$context" to be a number.');
  }

  static int _readInt(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected "$key" to be an integer.');
  }

  static DateTime _readDateTime(Map<String, Object?> payload, String key) {
    return _parseDateTime(payload[key], key);
  }

  static DateTime? _readNullableDateTime(
    Map<String, Object?> payload,
    String key,
  ) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    return _parseDateTime(value, key);
  }

  static DateTime _parseDateTime(Object? value, String context) {
    final raw = _asString(value, context);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Expected "$context" to be an ISO-8601 string.');
    }
    return parsed;
  }

  static T _readEnum<T extends Enum>(
    String encoded,
    List<T> values,
    String context,
  ) {
    for (final value in values) {
      if (value.name == encoded) {
        return value;
      }
    }
    throw FormatException('Unknown $context value "$encoded".');
  }
}
