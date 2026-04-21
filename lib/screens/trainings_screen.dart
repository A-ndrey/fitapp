import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/training_plan.dart';
import '../state/app_store.dart';

enum _TrainingsView { plans, exercises }

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  _TrainingsView _selectedView = _TrainingsView.plans;

  AppStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Trainings')),
          floatingActionButton: FloatingActionButton(
            heroTag: 'trainings-action-fab',
            tooltip: _selectedView == _TrainingsView.plans
                ? 'Add training plan'
                : 'Add exercise',
            onPressed: _selectedView == _TrainingsView.plans
                ? () => _openPlanDialog(context)
                : () => _openExerciseDialog(context),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<_TrainingsView>(
                  segments: const [
                    ButtonSegment(
                      value: _TrainingsView.plans,
                      label: Text('Plans'),
                      icon: Icon(Icons.assignment_outlined),
                    ),
                    ButtonSegment(
                      value: _TrainingsView.exercises,
                      label: Text('Exercises'),
                      icon: Icon(Icons.fitness_center_outlined),
                    ),
                  ],
                  selected: <_TrainingsView>{_selectedView},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedView = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedView == _TrainingsView.plans)
                  _buildPlansView(context)
                else
                  _buildExercisesView(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlansView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Training plans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (store.trainingPlans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No training plans yet'),
          )
        else
          ...store.trainingPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text(plan.name),
                  subtitle: Text(_planSummary(plan)),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit ${plan.name}',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _openPlanDialog(context, initialPlan: plan),
                      ),
                      IconButton(
                        tooltip: 'Delete ${plan.name}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDeletePlan(context, plan),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExercisesView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (store.exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No exercises yet'),
          )
        else
          ...store.exercises.map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text(exercise.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(exercise.description),
                      Text(exercise.instruction),
                      Text(_summarizeMuscleGroups(exercise.muscleGroups)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit ${exercise.name}',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openExerciseDialog(
                          context,
                          initialExercise: exercise,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete ${exercise.name}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _confirmDeleteExercise(context, exercise),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openPlanDialog(
    BuildContext context, {
    TrainingPlan? initialPlan,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _TrainingPlanDialog(store: store, initialPlan: initialPlan);
      },
    );
  }

  Future<void> _openExerciseDialog(
    BuildContext context, {
    Exercise? initialExercise,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ExerciseDialog(store: store, initialExercise: initialExercise);
      },
    );
  }

  Future<void> _confirmDeletePlan(
    BuildContext context,
    TrainingPlan plan,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${plan.name}?'),
          content: const Text('This removes the training plan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || shouldDelete != true) {
      return;
    }
    try {
      store.deleteTrainingPlan(plan.id);
    } on ArgumentError catch (error) {
      _showSnackBar(context, error.message?.toString() ?? 'Could not delete.');
    } on StateError catch (error) {
      _showSnackBar(context, error.message);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    Exercise exercise,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${exercise.name}?'),
          content: const Text('This removes the exercise.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || shouldDelete != true) {
      return;
    }
    try {
      store.deleteExercise(exercise.id);
    } on ArgumentError catch (error) {
      _showSnackBar(context, error.message?.toString() ?? 'Could not delete.');
    } on StateError catch (error) {
      _showSnackBar(context, error.message);
    }
  }

  String _planSummary(TrainingPlan plan) {
    final exerciseCount = plan.exercises.length;
    final exerciseLabel = exerciseCount == 1
        ? '1 exercise'
        : '$exerciseCount exercises';
    final description = plan.description.trim();
    if (description.isEmpty) {
      return exerciseLabel;
    }
    return '$exerciseLabel\n$description';
  }

  String _summarizeMuscleGroups(List<MuscleGroup> muscleGroups) {
    if (muscleGroups.isEmpty) {
      return 'Muscles: -';
    }
    return muscleGroups.map((group) => group.label).join(', ');
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({required this.store, this.initialExercise});

  final AppStore store;
  final Exercise? initialExercise;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionController;
  final Set<MuscleGroup> _selectedMuscleGroups = <MuscleGroup>{};
  String? _errorText;

  bool get _isEditing => widget.initialExercise != null;

  @override
  void initState() {
    super.initState();
    final exercise = widget.initialExercise;
    _nameController = TextEditingController(text: exercise?.name ?? '');
    _descriptionController = TextEditingController(
      text: exercise?.description ?? '',
    );
    _instructionController = TextEditingController(
      text: exercise?.instruction ?? '',
    );
    _selectedMuscleGroups.addAll(exercise?.muscleGroups ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit exercise' : 'Add exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Exercise name'),
              ),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Exercise description',
                ),
              ),
              TextField(
                controller: _instructionController,
                textInputAction: TextInputAction.next,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Exercise instruction',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select muscle groups',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MuscleGroup.values
                    .map((muscleGroup) {
                      return FilterChip(
                        label: Text(muscleGroup.label),
                        selected: _selectedMuscleGroups.contains(muscleGroup),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMuscleGroups.add(muscleGroup);
                            } else {
                              _selectedMuscleGroups.remove(muscleGroup);
                            }
                            _errorText = null;
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveExercise,
          child: const Text('Save exercise'),
        ),
      ],
    );
  }

  void _saveExercise() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final instruction = _instructionController.text.trim();
    final muscleGroups = _selectedMuscleGroups.toList(growable: false);
    if (name.isEmpty ||
        description.isEmpty ||
        instruction.isEmpty ||
        muscleGroups.isEmpty) {
      setState(() {
        _errorText =
            'Enter a name, description, instruction, and muscle groups.';
      });
      return;
    }
    final id =
        widget.initialExercise?.id ?? widget.store.createIdFromName(name);
    if (id.isEmpty) {
      setState(() {
        _errorText = 'Enter a valid exercise name.';
      });
      return;
    }

    final exercise = Exercise(
      id: id,
      name: name,
      description: description,
      instruction: instruction,
      muscleGroups: muscleGroups,
    );

    try {
      if (_isEditing) {
        widget.store.updateExercise(exercise);
      } else {
        widget.store.createExercise(exercise);
      }
    } on ArgumentError catch (error) {
      setState(() {
        _errorText = error.message?.toString() ?? 'Could not save exercise.';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _TrainingPlanDialog extends StatefulWidget {
  const _TrainingPlanDialog({required this.store, this.initialPlan});

  final AppStore store;
  final TrainingPlan? initialPlan;

  @override
  State<_TrainingPlanDialog> createState() => _TrainingPlanDialogState();
}

class _TrainingPlanDialogState extends State<_TrainingPlanDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final List<TrainingExercise> _exercises = <TrainingExercise>[];
  String? _errorText;

  bool get _isEditing => widget.initialPlan != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _descriptionController = TextEditingController(
      text: plan?.description ?? '',
    );
    if (plan != null) {
      _exercises.addAll(plan.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit training' : 'Training plan'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Training name'),
              ),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.newline,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Training description',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openExercisePicker,
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              ),
              const SizedBox(height: 12),
              if (_exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No exercises added yet'),
                )
              else
                ..._exercises.indexed.map((entry) {
                  final index = entry.$1;
                  final exercise = entry.$2;
                  final catalogExercise = widget.store.exerciseById(
                    exercise.exerciseId,
                  );
                  final exerciseName =
                      catalogExercise?.name ?? exercise.exerciseId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(exerciseName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_formatTarget(exercise.sets, 'sets')),
                            Text(_formatTarget(exercise.reps, 'reps')),
                            Text(_formatTarget(exercise.weight, 'weight')),
                            Text(_formatTarget(exercise.time, 'time')),
                            Text('Unit: ${exercise.unit}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit $exerciseName',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editExercise(index),
                            ),
                            IconButton(
                              tooltip: 'Remove $exerciseName',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _exercises.removeAt(index);
                                  _errorText = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _savePlan, child: const Text('Save training')),
      ],
    );
  }

  Future<void> _openExercisePicker() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.store.exercises.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final exercise = widget.store.exercises[index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.description),
                onTap: () => Navigator.of(context).pop(exercise),
              );
            },
          ),
        );
      },
    );
    if (!mounted || exercise == null) {
      return;
    }
    final entry = await showDialog<TrainingExercise>(
      context: context,
      builder: (dialogContext) {
        return _TrainingExerciseDialog(
          exercise: exercise,
          initialExercise: null,
        );
      },
    );
    if (!mounted || entry == null) {
      return;
    }
    setState(() {
      _exercises.add(entry);
      _errorText = null;
    });
  }

  Future<void> _editExercise(int index) async {
    final current = _exercises[index];
    final exercise = widget.store.exerciseById(current.exerciseId);
    if (exercise == null) {
      return;
    }
    final updated = await showDialog<TrainingExercise>(
      context: context,
      builder: (dialogContext) {
        return _TrainingExerciseDialog(
          exercise: exercise,
          initialExercise: current,
        );
      },
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _exercises[index] = updated;
      _errorText = null;
    });
  }

  void _savePlan() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty || _exercises.isEmpty) {
      setState(() {
        _errorText = 'Enter a training name and add at least one exercise.';
      });
      return;
    }

    final plan = TrainingPlan(
      id: widget.initialPlan?.id ?? widget.store.createIdFromName(name),
      name: name,
      description: description,
      exercises: List<TrainingExercise>.unmodifiable(_exercises),
    );

    try {
      if (_isEditing) {
        widget.store.updateTrainingPlan(plan);
      } else {
        widget.store.createTrainingPlan(plan);
      }
    } on ArgumentError catch (error) {
      setState(() {
        _errorText = error.message?.toString() ?? 'Could not save training.';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _formatTarget(double? value, String label) {
    if (value == null) {
      return '$label: -';
    }
    return '${_formatNumber(value)} $label';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _TrainingExerciseDialog extends StatefulWidget {
  const _TrainingExerciseDialog({
    required this.exercise,
    required this.initialExercise,
  });

  final Exercise exercise;
  final TrainingExercise? initialExercise;

  @override
  State<_TrainingExerciseDialog> createState() =>
      _TrainingExerciseDialogState();
}

class _TrainingExerciseDialogState extends State<_TrainingExerciseDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _timeController;
  late final TextEditingController _unitController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExercise;
    _setsController = TextEditingController(
      text: initial?.sets == null ? '' : _formatInput(initial!.sets!),
    );
    _repsController = TextEditingController(
      text: initial?.reps == null ? '' : _formatInput(initial!.reps!),
    );
    _weightController = TextEditingController(
      text: initial?.weight == null ? '' : _formatInput(initial!.weight!),
    );
    _timeController = TextEditingController(
      text: initial?.time == null ? '' : _formatInput(initial!.time!),
    );
    _unitController = TextEditingController(text: initial?.unit ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _timeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialExercise == null ? 'Add exercise' : 'Edit exercise',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.exercise.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Expected sets'),
            ),
            TextField(
              controller: _repsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Expected reps'),
            ),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Expected weight'),
            ),
            TextField(
              controller: _timeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Expected time'),
            ),
            TextField(
              controller: _unitController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveExercise,
          child: const Text('Save exercise'),
        ),
      ],
    );
  }

  void _saveExercise() {
    final sets = _parseOptional(_setsController.text);
    final reps = _parseOptional(_repsController.text);
    final weight = _parseOptional(_weightController.text);
    final time = _parseOptional(_timeController.text);
    final unit = _unitController.text.trim();
    if ((sets == null && _setsController.text.trim().isNotEmpty) ||
        (reps == null && _repsController.text.trim().isNotEmpty) ||
        (weight == null && _weightController.text.trim().isNotEmpty) ||
        (time == null && _timeController.text.trim().isNotEmpty) ||
        unit.isEmpty) {
      setState(() {
        _errorText = 'Enter valid exercise targets and a unit.';
      });
      return;
    }

    Navigator.of(context).pop(
      TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        weight: weight,
        time: time,
        unit: unit,
      ),
    );
  }

  double? _parseOptional(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return null;
    }
    return parsed;
  }

  String _formatInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
