import '../app_state_components.dart';
import 'persisted_app_state.dart';
import 'persisted_app_state_codec.dart';

/// Encodes independently persisted portions of [PersistedAppState].
class PersistedStateSlices {
  const PersistedStateSlices._();

  static Map<AppStateSlice, Object> encode(PersistedAppState state) {
    final root = Map<String, Object?>.from(
      PersistedAppStateCodec.encode(state) as Map,
    );
    return <AppStateSlice, Object>{
      AppStateSlice.foodLibrary: <String, Object?>{
        'userFoods': root['userFoods'],
        'userDishes': root['userDishes'],
      },
      AppStateSlice.trainingLibrary: <String, Object?>{
        'userExercises': root['userExercises'],
        'userTrainingPlans': root['userTrainingPlans'],
      },
      AppStateSlice.nutritionHistory: <String, Object?>{
        'mealEntries': root['mealEntries'],
        'mealEntryCounter': root['mealEntryCounter'],
      },
      AppStateSlice.workout: <String, Object?>{
        'activeWorkoutSession': root['activeWorkoutSession'],
        'completedWorkoutSessions': root['completedWorkoutSessions'],
        'workoutSessionCounter': root['workoutSessionCounter'],
      },
      AppStateSlice.preferences: <String, Object?>{
        'preferences': root['preferences'],
      },
    };
  }

  static PersistedAppState decode(
    Map<AppStateSlice, Object?> slices, {
    Set<String> knownExerciseIds = const {},
  }) {
    final root = Map<String, Object?>.from(
      PersistedAppStateCodec.encode(const PersistedAppState.empty()) as Map,
    );
    for (final slice in AppStateSlice.values) {
      final encoded = slices[slice];
      if (encoded is! Map) {
        throw FormatException('Missing persisted ${slice.name} slice.');
      }
      for (final entry in encoded.entries) {
        if (entry.key is! String) {
          throw FormatException('${slice.name} keys must be strings.');
        }
        root[entry.key as String] = entry.value;
      }
    }
    return PersistedAppStateCodec.decode(
      root,
      knownExerciseIds: knownExerciseIds,
    );
  }
}
