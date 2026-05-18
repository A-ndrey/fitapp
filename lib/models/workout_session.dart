import 'training_plan.dart';

const Object _workoutSetLogCopyWithSentinel = Object();

class WorkoutSetLog {
  const WorkoutSetLog({
    this.reps,
    this.weightGrams,
    this.durationSeconds,
    this.distanceMeters,
    this.assistanceWeightGrams,
  });

  final double? reps;
  final double? weightGrams;
  final double? durationSeconds;
  final double? distanceMeters;
  final double? assistanceWeightGrams;

  WorkoutSetLog copyWith({
    double? reps,
    Object? weightGrams = _workoutSetLogCopyWithSentinel,
    Object? durationSeconds = _workoutSetLogCopyWithSentinel,
    Object? distanceMeters = _workoutSetLogCopyWithSentinel,
    Object? assistanceWeightGrams = _workoutSetLogCopyWithSentinel,
  }) {
    return WorkoutSetLog(
      reps: reps ?? this.reps,
      weightGrams: identical(weightGrams, _workoutSetLogCopyWithSentinel)
          ? this.weightGrams
          : weightGrams as double?,
      durationSeconds:
          identical(durationSeconds, _workoutSetLogCopyWithSentinel)
          ? this.durationSeconds
          : durationSeconds as double?,
      distanceMeters: identical(distanceMeters, _workoutSetLogCopyWithSentinel)
          ? this.distanceMeters
          : distanceMeters as double?,
      assistanceWeightGrams:
          identical(assistanceWeightGrams, _workoutSetLogCopyWithSentinel)
          ? this.assistanceWeightGrams
          : assistanceWeightGrams as double?,
    );
  }
}

class WorkoutExerciseResult {
  const WorkoutExerciseResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.target,
    required this.setLogs,
  });

  final String exerciseId;
  final String exerciseName;
  final TrainingExercise target;
  final List<WorkoutSetLog> setLogs;

  WorkoutExerciseResult copyWith({
    String? exerciseId,
    String? exerciseName,
    TrainingExercise? target,
    List<WorkoutSetLog>? setLogs,
  }) {
    return WorkoutExerciseResult(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      target: target ?? this.target,
      setLogs: setLogs ?? this.setLogs,
    );
  }
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.trainingPlanId,
    required this.trainingPlanName,
    required this.startedAt,
    this.finishedAt,
    required this.results,
  });

  final String id;
  final String trainingPlanId;
  final String trainingPlanName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExerciseResult> results;

  Duration get duration {
    final end = finishedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  WorkoutSession copyWith({
    String? id,
    String? trainingPlanId,
    String? trainingPlanName,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<WorkoutExerciseResult>? results,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      trainingPlanId: trainingPlanId ?? this.trainingPlanId,
      trainingPlanName: trainingPlanName ?? this.trainingPlanName,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      results: results ?? this.results,
    );
  }
}

class WorkoutStats {
  const WorkoutStats({
    required this.completedCount,
    required this.totalDuration,
    required this.latestSession,
  });

  final int completedCount;
  final Duration totalDuration;
  final WorkoutSession? latestSession;
}
