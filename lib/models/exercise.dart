enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  forearms('Forearms'),
  core('Core'),
  glutes('Glutes'),
  legs('Legs'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  calves('Calves'),
  cardio('Cardio'),
  fullBody('Full body');

  const MuscleGroup(this.label);

  final String label;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instruction,
    required this.muscleGroups,
  });

  final String id;
  final String name;
  final String description;
  final String instruction;
  final List<MuscleGroup> muscleGroups;

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? instruction,
    List<MuscleGroup>? muscleGroups,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instruction: instruction ?? this.instruction,
      muscleGroups: muscleGroups ?? this.muscleGroups,
    );
  }
}
