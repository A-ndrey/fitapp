import 'training_plan.dart';

class WorkoutExerciseResult {
  const WorkoutExerciseResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.target,
    this.actualSets,
    this.actualReps,
    this.actualWeight,
    this.actualTime,
    required this.actualUnit,
  });

  final String exerciseId;
  final String exerciseName;
  final TrainingExercise target;
  final double? actualSets;
  final double? actualReps;
  final double? actualWeight;
  final double? actualTime;
  final String actualUnit;

  WorkoutExerciseResult copyWith({
    String? exerciseId,
    String? exerciseName,
    TrainingExercise? target,
    double? actualSets,
    double? actualReps,
    double? actualWeight,
    double? actualTime,
    String? actualUnit,
  }) {
    return WorkoutExerciseResult(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      target: target ?? this.target,
      actualSets: actualSets ?? this.actualSets,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      actualTime: actualTime ?? this.actualTime,
      actualUnit: actualUnit ?? this.actualUnit,
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
