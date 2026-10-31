import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/library/library_formatters.dart';

/// Selects a library exercise using search and editable muscle filters.
class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({
    super.key,
    required this.exercises,
    this.initialMuscleGroups = const [],
    this.previousReplacementIds,
  });

  final List<Exercise> exercises;
  final List<MuscleGroup> initialMuscleGroups;

  /// Most recent first. Null keeps the regular picker without section headings.
  /// These exercises bypass muscle filters, but still match the search query.
  final List<String>? previousReplacementIds;

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
    final l10n = AppLocalizations.of(context);
    final available = {
      for (final exercise in widget.exercises) exercise.id: exercise,
    };
    final previousIds = widget.previousReplacementIds?.toSet() ?? <String>{};
    final previous = <Exercise>[
      for (final id in previousIds)
        if (available[id] case final exercise?)
          if (query.isEmpty || _matchesExercise(exercise, query)) exercise,
    ];
    final exercises = widget.exercises
        .where((exercise) {
          if (previousIds.contains(exercise.id)) return false;
          final matchesQuery =
              query.isEmpty || _matchesExercise(exercise, query);
          final matchesMuscleGroups = _selectedMuscleGroups.every(
            exercise.muscleGroups.contains,
          );
          return matchesQuery && matchesMuscleGroups;
        })
        .toList(growable: false);
    final sections = <({String? title, List<Exercise> exercises})>[
      if (previous.isNotEmpty)
        (
          title:
              l10n?.exercisePickerPreviousReplacements ??
              'Previous replacements',
          exercises: previous,
        ),
      if (exercises.isNotEmpty)
        (
          title: widget.previousReplacementIds == null
              ? null
              : l10n?.exercisePickerOtherExercises ?? 'All other exercises',
          exercises: exercises,
        ),
    ];
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
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
                ),
              ),
              if (sections.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Text('No exercises match these filters'),
                  ),
                ),
              for (final section in sections) ...[
                if (section.title case final title?)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Semantics(
                        header: true,
                        child: SectionHeader(title: title),
                      ),
                    ),
                  ),
                SliverList.separated(
                  itemCount: section.exercises.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final exercise = section.exercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: _ExercisePickerResultSubtitle(
                        exercise: exercise,
                      ),
                      onTap: () => Navigator.of(context).pop(exercise),
                    );
                  },
                ),
              ],
            ],
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
