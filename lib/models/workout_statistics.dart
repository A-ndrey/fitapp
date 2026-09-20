import 'exercise.dart';
import 'workout_session.dart';

enum WorkoutPeriodType { week, month }

/// A local calendar interval, including start and excluding end.
class WorkoutPeriod {
  const WorkoutPeriod._(this.type, this.start, this.end);

  factory WorkoutPeriod.containing(DateTime date, WorkoutPeriodType type) {
    final local = date.toLocal();
    final start = type == WorkoutPeriodType.week
        ? DateTime(local.year, local.month, local.day - local.weekday + 1)
        : DateTime(local.year, local.month);
    final end = type == WorkoutPeriodType.week
        ? DateTime(start.year, start.month, start.day + 7)
        : DateTime(start.year, start.month + 1);
    return WorkoutPeriod._(type, start, end);
  }

  final WorkoutPeriodType type;
  final DateTime start;
  final DateTime end;

  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  WorkoutPeriod shift(int offset) => WorkoutPeriod.containing(
    type == WorkoutPeriodType.week
        ? DateTime(start.year, start.month, start.day + 7 * offset)
        : DateTime(start.year, start.month + offset),
    type,
  );

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
}

enum MuscleRegion {
  chest,
  back,
  shoulders,
  arms,
  core,
  glutes,
  legs;

  static MuscleRegion? forGroup(MuscleGroup group) => switch (group) {
    MuscleGroup.chest => chest,
    MuscleGroup.back => back,
    MuscleGroup.shoulders => shoulders,
    MuscleGroup.biceps || MuscleGroup.triceps || MuscleGroup.forearms => arms,
    MuscleGroup.core => core,
    MuscleGroup.glutes => glutes,
    MuscleGroup.legs ||
    MuscleGroup.quads ||
    MuscleGroup.hamstrings ||
    MuscleGroup.calves => legs,
    MuscleGroup.cardio || MuscleGroup.fullBody => null,
  };
}

/// Counts logged sets, deduplicating each exercise's groups and regions.
class WorkoutPeriodStats {
  WorkoutPeriodStats._({
    required this.completedCount,
    required this.totalDuration,
    required this.setCount,
    required this.unknownGroupSets,
    required Map<MuscleGroup, int> groupSets,
    required Map<MuscleRegion, int> regionSets,
  }) : groupSets = Map.unmodifiable(groupSets),
       regionSets = Map.unmodifiable(regionSets);

  factory WorkoutPeriodStats.calculate(
    Iterable<WorkoutSession> sessions,
    WorkoutPeriod period,
  ) {
    var completedCount = 0;
    var totalDuration = Duration.zero;
    var setCount = 0;
    var unknownGroupSets = 0;
    final groups = {for (final group in MuscleGroup.values) group: 0};
    final regions = {for (final region in MuscleRegion.values) region: 0};
    for (final session in sessions) {
      if (session.finishedAt == null || !period.contains(session.startedAt)) {
        continue;
      }
      completedCount++;
      totalDuration += session.duration;
      for (final result in session.results) {
        final count = result.setLogs.length;
        setCount += count;
        final muscleGroups = result.muscleGroups?.toSet() ?? <MuscleGroup>{};
        if (muscleGroups.isEmpty) unknownGroupSets += count;
        for (final group in muscleGroups) {
          groups[group] = groups[group]! + count;
        }
        final muscleRegions = muscleGroups
            .map(MuscleRegion.forGroup)
            .whereType<MuscleRegion>()
            .toSet();
        for (final region in muscleRegions) {
          regions[region] = regions[region]! + count;
        }
      }
    }
    return WorkoutPeriodStats._(
      completedCount: completedCount,
      totalDuration: totalDuration,
      setCount: setCount,
      unknownGroupSets: unknownGroupSets,
      groupSets: groups,
      regionSets: regions,
    );
  }

  final int completedCount;
  final Duration totalDuration;
  final int setCount;
  final int unknownGroupSets;
  final Map<MuscleGroup, int> groupSets;
  final Map<MuscleRegion, int> regionSets;

  /// Four equal rings with whole-number labels and a shared scale.
  int get radarMaximum {
    final largest = regionSets.values.fold(0, (a, b) => a > b ? a : b);
    return largest == 0 ? 4 : ((largest + 3) ~/ 4) * 4;
  }
}
