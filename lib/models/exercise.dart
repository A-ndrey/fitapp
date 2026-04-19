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
  final List<String> muscleGroups;

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? instruction,
    List<String>? muscleGroups,
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
