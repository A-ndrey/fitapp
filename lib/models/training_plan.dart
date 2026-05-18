class TrainingExercise {
  const TrainingExercise({
    required this.exerciseId,
    this.sets,
    this.reps,
    this.weightGrams,
    this.durationSeconds,
    this.distanceMeters,
    this.assistanceWeightGrams,
  });

  final String exerciseId;
  final double? sets;
  final double? reps;
  final double? weightGrams;
  final double? durationSeconds;
  final double? distanceMeters;
  final double? assistanceWeightGrams;

  TrainingExercise copyWith({
    String? exerciseId,
    double? sets,
    bool clearSets = false,
    double? reps,
    bool clearReps = false,
    double? weightGrams,
    bool clearWeightGrams = false,
    double? durationSeconds,
    bool clearDurationSeconds = false,
    double? distanceMeters,
    bool clearDistanceMeters = false,
    double? assistanceWeightGrams,
    bool clearAssistanceWeightGrams = false,
  }) {
    return TrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: clearSets ? null : (sets ?? this.sets),
      reps: clearReps ? null : (reps ?? this.reps),
      weightGrams: clearWeightGrams ? null : (weightGrams ?? this.weightGrams),
      durationSeconds: clearDurationSeconds
          ? null
          : (durationSeconds ?? this.durationSeconds),
      distanceMeters: clearDistanceMeters
          ? null
          : (distanceMeters ?? this.distanceMeters),
      assistanceWeightGrams: clearAssistanceWeightGrams
          ? null
          : (assistanceWeightGrams ?? this.assistanceWeightGrams),
    );
  }
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
  });

  final String id;
  final String name;
  final String description;
  final List<TrainingExercise> exercises;

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? description,
    List<TrainingExercise>? exercises,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
    );
  }
}
