import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/models/workout_statistics.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/app_store_persistence.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/workout_replacement_fixture.dart';

void main() {
  test('calendar weeks start Monday and cross month and year boundaries', () {
    final week = WorkoutPeriod.containing(
      DateTime(2027, 1, 3, 23, 59),
      WorkoutPeriodType.week,
    );
    expect(week.start, DateTime(2026, 12, 28));
    expect(week.lastDay, DateTime(2027, 1, 3));
    expect(week.end, DateTime(2027, 1, 4));
    expect(week.contains(week.start.toUtc()), isTrue);
    expect(
      week.contains(week.start.subtract(const Duration(microseconds: 1))),
      isFalse,
    );
    expect(week.contains(week.end), isFalse);
    expect(week.shift(1).start, DateTime(2027, 1, 4));
    expect(week.shift(-1).start, DateTime(2026, 12, 21));
  });

  test('calendar months handle leap days and shifts from long months', () {
    final month = WorkoutPeriod.containing(
      DateTime(2028, 3, 31),
      WorkoutPeriodType.month,
    ).shift(-1);
    expect(month.start, DateTime(2028, 2));
    expect(month.lastDay, DateTime(2028, 2, 29));
    expect(month.shift(-2).start, DateTime(2027, 12));
    final dstWeek = WorkoutPeriod.containing(
      DateTime(2026, 3, 29, 23),
      WorkoutPeriodType.week,
    );
    expect(dstWeek.shift(1).start, DateTime(2026, 3, 30));
    expect(dstWeek.end.hour, 0);
  });

  test('counts actual sets once per group and once per merged region', () {
    final session = _session(DateTime(2026, 9, 14), [
      _result([
        MuscleGroup.chest,
        MuscleGroup.biceps,
        MuscleGroup.forearms,
        MuscleGroup.chest,
      ], sets: 3),
      _result([
        MuscleGroup.legs,
        MuscleGroup.quads,
        MuscleGroup.calves,
        MuscleGroup.glutes,
      ], sets: 2),
      _result([MuscleGroup.cardio, MuscleGroup.fullBody], sets: 1),
      _result([], sets: 2),
      _result(null, sets: 1),
    ]);
    final stats = WorkoutPeriodStats.calculate([session], _week);
    expect(stats.completedCount, 1);
    expect(stats.totalDuration, const Duration(minutes: 45));
    expect(stats.setCount, 9);
    expect(stats.regionSets[MuscleRegion.arms], 3);
    expect(stats.regionSets[MuscleRegion.chest], 3);
    expect(stats.regionSets[MuscleRegion.legs], 2);
    expect(stats.regionSets[MuscleRegion.glutes], 2);
    expect(stats.groupSets[MuscleGroup.biceps], 3);
    expect(stats.groupSets[MuscleGroup.forearms], 3);
    expect(stats.groupSets[MuscleGroup.cardio], 1);
    expect(stats.unknownGroupSets, 3);
    expect(stats.radarMaximum, 4);
  });

  test(
    'filters completed sessions by start including boundary-crossing sessions',
    () {
      final stats = WorkoutPeriodStats.calculate([
        _session(DateTime(2026, 9, 13, 23, 50), [
          _result([MuscleGroup.chest]),
        ]),
        _session(DateTime(2026, 9, 14), [
          _result([MuscleGroup.chest]),
        ]),
        _session(DateTime(2026, 9, 20, 23, 50), [
          _result([MuscleGroup.back]),
        ]),
        _session(DateTime(2026, 9, 21), [
          _result([MuscleGroup.legs]),
        ]),
        _session(DateTime(2026, 9, 15), [], active: true),
        _session(DateTime(2026, 9, 16), []),
      ], _week);
      expect(stats.completedCount, 3);
      expect(stats.totalDuration, const Duration(minutes: 135));
      expect(stats.setCount, 2);
      expect(stats.regionSets[MuscleRegion.legs], 0);
      final empty = WorkoutPeriodStats.calculate([], _week);
      expect(empty.setCount, 0);
      expect(empty.totalDuration, Duration.zero);
      expect(empty.radarMaximum, 4);
    },
  );

  test(
    'snapshots survive set changes, exercise edits, deletion and local reload',
    () async {
      final persistence = _MemoryPersistence();
      final store = workoutReplacementFixture(persistence: persistence);
      addTearDown(store.dispose);
      store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(reps: 8, weightGrams: 60000),
      );
      store.addActiveWorkoutSet(
        resultIndex: 0,
        setLog: const WorkoutSetLog(reps: 6, weightGrams: 60000),
      );
      store.removeActiveWorkoutSet(resultIndex: 0, setIndex: 1);
      store.updateExercise(
        store.exercises
            .firstWhere((e) => e.id == 'bench')
            .copyWith(muscleGroups: [MuscleGroup.shoulders]),
      );
      final completed = store.finishActiveWorkout();
      expect(completed.results.single.muscleGroups, [
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ]);
      store.deleteTrainingPlan('plan');
      store.deleteExercise('bench');
      await store.flushPersistence();
      final restored = await AppStore.hydrated(persistence: persistence);
      addTearDown(restored.dispose);
      final stats = restored.workoutStatisticsFor(
        WorkoutPeriod.containing(completed.startedAt, WorkoutPeriodType.week),
      );
      expect(stats.regionSets[MuscleRegion.chest], 1);
      expect(stats.regionSets[MuscleRegion.arms], 1);
      expect(stats.regionSets[MuscleRegion.shoulders], 0);
      expect(
        () => restored
            .completedWorkoutSessions
            .single
            .results
            .single
            .muscleGroups!
            .add(MuscleGroup.back),
        throwsUnsupportedError,
      );
    },
  );

  test('replacement snapshots the replacement muscle groups', () {
    final store = workoutReplacementFixture();
    addTearDown(store.dispose);
    final session = store.activeWorkoutSession!;
    store.replaceActiveWorkoutExercise(
      sessionId: session.id,
      resultIndex: 0,
      expectedResult: session.results.single,
      replacement: store.exercises.firstWhere((e) => e.id == 'plank'),
      target: const TrainingExercise(
        exerciseId: 'plank',
        sets: 2,
        durationSeconds: 30,
      ),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(durationSeconds: 30),
    );
    final completed = store.finishActiveWorkout();
    expect(completed.results.single.muscleGroups, [MuscleGroup.core]);
  });

  test(
    'legacy migration freezes known groups and leaves deleted groups unknown',
    () async {
      const exercise = Exercise(
        id: 'exercise',
        name: 'Exercise',
        description: 'Bodyweight exercise',
        instruction: 'Perform controlled repetitions.',
        muscleGroups: [MuscleGroup.back],
        measurementType: ExerciseMeasurementType.bodyweight,
      );
      final legacy = _state(
        [
          _session(DateTime(2026, 9, 14), [
            _result(null),
            _result(null).copyWith(
              exerciseId: 'deleted',
              target: const TrainingExercise(
                exerciseId: 'deleted',
                sets: 10,
                reps: 8,
              ),
            ),
            _result([]),
            _result([MuscleGroup.chest]),
          ]),
        ],
        exercises: [exercise],
      );
      final persistence = _MemoryPersistence()..state = legacy;
      final store = await AppStore.hydrated(persistence: persistence);
      addTearDown(store.dispose);
      expect(
        store.completedWorkoutSessions.single.results.map(
          (r) => r.muscleGroups,
        ),
        [
          [MuscleGroup.back],
          <MuscleGroup>[],
          <MuscleGroup>[],
          [MuscleGroup.chest],
        ],
      );
      store.updateExercise(exercise.copyWith(muscleGroups: [MuscleGroup.legs]));
      await store.flushPersistence();
      final restored = await AppStore.hydrated(persistence: persistence);
      addTearDown(restored.dispose);
      final stats = restored.workoutStatisticsFor(_week);
      expect(stats.regionSets[MuscleRegion.back], 1);
      expect(stats.regionSets[MuscleRegion.legs], 0);
      expect(stats.unknownGroupSets, 2);
    },
  );

  test('codec distinguishes absent snapshots from explicit unknown groups', () {
    final session = _session(DateTime(2026, 9, 14), [
      _result(null),
      _result([]),
      _result([MuscleGroup.back]),
    ]);
    final encoded = PersistedAppStateCodec.encodeWorkoutSession(session);
    final decoded = PersistedAppStateCodec.decodeWorkoutSession(encoded);
    expect(decoded.results.map((r) => r.muscleGroups), [
      null,
      <MuscleGroup>[],
      [MuscleGroup.back],
    ]);
    final results = encoded['results']! as List;
    (results.last as Map)['muscleGroups'] = ['not-a-muscle'];
    expect(
      () => PersistedAppStateCodec.decodeWorkoutSession(encoded),
      throwsFormatException,
    );
  });

  test(
    'persisted snapshots clone muscle lists and sync preserves attribution',
    () async {
      final groups = [MuscleGroup.chest, MuscleGroup.triceps];
      final state = _state([
        _session(DateTime(2026, 9, 14), [_result(groups), _result([])]),
      ]);
      groups.clear();
      expect(state.completedWorkoutSessions.single.results.first.muscleGroups, [
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ]);
      final transferred = PersistedEntityBundle.decode(
        PersistedEntityBundle.encode(state),
      );
      final merged = PersistedEntityBundle.merge(
        const PersistedAppState.empty(),
        transferred,
        preferRemote: true,
      );
      final store = AppStore.empty();
      addTearDown(store.dispose);
      await store.applyExternalPersistedState(merged);
      final stats = store.workoutStatisticsFor(_week);
      expect(stats.regionSets[MuscleRegion.chest], 1);
      expect(stats.regionSets[MuscleRegion.arms], 1);
      expect(stats.unknownGroupSets, 1);
    },
  );
}

final _week = WorkoutPeriod.containing(
  DateTime(2026, 9, 19),
  WorkoutPeriodType.week,
);

WorkoutExerciseResult _result(List<MuscleGroup>? groups, {int sets = 1}) =>
    WorkoutExerciseResult(
      exerciseId: 'exercise',
      exerciseName: 'Exercise',
      measurementType: ExerciseMeasurementType.bodyweight,
      muscleGroups: groups,
      target: const TrainingExercise(exerciseId: 'exercise', sets: 10, reps: 8),
      setLogs: List.generate(sets, (_) => const WorkoutSetLog(reps: 8)),
    );

WorkoutSession _session(
  DateTime start,
  List<WorkoutExerciseResult> results, {
  bool active = false,
}) => WorkoutSession(
  id: start.toIso8601String(),
  trainingPlanId: 'plan',
  trainingPlanName: 'Training',
  startedAt: start,
  finishedAt: active ? null : start.add(const Duration(minutes: 45)),
  results: results,
);

PersistedAppState _state(
  List<WorkoutSession> sessions, {
  List<Exercise> exercises = const [],
}) => PersistedAppState(
  userFoods: [],
  userDishes: [],
  userExercises: exercises,
  userTrainingPlans: [],
  mealEntries: [],
  preferences: const AppPreferences.defaults(),
  activeWorkoutSession: null,
  completedWorkoutSessions: sessions,
  mealEntryCounter: 0,
  workoutSessionCounter: 0,
);

class _MemoryPersistence implements AppStorePersistence {
  PersistedAppState? state;
  @override
  Future<PersistedAppState?> load() async => state == null
      ? null
      : PersistedAppStateCodec.decode(PersistedAppStateCodec.encode(state!));
  @override
  Future<void> save(PersistedAppState value) async => state = value;
}
