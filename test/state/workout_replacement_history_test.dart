import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_replacement_fixture.dart';

WorkoutSession historicalReplacement(
  String id,
  String exerciseId,
  int selectionDay, {
  String? originalId = 'bench',
  bool hasSets = true,
}) {
  final measurementType = switch (exerciseId) {
    'bench' || 'fly' => ExerciseMeasurementType.strength,
    'plank' => ExerciseMeasurementType.duration,
    _ => ExerciseMeasurementType.bodyweight,
  };
  final setLog = switch (measurementType) {
    ExerciseMeasurementType.strength => const WorkoutSetLog(
      reps: 8,
      weightGrams: 10000,
    ),
    ExerciseMeasurementType.duration => const WorkoutSetLog(
      durationSeconds: 30,
    ),
    _ => const WorkoutSetLog(reps: 8),
  };
  return WorkoutSession(
    id: id,
    trainingPlanId: 'plan-$id',
    trainingPlanName: 'Another plan $id',
    // Intentionally opposite to selection order.
    startedAt: DateTime.utc(2025, 12, 31 - selectionDay),
    finishedAt: DateTime.utc(2026, 2, 28 - selectionDay),
    results: [
      WorkoutExerciseResult(
        exerciseId: exerciseId,
        exerciseName: exerciseId,
        measurementType: measurementType,
        originalExerciseId: originalId,
        replacedAt: originalId == null
            ? null
            : DateTime.utc(2026, 1, selectionDay),
        target: TrainingExercise(exerciseId: exerciseId),
        setLogs: hasSets ? [setLog] : const [],
      ),
    ],
  );
}

void main() {
  test(
    'history is unique across plans and ordered by choice, not session time',
    () async {
      final store = workoutReplacementFixture();
      addTearDown(store.dispose);
      final sessions = [
        historicalReplacement('old-pushups', 'pushups', 1),
        historicalReplacement('fly', 'fly', 2),
        historicalReplacement('latest-pushups', 'pushups', 3),
        historicalReplacement('other-source', 'plank', 4, originalId: 'fly'),
        historicalReplacement('no-sets', 'plank', 5, hasSets: false),
        historicalReplacement('legacy', 'plank', 6, originalId: null),
        historicalReplacement('unavailable', 'deleted-exercise', 7),
        historicalReplacement('original', 'bench', 8),
      ];
      await store.applyExternalPersistedState(
        PersistedEntityBundle.decode({
          ...PersistedEntityBundle.encode(store.persistedSnapshot),
          for (final session in sessions)
            'workoutSessions/${session.id}':
                PersistedAppStateCodec.encodeWorkoutSession(session),
        }),
      );
      Iterable<String> choices(String originalId) =>
          store.previousReplacementsForExercise(originalId).map((e) => e.id);
      expect(choices('bench'), ['pushups', 'fly']);
      expect(choices('fly'), ['plank']);
      expect(choices('pushups'), isEmpty);

      store.deleteCompletedWorkoutSession('latest-pushups');
      expect(choices('bench'), ['fly', 'pushups']);
      store.deleteCompletedWorkoutSession('old-pushups');
      expect(choices('bench'), ['fly']);
      store.updateExercise(
        store.exerciseById('fly')!.copyWith(name: 'Renamed fly'),
      );
      expect(
        store.previousReplacementsForExercise('bench').single.name,
        'Renamed fly',
      );
      store.deleteExercise('fly');
      expect(choices('bench'), isEmpty);
    },
  );

  test(
    'legacy workout results decode without invented replacement history',
    () {
      final encoded = PersistedAppStateCodec.encodeWorkoutSession(
        historicalReplacement('legacy', 'pushups', 1),
      );
      final result = (encoded['results']! as List).single as Map;
      result.remove('originalExerciseId');
      result.remove('replacedAt');
      final decoded = PersistedAppStateCodec.decodeWorkoutSession(encoded);
      expect(decoded.results.single.exerciseId, 'pushups');
      expect(decoded.results.single.setLogs, hasLength(1));
      expect(decoded.results.single.originalExerciseId, isNull);
      expect(decoded.results.single.replacedAt, isNull);
    },
  );

  test(
    'synchronized workout deletions remove replacement contributions',
    () async {
      final store = workoutReplacementFixture();
      addTearDown(store.dispose);
      final session = historicalReplacement('completed', 'pushups', 1);
      final local = PersistedEntityBundle.decode({
        ...PersistedEntityBundle.encode(store.persistedSnapshot),
        'workoutSessions/${session.id}':
            PersistedAppStateCodec.encodeWorkoutSession(session),
      });
      await store.applyExternalPersistedState(local);
      expect(store.previousReplacementsForExercise('bench'), hasLength(1));
      final merged = PersistedEntityBundle.merge(
        local,
        store.persistedSnapshot,
        preferRemote: true,
        remoteEntityHashes: {'workoutSessions/${session.id}': 'deleted'},
      );
      await store.applyExternalPersistedState(merged);
      expect(store.previousReplacementsForExercise('bench'), isEmpty);
    },
  );
}
