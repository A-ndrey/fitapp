const Object _trainingExerciseCopyWithSentinel = Object();

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
    double? reps,
    Object? weightGrams = _trainingExerciseCopyWithSentinel,
    Object? durationSeconds = _trainingExerciseCopyWithSentinel,
    Object? distanceMeters = _trainingExerciseCopyWithSentinel,
    Object? assistanceWeightGrams = _trainingExerciseCopyWithSentinel,
  }) {
    return TrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightGrams: identical(weightGrams, _trainingExerciseCopyWithSentinel)
          ? this.weightGrams
          : weightGrams as double?,
      durationSeconds:
          identical(durationSeconds, _trainingExerciseCopyWithSentinel)
          ? this.durationSeconds
          : durationSeconds as double?,
      distanceMeters:
          identical(distanceMeters, _trainingExerciseCopyWithSentinel)
          ? this.distanceMeters
          : distanceMeters as double?,
      assistanceWeightGrams:
          identical(assistanceWeightGrams, _trainingExerciseCopyWithSentinel)
          ? this.assistanceWeightGrams
          : assistanceWeightGrams as double?,
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
