import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../ui/library/library_formatters.dart';

/// Selects a library exercise using search and editable muscle filters.
class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.exercises,
    this.initialMuscleGroups = const [],
  });

  final List<Exercise> exercises;
  final List<MuscleGroup> initialMuscleGroups;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<MuscleGroup> _selectedMuscleGroups = <MuscleGroup>{};

  @override
  void initState() {
    super.initState();
    _selectedMuscleGroups.addAll(widget.initialMuscleGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final exercises = widget.exercises
        .where((exercise) {
          final matchesQuery =
              query.isEmpty || _matchesExercise(exercise, query);
          final matchesMuscleGroups = _selectedMuscleGroups.every(
            exercise.muscleGroups.contains,
          );
          return matchesQuery && matchesMuscleGroups;
        })
        .toList(growable: false);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: exercises.isEmpty ? 2 : exercises.length + 1,
            separatorBuilder: (context, index) =>
                index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search exercises',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MuscleGroup.values
                            .map((muscleGroup) {
                              final isSelected = _selectedMuscleGroups.contains(
                                muscleGroup,
                              );
                              return FilterChip(
                                label: Text(muscleGroup.label),
                                labelStyle: theme.textTheme.labelLarge
                                    ?.copyWith(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                checkmarkColor:
                                    theme.colorScheme.onPrimaryContainer,
                                selectedColor:
                                    theme.colorScheme.primaryContainer,
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedMuscleGroups.add(muscleGroup);
                                    } else {
                                      _selectedMuscleGroups.remove(muscleGroup);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ],
                  ),
                );
              }
              if (exercises.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Text('No exercises match these filters'),
                );
              }
              final exercise = exercises[index - 1];
              return ListTile(
                title: Text(exercise.name),
                subtitle: _ExercisePickerResultSubtitle(exercise: exercise),
                onTap: () => Navigator.of(context).pop(exercise),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _matchesExercise(Exercise exercise, String query) {
    return exercise.name.toLowerCase().contains(query) ||
        exercise.description.toLowerCase().contains(query) ||
        exercise.instruction.toLowerCase().contains(query) ||
        exercise.muscleGroups.any(
          (muscleGroup) => muscleGroup.label.toLowerCase().contains(query),
        );
  }
}

class _ExercisePickerResultSubtitle extends StatelessWidget {
  const _ExercisePickerResultSubtitle({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final description = exercise.description.trim();
    final muscleGroups = formatExerciseMuscleGroupSummaryLabel(
      exercise.muscleGroups,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(muscleGroups),
        if (description.isNotEmpty) Text(description),
      ],
    );
  }
}
