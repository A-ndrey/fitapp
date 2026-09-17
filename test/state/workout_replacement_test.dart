import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_replacement_fixture.dart';

class _MemoryPersistence implements AppStorePersistence {
  Object? encoded;
  @override
  Future<PersistedAppState?> load() async =>
      encoded == null ? null : PersistedAppStateCodec.decode(encoded!);
  @override
  Future<void> save(PersistedAppState state) async {
    encoded = PersistedAppStateCodec.encode(state);
  }
}

void replaceFirst(AppStore store, {bool allowDuplicate = false}) {
  final session = store.activeWorkoutSession!;
  final replacement = store.exerciseById('pushups')!;
  store.replaceActiveWorkoutExercise(
    sessionId: session.id,
    resultIndex: 0,
    expectedResult: session.results.first,
    replacement: replacement,
    target: session.results.first.target.forReplacement(replacement),
    allowDuplicate: allowDuplicate,
  );
}

void main() {
  test(
    'replacement persists, syncs and completes without changing the plan',
    () async {
      final persistence = _MemoryPersistence();
      final store = workoutReplacementFixture(persistence: persistence);
      addTearDown(store.dispose);
      final original = store.activeWorkoutSession!;
      var workoutChanges = 0;
      var libraryChanges = 0;
      store.workoutState.addListener(() => workoutChanges++);
      store.trainingLibraryState.addListener(() => libraryChanges++);
      replaceFirst(store);
      expect(workoutChanges, 1);
      expect(libraryChanges, 0);
      final active = store.activeWorkoutSession!;
      expect(active.id, original.id);
      expect(active.startedAt, original.startedAt);
      expect(active.results.single.exerciseName, 'Pushups');
      expect(
        active.results.single.measurementType,
        ExerciseMeasurementType.bodyweight,
      );
      expect(active.results.single.target.exerciseId, 'pushups');
      expect(active.results.single.target.sets, 3);
      expect(active.results.single.target.reps, 8);
      expect(active.results.single.target.weightGrams, isNull);
      expect(original.results.single.exerciseId, 'bench');
      expect(
        store.trainingPlanById('plan')!.exercises.single.exerciseId,
        'bench',
      );
      await store.flushPersistence();
      final restored = await AppStore.hydrated(persistence: persistence);
      addTearDown(restored.dispose);
      expect(
        restored.activeWorkoutSession!.results.single.exerciseId,
        'pushups',
      );
      final syncState = PersistedEntityBundle.decode(
        PersistedEntityBundle.encode(restored.persistedSnapshot),
      );
      final remote = AppStore.empty();
      addTearDown(remote.dispose);
      await remote.applyExternalPersistedState(syncState);
      expect(remote.activeWorkoutSession!.results.single.target.reps, 8);
      remote.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(reps: 8),
      );
      final completed = remote.finishActiveWorkout();
      expect(completed.results.single.exerciseId, 'pushups');
      expect(completed.results.single.setLogs.single.reps, 8);
      expect(remote.completedWorkoutHistoryForExercise('bench'), isEmpty);
      expect(
        remote.completedWorkoutHistoryForExercise('pushups'),
        hasLength(1),
      );
      final completedSync = PersistedEntityBundle.decode(
        PersistedEntityBundle.encode(remote.persistedSnapshot),
      );
      expect(completedSync.activeWorkoutSession, isNull);
      expect(
        completedSync
            .completedWorkoutSessions
            .single
            .results
            .single
            .exerciseName,
        'Pushups',
      );
    },
  );

  test(
    'duplicate requires explicit confirmation and preserves the other entry',
    () {
      final store = workoutReplacementFixture(duplicate: true);
      addTearDown(store.dispose);
      store.addActiveWorkoutSet(
        resultIndex: 1,
        setLog: const WorkoutSetLog(reps: 12),
      );
      final other = store.activeWorkoutSession!.results[1];
      expect(() => replaceFirst(store), throwsStateError);
      expect(store.activeWorkoutSession!.results.first.exerciseId, 'bench');
      replaceFirst(store, allowDuplicate: true);
      expect(store.activeWorkoutSession!.results.map((r) => r.exerciseId), [
        'pushups',
        'pushups',
      ]);
      expect(store.activeWorkoutSession!.results[1], same(other));
      expect(store.activeWorkoutSession!.results.first.setLogs, isEmpty);
    },
  );

  test('logged sets and a read-only lease prevent replacement', () {
    final store = workoutReplacementFixture();
    addTearDown(store.dispose);
    final readOnly = ValueNotifier(true);
    addTearDown(readOnly.dispose);
    store.bindActiveWorkoutLeaseController(
      listenable: readOnly,
      isReadOnly: () => readOnly.value,
      takeOver: () async => false,
    );
    expect(() => replaceFirst(store), throwsStateError);
    readOnly.value = false;
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weightGrams: 60000),
    );
    expect(() => replaceFirst(store), throwsStateError);
    expect(store.activeWorkoutSession!.results.single.exerciseId, 'bench');
    expect(store.activeWorkoutSession!.results.single.setLogs, hasLength(1));
  });

  test(
    'stale entry, changed session and changed library selection are rejected',
    () {
      final store = workoutReplacementFixture();
      addTearDown(store.dispose);
      final original = store.activeWorkoutSession!;
      final replacement = store.exerciseById('pushups')!;
      void saveOriginal() => store.replaceActiveWorkoutExercise(
        sessionId: original.id,
        resultIndex: 0,
        expectedResult: original.results.first,
        replacement: replacement,
        target: const TrainingExercise(exerciseId: 'pushups'),
      );
      store.updateExercise(replacement.copyWith(name: 'Updated pushups'));
      expect(saveOriginal, throwsStateError);
      replaceFirst(store);
      expect(saveOriginal, throwsStateError);
      store.finishActiveWorkout();
      expect(saveOriginal, throwsStateError);
      store.startWorkout(trainingPlanId: 'plan');
      expect(saveOriginal, throwsStateError);
      expect(store.activeWorkoutSession!.results.single.exerciseId, 'bench');
    },
  );

  test(
    'rejects invalid targets and self replacement without mutating state',
    () {
      final store = workoutReplacementFixture();
      addTearDown(store.dispose);
      final session = store.activeWorkoutSession!;
      void save(Exercise exercise, TrainingExercise target) =>
          store.replaceActiveWorkoutExercise(
            sessionId: session.id,
            resultIndex: 0,
            expectedResult: session.results.first,
            replacement: exercise,
            target: target,
          );
      expect(
        () => save(store.exerciseById('bench')!, session.results.first.target),
        throwsArgumentError,
      );
      expect(
        () => save(
          store.exerciseById('pushups')!,
          const TrainingExercise(exerciseId: 'bench'),
        ),
        throwsArgumentError,
      );
      expect(
        () => save(
          store.exerciseById('pushups')!,
          const TrainingExercise(exerciseId: 'pushups', weightGrams: 10),
        ),
        throwsArgumentError,
      );
      expect(
        () => save(
          store.exerciseById('pushups')!,
          const TrainingExercise(exerciseId: 'pushups', reps: -1),
        ),
        throwsArgumentError,
      );
      expect(store.activeWorkoutSession, same(session));
    },
  );

  test('replacement can be repeated until a set is logged', () {
    final store = workoutReplacementFixture();
    addTearDown(store.dispose);
    replaceFirst(store);
    final session = store.activeWorkoutSession!;
    final bench = store.exerciseById('bench')!;
    store.replaceActiveWorkoutExercise(
      sessionId: session.id,
      resultIndex: 0,
      expectedResult: session.results.single,
      replacement: bench,
      target: session.results.single.target.forReplacement(bench),
    );
    expect(store.activeWorkoutSession!.results.single.exerciseId, 'bench');
    expect(store.activeWorkoutSession!.results.single.target.reps, 8);
    expect(
      store.activeWorkoutSession!.results.single.target.weightGrams,
      isNull,
    );
  });

  test('compatible targets are retained for all six measurement types', () {
    const target = TrainingExercise(
      exerciseId: 'original',
      sets: 3,
      reps: 8,
      weightGrams: 60000,
      durationSeconds: 30,
      distanceMeters: 1000,
      assistanceWeightGrams: 20000,
    );
    final expected = <ExerciseMeasurementType, List<double?>>{
      ExerciseMeasurementType.strength: [3, 8, 60000, null, null, null],
      ExerciseMeasurementType.bodyweight: [3, 8, null, null, null, null],
      ExerciseMeasurementType.duration: [3, null, null, 30, null, null],
      ExerciseMeasurementType.weightedDuration: [
        3,
        null,
        60000,
        30,
        null,
        null,
      ],
      ExerciseMeasurementType.cardio: [null, null, null, 30, 1000, null],
      ExerciseMeasurementType.assisted: [3, 8, null, null, null, 20000],
    };
    for (final entry in expected.entries) {
      final result = target.forReplacement(
        Exercise(
          id: entry.key.name,
          name: 'Replacement',
          description: '',
          instruction: '',
          muscleGroups: const [],
          measurementType: entry.key,
        ),
      );
      expect(result.exerciseId, entry.key.name);
      expect(
        [
          result.sets,
          result.reps,
          result.weightGrams,
          result.durationSeconds,
          result.distanceMeters,
          result.assistanceWeightGrams,
        ],
        entry.value,
        reason: entry.key.name,
      );
    }
  });
}
