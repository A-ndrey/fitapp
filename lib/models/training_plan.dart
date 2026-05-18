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
    double? weightGrams,
    double? durationSeconds,
    double? distanceMeters,
    double? assistanceWeightGrams,
  }) {
    return TrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightGrams: weightGrams ?? this.weightGrams,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      assistanceWeightGrams:
          assistanceWeightGrams ?? this.assistanceWeightGrams,
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
