import 'dart:convert';

import '../../models/app_preferences.dart';
import '../persistence/persisted_app_state.dart';
import '../persistence/persisted_app_state_codec.dart';

/// Converts the application snapshot to independently synchronized entities.
class PersistedEntityBundle {
  const PersistedEntityBundle._();

  static const collections = <String>{
    'foods',
    'recipes',
    'exercises',
    'trainingPlans',
    'mealEntries',
    'workoutSessions',
    'runtime',
    'preferences',
  };

  static Map<String, Map<String, Object?>> encode(PersistedAppState state) {
    final entities = <String, Map<String, Object?>>{};
    for (final item in state.userFoods) {
      entities['foods/${item.id}'] = PersistedAppStateCodec.encodeFoodItem(
        item,
      );
    }
    for (final item in state.userDishes) {
      entities['recipes/${item.id}'] = PersistedAppStateCodec.encodeDishItem(
        item,
      );
    }
    for (final item in state.userExercises) {
      entities['exercises/${item.id}'] = PersistedAppStateCodec.encodeExercise(
        item,
      );
    }
    for (final item in state.userTrainingPlans) {
      entities['trainingPlans/${item.id}'] =
          PersistedAppStateCodec.encodeTrainingPlan(item);
    }
    for (final item in state.mealEntries) {
      entities['mealEntries/${item.id}'] =
          PersistedAppStateCodec.encodeMealEntry(item);
    }
    for (final item in state.completedWorkoutSessions) {
      entities['workoutSessions/${item.id}'] =
          PersistedAppStateCodec.encodeWorkoutSession(item);
    }
    final activeWorkout = state.activeWorkoutSession;
    if (activeWorkout != null) {
      entities['runtime/activeWorkout'] =
          PersistedAppStateCodec.encodeWorkoutSession(activeWorkout);
    }
    entities['preferences/current'] = PersistedAppStateCodec.encodePreferences(
      state.preferences,
    );
    return entities;
  }

  static PersistedAppState decode(
    Map<String, Map<String, Object?>> entities, {
    Set<String> knownExerciseIds = const {},
  }) {
    final foods = _decodeCollection(
      entities,
      'foods',
      PersistedAppStateCodec.decodeFoodItem,
    );
    final dishes = _decodeCollection(
      entities,
      'recipes',
      PersistedAppStateCodec.decodeDishItem,
    );
    final exercises = _decodeCollection(
      entities,
      'exercises',
      PersistedAppStateCodec.decodeExercise,
    );
    final exerciseIds = <String>{
      ...knownExerciseIds,
      ...exercises.map((exercise) => exercise.id),
    };
    final plans = _decodeCollection(
      entities,
      'trainingPlans',
      (encoded) =>
          PersistedAppStateCodec.decodeTrainingPlan(encoded, exerciseIds),
    );
    final meals = _decodeCollection(
      entities,
      'mealEntries',
      PersistedAppStateCodec.decodeMealEntry,
    );
    final workouts = _decodeCollection(
      entities,
      'workoutSessions',
      PersistedAppStateCodec.decodeWorkoutSession,
    );
    final activePayload = entities['runtime/activeWorkout'];
    final preferencesPayload = entities['preferences/current'];
    return PersistedAppState(
      userFoods: foods,
      userDishes: dishes,
      userExercises: exercises,
      userTrainingPlans: plans,
      mealEntries: meals,
      preferences: preferencesPayload == null
          ? const AppPreferences.defaults()
          : PersistedAppStateCodec.decodePreferences(preferencesPayload),
      activeWorkoutSession: activePayload == null
          ? null
          : PersistedAppStateCodec.decodeWorkoutSession(activePayload),
      completedWorkoutSessions: workouts,
      mealEntryCounter: 0,
      workoutSessionCounter: 0,
    );
  }

  static PersistedAppState merge(
    PersistedAppState local,
    PersistedAppState remote, {
    required bool preferRemote,
    bool? preferRemoteActiveWorkout,
    Map<String, String> remoteEntityHashes = const {},
    Set<String> localDeletedKeys = const {},
    AppPreferences? mergedPreferences,
  }) {
    final merged = PersistedAppState(
      userFoods: _mergeById(
        local.userFoods,
        remote.userFoods,
        (item) => item.id,
        preferRemote,
      ),
      userDishes: _mergeById(
        local.userDishes,
        remote.userDishes,
        (item) => item.id,
        preferRemote,
      ),
      userExercises: _mergeById(
        local.userExercises,
        remote.userExercises,
        (item) => item.id,
        preferRemote,
      ),
      userTrainingPlans: _mergeById(
        local.userTrainingPlans,
        remote.userTrainingPlans,
        (item) => item.id,
        preferRemote,
      ),
      mealEntries: _mergeById(
        local.mealEntries,
        remote.mealEntries,
        (item) => item.id,
        preferRemote,
      ),
      preferences:
          mergedPreferences ??
          (preferRemote ? remote.preferences : local.preferences),
      activeWorkoutSession: (preferRemoteActiveWorkout ?? preferRemote)
          ? remote.activeWorkoutSession
          : local.activeWorkoutSession,
      completedWorkoutSessions: _mergeById(
        local.completedWorkoutSessions,
        remote.completedWorkoutSessions,
        (item) => item.id,
        preferRemote,
      ),
      mealEntryCounter: _max(local.mealEntryCounter, remote.mealEntryCounter),
      workoutSessionCounter: _max(
        local.workoutSessionCounter,
        remote.workoutSessionCounter,
      ),
    );
    final deletedKeys =
        remoteEntityHashes.entries
            .where((entry) => entry.value == 'deleted')
            .map((entry) => entry.key)
            .toSet()
          ..addAll(localDeletedKeys);
    if (deletedKeys.isEmpty) {
      return merged;
    }
    return PersistedAppState(
      userFoods: merged.userFoods
          .where((item) => !deletedKeys.contains('foods/${item.id}'))
          .toList(growable: false),
      userDishes: merged.userDishes
          .where((item) => !deletedKeys.contains('recipes/${item.id}'))
          .toList(growable: false),
      userExercises: merged.userExercises
          .where((item) => !deletedKeys.contains('exercises/${item.id}'))
          .toList(growable: false),
      userTrainingPlans: merged.userTrainingPlans
          .where((item) => !deletedKeys.contains('trainingPlans/${item.id}'))
          .toList(growable: false),
      mealEntries: merged.mealEntries
          .where((item) => !deletedKeys.contains('mealEntries/${item.id}'))
          .toList(growable: false),
      preferences: deletedKeys.contains('preferences/current')
          ? const AppPreferences.defaults()
          : merged.preferences,
      activeWorkoutSession: deletedKeys.contains('runtime/activeWorkout')
          ? null
          : merged.activeWorkoutSession,
      completedWorkoutSessions: merged.completedWorkoutSessions
          .where((item) => !deletedKeys.contains('workoutSessions/${item.id}'))
          .toList(growable: false),
      mealEntryCounter: merged.mealEntryCounter,
      workoutSessionCounter: merged.workoutSessionCounter,
    );
  }

  static Map<String, String> hashes(PersistedAppState state) {
    return encode(state).map((key, value) => MapEntry(key, hashJson(value)));
  }

  static Map<String, String> preferenceGroupHashes(AppPreferences preferences) {
    final encoded = PersistedAppStateCodec.encodePreferences(preferences);
    return <String, String>{
      'appearance': hashJson(encoded['appearance']),
      'language': hashJson(encoded['language']),
      'units': hashJson(<String, Object?>{
        'workoutWeightUnit': encoded['workoutWeightUnit'],
        'dishWeightUnit': encoded['dishWeightUnit'],
        'heightUnit': encoded['heightUnit'],
        'distanceUnit': encoded['distanceUnit'],
      }),
      'nutritionTargets': hashJson(encoded['dailyMacroTargets']),
    };
  }

  static AppPreferences mergePreferences(
    AppPreferences local,
    AppPreferences remote, {
    required Map<String, String> previouslySyncedHashes,
    required bool preferRemote,
  }) {
    final localHashes = preferenceGroupHashes(local);
    final remoteHashes = preferenceGroupHashes(remote);
    bool useRemote(String group) {
      final previous = previouslySyncedHashes[group];
      final localChanged = previous == null || previous != localHashes[group];
      final remoteChanged = previous == null || previous != remoteHashes[group];
      if (localChanged != remoteChanged) {
        return remoteChanged;
      }
      return preferRemote;
    }

    return AppPreferences(
      appearance: useRemote('appearance')
          ? remote.appearance
          : local.appearance,
      language: useRemote('language') ? remote.language : local.language,
      workoutWeightUnit: useRemote('units')
          ? remote.workoutWeightUnit
          : local.workoutWeightUnit,
      dishWeightUnit: useRemote('units')
          ? remote.dishWeightUnit
          : local.dishWeightUnit,
      heightUnit: useRemote('units') ? remote.heightUnit : local.heightUnit,
      distanceUnit: useRemote('units')
          ? remote.distanceUnit
          : local.distanceUnit,
      dailyMacroTargets: useRemote('nutritionTargets')
          ? remote.dailyMacroTargets
          : local.dailyMacroTargets,
    );
  }

  static String snapshotHash(PersistedAppState state) {
    final entities = encode(state);
    final keys = entities.keys.toList(growable: false)..sort();
    return hashJson(<String, Object?>{
      for (final key in keys) key: entities[key],
    });
  }

  static String hashJson(Object? value) {
    final bytes = utf8.encode(jsonEncode(_canonicalizeJson(value)));
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Object? _canonicalizeJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) {
        if (key is! String) {
          throw const FormatException('JSON object keys must be strings.');
        }
        return key;
      }).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _canonicalizeJson(value[key]),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalizeJson).toList(growable: false);
    }
    return value;
  }

  static List<T> _decodeCollection<T>(
    Map<String, Map<String, Object?>> entities,
    String collection,
    T Function(Object?) decode,
  ) {
    final prefix = '$collection/';
    final matching =
        entities.entries
            .where((entry) => entry.key.startsWith(prefix))
            .toList(growable: false)
          ..sort((left, right) => left.key.compareTo(right.key));
    return matching.map((entry) => decode(entry.value)).toList(growable: false);
  }

  static List<T> _mergeById<T>(
    List<T> local,
    List<T> remote,
    String Function(T value) idOf,
    bool preferRemote,
  ) {
    final merged = <String, T>{};
    final first = preferRemote ? local : remote;
    final second = preferRemote ? remote : local;
    for (final value in first) {
      merged[idOf(value)] = value;
    }
    for (final value in second) {
      merged[idOf(value)] = value;
    }
    final ids = merged.keys.toList(growable: false)..sort();
    return ids.map((id) => merged[id]!).toList(growable: false);
  }

  static int _max(int left, int right) => left > right ? left : right;
}
