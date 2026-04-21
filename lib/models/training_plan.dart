class TrainingExercise {
  const TrainingExercise({
    required this.exerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.time,
    required this.unit,
  });

  final String exerciseId;
  final double? sets;
  final double? reps;
  final double? weight;
  final double? time;
  final String unit;

  TrainingExercise copyWith({
    String? exerciseId,
    double? sets,
    double? reps,
    double? weight,
    double? time,
    String? unit,
  }) {
    return TrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      time: time ?? this.time,
      unit: unit ?? this.unit,
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
