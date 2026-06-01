import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_preferences.dart';
import '../models/exercise.dart';
import '../models/training_plan.dart';
import '../state/app_store.dart';
import '../ui/core/forms/form_error_messages.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/layout/app_breakpoints.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/core/widgets/form_shell.dart';
import '../ui/core/widgets/swipe_action_card.dart';
import '../ui/library/library_cards.dart';
import '../ui/library/library_formatters.dart';

enum TrainingsCatalogView { plans, exercises }

Future<void> openTrainingPlanForm(
  BuildContext context,
  AppStore store, {
  TrainingPlan? initialPlan,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) {
        return _TrainingPlanDialog(
          store: store,
          initialPlan: initialPlan,
          fullScreen: true,
        );
      },
    ),
  );
}

Future<void> openExerciseForm(
  BuildContext context,
  AppStore store, {
  Exercise? initialExercise,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) {
        return _ExerciseDialog(
          store: store,
          initialExercise: initialExercise,
          fullScreen: true,
        );
      },
    ),
  );
}

class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({
    super.key,
    required this.store,
    this.embedded = false,
    this.initialView = TrainingsCatalogView.plans,
    this.showEmbeddedAction = true,
    this.showViewSwitcher = true,
  });

  final AppStore store;
  final bool embedded;
  final TrainingsCatalogView initialView;
  final bool showEmbeddedAction;
  final bool showViewSwitcher;

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  late TrainingsCatalogView _selectedView;

  AppStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _selectedView = widget.initialView;
  }

  @override
  void didUpdateWidget(covariant TrainingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialView != widget.initialView) {
      _selectedView = widget.initialView;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final body = _buildBody(context);
        final l10n = AppLocalizations.of(context);
        final addLabel = _selectedView == TrainingsCatalogView.plans
            ? l10n?.trainingAddPlanAction ?? 'Add training plan'
            : l10n?.trainingAddExerciseAction ?? 'Add exercise';
        if (widget.embedded) {
          return body;
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n?.trainingsTitle ?? 'Trainings')),
          floatingActionButton: FloatingActionButton(
            heroTag: 'trainings-action-fab',
            tooltip: addLabel,
            onPressed: _selectedView == TrainingsCatalogView.plans
                ? () => _openPlanDialog(context)
                : () => _openExerciseDialog(context),
            child: const Icon(Icons.add),
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptivePage(
      children: [
        if (widget.showViewSwitcher) ...[
          SegmentedButton<TrainingsCatalogView>(
            segments: [
              ButtonSegment(
                value: TrainingsCatalogView.plans,
                label: Text(l10n?.trainingPlansSegment ?? 'Plans'),
                icon: const Icon(Icons.assignment_outlined),
              ),
              ButtonSegment(
                value: TrainingsCatalogView.exercises,
                label: Text(l10n?.trainingExercisesSegment ?? 'Exercises'),
                icon: const Icon(Icons.fitness_center_outlined),
              ),
            ],
            selected: <TrainingsCatalogView>{_selectedView},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedView = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_selectedView == TrainingsCatalogView.plans)
          ..._buildPlansView(context)
        else
          ..._buildExercisesView(context),
      ],
    );
  }

  List<Widget> _buildPlansView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildSectionHeader(
        context,
        title: l10n?.trainingPlansTitle ?? 'Training plans',
        actionLabel: l10n?.trainingAddPlanAction ?? 'Add training plan',
        onPressed: () => _openPlanDialog(context),
      ),
      const SizedBox(height: 12),
      if (store.trainingPlans.isEmpty)
        AppEmptyState(
          icon: Icons.assignment_outlined,
          title: l10n?.trainingNoPlansTitle ?? 'No training plans yet',
          message:
              l10n?.trainingNoPlansMessage ??
              'Create a training plan to organize exercises.',
        )
      else
        ...store.trainingPlans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TrainingPlanCatalogCard(
              plan: plan,
              store: store,
              onEdit: () => _openPlanDialog(context, initialPlan: plan),
              onDelete: () => _confirmDeletePlan(context, plan),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildExercisesView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _buildSectionHeader(
        context,
        title: l10n?.trainingExercisesSegment ?? 'Exercises',
        actionLabel: l10n?.trainingAddExerciseAction ?? 'Add exercise',
        onPressed: () => _openExerciseDialog(context),
      ),
      const SizedBox(height: 12),
      if (store.exercises.isEmpty)
        AppEmptyState(
          icon: Icons.fitness_center_outlined,
          title: l10n?.trainingNoExercisesTitle ?? 'No exercises yet',
          message:
              l10n?.trainingNoExercisesMessage ??
              'Create an exercise to use it in training plans.',
        )
      else
        ...store.exercises.map(
          (exercise) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExerciseCatalogCard(
              exercise: exercise,
              onEdit: () =>
                  _openExerciseDialog(context, initialExercise: exercise),
              onDelete: () => _confirmDeleteExercise(context, exercise),
            ),
          ),
        ),
    ];
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    final titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
    if (!widget.embedded) {
      return titleWidget;
    }
    if (!widget.showEmbeddedAction) {
      return titleWidget;
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        titleWidget,
        Tooltip(
          message: actionLabel,
          child: IntrinsicWidth(
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
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
    await openTrainingPlanForm(context, store, initialPlan: initialPlan);
  }

  Future<void> _openExerciseDialog(
    BuildContext context, {
    Exercise? initialExercise,
  }) async {
    await openExerciseForm(context, store, initialExercise: initialExercise);
  }

  Future<void> _confirmDeletePlan(
    BuildContext context,
    TrainingPlan plan,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n?.trainingDeletePlanTitle(plan.name) ?? 'Delete ${plan.name}?',
          ),
          content: Text(
            l10n?.trainingDeletePlanMessage ??
                'This removes the training plan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n?.commonCancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n?.commonDelete ?? 'Delete'),
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
      _showSnackBar(
        context,
        humanReadableFormError(
          error,
          resourceName: 'training',
          fallback: l10n?.trainingCouldNotDelete ?? 'Could not delete.',
        ),
      );
    } on StateError catch (error) {
      _showSnackBar(
        context,
        humanReadableFormError(
          error,
          resourceName: 'training',
          fallback: l10n?.trainingCouldNotDelete ?? 'Could not delete.',
        ),
      );
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
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n?.trainingDeleteExerciseTitle(exercise.name) ??
                'Delete ${exercise.name}?',
          ),
          content: Text(
            l10n?.trainingDeleteExerciseMessage ?? 'This removes the exercise.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n?.commonCancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n?.commonDelete ?? 'Delete'),
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
      _showSnackBar(
        context,
        humanReadableFormError(
          error,
          resourceName: 'exercise',
          fallback: l10n?.trainingCouldNotDelete ?? 'Could not delete.',
        ),
      );
    } on StateError catch (error) {
      _showSnackBar(
        context,
        humanReadableFormError(
          error,
          resourceName: 'exercise',
          fallback: l10n?.trainingCouldNotDelete ?? 'Could not delete.',
        ),
      );
    }
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({
    required this.store,
    this.initialExercise,
    this.fullScreen = false,
  });

  final AppStore store;
  final Exercise? initialExercise;
  final bool fullScreen;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionController;
  final Set<MuscleGroup> _selectedMuscleGroups = <MuscleGroup>{};
  ExerciseMeasurementType? _selectedMeasurementType;
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
    _selectedMeasurementType = exercise?.measurementType;
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
    final l10n = AppLocalizations.of(context);
    final measurementTypeLocked = _measurementTypeEditingLocked;
    final title = _isEditing
        ? l10n?.exerciseDialogEditTitle ?? 'Edit exercise'
        : l10n?.exerciseDialogAddTitle ?? 'Add exercise';
    final subtitle =
        l10n?.exerciseDialogSubtitle ??
        'Define instructions and muscle focus for workout plans.';
    final children = [
      FormSectionCard(
        title: l10n?.exerciseProfileSectionTitle ?? 'Exercise profile',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n?.exerciseNameFieldLabel ?? 'Exercise name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText:
                    l10n?.exerciseDescriptionFieldLabel ??
                    'Exercise description',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionController,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText:
                    l10n?.exerciseInstructionFieldLabel ??
                    'Exercise instruction',
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Measurement type',
              child: DropdownButtonFormField<ExerciseMeasurementType>(
                key: const ValueKey('exercise-measurement-type-field'),
                initialValue: _selectedMeasurementType,
                decoration: const InputDecoration(
                  labelText: 'Measurement type',
                ),
                items: ExerciseMeasurementType.values
                    .map(
                      (measurementType) =>
                          DropdownMenuItem<ExerciseMeasurementType>(
                            value: measurementType,
                            child: Text(
                              formatExerciseMeasurementTypeLabel(
                                measurementType,
                              ),
                            ),
                          ),
                    )
                    .toList(growable: false),
                onChanged: measurementTypeLocked
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMeasurementType = value;
                          _errorText = null;
                        });
                      },
              ),
            ),
            if (measurementTypeLocked) ...[
              const SizedBox(height: 8),
              Text(
                'Measurement type can no longer change because workout history exists.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      FormSectionCard(
        title: l10n?.exerciseMuscleFocusTitle ?? 'Muscle focus',
        subtitle:
            l10n?.exerciseMuscleFocusSubtitle ??
            'Choose every area this exercise primarily trains.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.exerciseSelectMuscleGroups ?? 'Select muscle groups',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
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
                      labelStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                      checkmarkColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      selected: isSelected,
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
          ],
        ),
      ),
      if (_errorText != null) InlineErrorBanner(message: _errorText!),
    ];
    if (widget.fullScreen) {
      return FormShellPage(
        title: title,
        subtitle: subtitle,
        primaryActionLabel: l10n?.exerciseSaveAction ?? 'Save exercise',
        onPrimaryAction: _saveExercise,
        children: children,
      );
    }
    return FormShellDialog(
      title: title,
      subtitle: subtitle,
      primaryActionLabel: l10n?.exerciseSaveAction ?? 'Save exercise',
      onPrimaryAction: _saveExercise,
      maxWidth: 640,
      children: children,
    );
  }

  void _saveExercise() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final instruction = _instructionController.text.trim();
    final muscleGroups = _selectedMuscleGroups.toList(growable: false);
    final measurementType = _selectedMeasurementType;
    if (name.isEmpty ||
        description.isEmpty ||
        instruction.isEmpty ||
        muscleGroups.isEmpty ||
        measurementType == null) {
      setState(() {
        _errorText =
            'Enter a name, description, instruction, muscle groups, and measurement type.';
      });
      return;
    }
    final id =
        widget.initialExercise?.id ?? widget.store.createIdFromName(name);
    if (id.isEmpty) {
      setState(() {
        _errorText =
            AppLocalizations.of(context)?.exerciseNameValidation ??
            'Enter a valid exercise name.';
      });
      return;
    }

    final exercise = Exercise(
      id: id,
      name: name,
      description: description,
      instruction: instruction,
      muscleGroups: muscleGroups,
      measurementType: measurementType,
    );

    try {
      if (_isEditing) {
        widget.store.updateExercise(exercise);
      } else {
        widget.store.createExercise(exercise);
      }
    } on ArgumentError catch (error) {
      setState(() {
        _errorText = humanReadableFormError(
          error,
          resourceName: 'exercise',
          fallback:
              AppLocalizations.of(context)?.exerciseCouldNotSave ??
              'Could not save exercise.',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  bool get _measurementTypeEditingLocked {
    final exerciseId = widget.initialExercise?.id;
    if (exerciseId == null) {
      return false;
    }
    if (widget.store
        .completedWorkoutHistoryForExercise(exerciseId)
        .isNotEmpty) {
      return true;
    }
    final activeWorkout = widget.store.activeWorkoutSession;
    if (activeWorkout == null) {
      return false;
    }
    return activeWorkout.results.any(
      (result) => result.exerciseId == exerciseId,
    );
  }
}

class _TrainingPlanDialog extends StatefulWidget {
  const _TrainingPlanDialog({
    required this.store,
    this.initialPlan,
    this.fullScreen = false,
  });

  final AppStore store;
  final TrainingPlan? initialPlan;
  final bool fullScreen;

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
    final l10n = AppLocalizations.of(context);
    final title = _isEditing
        ? l10n?.trainingPlanEditDialogTitle ?? 'Edit training'
        : l10n?.trainingPlanDialogTitle ?? 'Training plan';
    final subtitle =
        l10n?.trainingPlanDialogSubtitle ??
        'Assemble a reusable sequence for workout sessions.';
    final children = [
      FormSectionCard(
        title: l10n?.trainingBasicsSectionTitle ?? 'Training basics',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n?.trainingNameFieldLabel ?? 'Training name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.newline,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText:
                    l10n?.trainingDescriptionFieldLabel ??
                    'Training description',
              ),
            ),
          ],
        ),
      ),
      FormSectionCard(
        title: l10n?.trainingExerciseSequenceTitle ?? 'Exercise sequence',
        subtitle:
            l10n?.trainingExerciseSequenceSubtitle ??
            'Add targets in the order you want to train.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _openExercisePicker,
              icon: const Icon(Icons.add),
              label: Text(l10n?.trainingAddExerciseAction ?? 'Add exercise'),
            ),
            const SizedBox(height: 12),
            if (_exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n?.trainingNoExercisesAdded ?? 'No exercises added yet',
                ),
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
                final detailLines = catalogExercise == null
                    ? const <String>[]
                    : formatTrainingExerciseDetailLines(
                        exercise,
                        catalogExercise.measurementType,
                        widget.store,
                      );
                final isCompact = AppBreakpoints.isCompact(
                  MediaQuery.sizeOf(context).width,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SwipeActionCard(
                    actions: [
                      SwipeCardAction(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        onPressed: () => _editExercise(index),
                      ),
                      SwipeCardAction(
                        label: 'Remove',
                        icon: Icons.remove_circle_outline,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                        onPressed: () {
                          setState(() {
                            _exercises.removeAt(index);
                            _errorText = null;
                          });
                        },
                      ),
                    ],
                    child: Card(
                      child: ListTile(
                        title: Text(exerciseName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: detailLines
                              .map((detail) => Text(detail))
                              .toList(growable: false),
                        ),
                        isThreeLine: true,
                        trailing: isCompact
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip:
                                        l10n?.libraryEditItem(exerciseName) ??
                                        'Edit $exerciseName',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editExercise(index),
                                  ),
                                  IconButton(
                                    tooltip:
                                        l10n?.trainingRemoveExerciseTooltip(
                                          exerciseName,
                                        ) ??
                                        'Remove $exerciseName',
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
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
                  ),
                );
              }),
          ],
        ),
      ),
      if (_errorText != null) InlineErrorBanner(message: _errorText!),
    ];
    if (widget.fullScreen) {
      return FormShellPage(
        title: title,
        subtitle: subtitle,
        primaryActionLabel: l10n?.trainingSaveAction ?? 'Save training',
        onPrimaryAction: _savePlan,
        children: children,
      );
    }
    return FormShellDialog(
      title: title,
      subtitle: subtitle,
      primaryActionLabel: l10n?.trainingSaveAction ?? 'Save training',
      onPrimaryAction: _savePlan,
      maxWidth: 720,
      children: children,
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
    final entry = await Navigator.of(context).push<TrainingExercise>(
      MaterialPageRoute<TrainingExercise>(
        fullscreenDialog: true,
        builder: (context) {
          return _TrainingExerciseDialog(
            store: widget.store,
            exercise: exercise,
            initialExercise: null,
            fullScreen: true,
          );
        },
      ),
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
    final updated = await Navigator.of(context).push<TrainingExercise>(
      MaterialPageRoute<TrainingExercise>(
        fullscreenDialog: true,
        builder: (context) {
          return _TrainingExerciseDialog(
            store: widget.store,
            exercise: exercise,
            initialExercise: current,
            fullScreen: true,
          );
        },
      ),
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
        _errorText =
            AppLocalizations.of(context)?.trainingPlanValidation ??
            'Enter a training name and add at least one exercise.';
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
        _errorText = humanReadableFormError(
          error,
          resourceName: 'training',
          fallback:
              AppLocalizations.of(context)?.trainingCouldNotSave ??
              'Could not save training.',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _TrainingExerciseDialog extends StatefulWidget {
  const _TrainingExerciseDialog({
    required this.store,
    required this.exercise,
    required this.initialExercise,
    this.fullScreen = false,
  });

  final AppStore store;
  final Exercise exercise;
  final TrainingExercise? initialExercise;
  final bool fullScreen;

  @override
  State<_TrainingExerciseDialog> createState() =>
      _TrainingExerciseDialogState();
}

class _TrainingExerciseDialogState extends State<_TrainingExerciseDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late final TextEditingController _assistanceController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExercise;
    _setsController = TextEditingController(text: _formatInput(initial?.sets));
    _repsController = TextEditingController(text: _formatInput(initial?.reps));
    _weightController = TextEditingController(
      text: _formatInput(_displayWeight(initial?.weightGrams)),
    );
    _durationController = TextEditingController(
      text: _formatInput(initial?.durationSeconds),
    );
    _distanceController = TextEditingController(
      text: _formatInput(_displayDistance(initial?.distanceMeters)),
    );
    _assistanceController = TextEditingController(
      text: _formatInput(_displayWeight(initial?.assistanceWeightGrams)),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _assistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.initialExercise == null
        ? l10n?.trainingTargetDialogTitle ?? 'Add exercise'
        : l10n?.trainingTargetDialogEditTitle ?? 'Edit exercise';
    final children = [
      FormSectionCard(
        title: l10n?.trainingTargetSectionTitle ?? 'Set targets',
        subtitle: _targetSectionSubtitle(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFields(context),
        ),
      ),
      if (_errorText != null) InlineErrorBanner(message: _errorText!),
    ];
    if (widget.fullScreen) {
      return FormShellPage(
        title: title,
        subtitle: widget.exercise.name,
        primaryActionLabel: l10n?.exerciseSaveAction ?? 'Save exercise',
        onPrimaryAction: _saveExercise,
        children: children,
      );
    }
    return FormShellDialog(
      title: title,
      subtitle: widget.exercise.name,
      primaryActionLabel: l10n?.exerciseSaveAction ?? 'Save exercise',
      onPrimaryAction: _saveExercise,
      children: children,
    );
  }

  void _saveExercise() {
    final sets = _parsePositiveIntegerOptional(_setsController.text);
    final reps = _parsePositiveIntegerOptional(_repsController.text);
    final weightInput = _parsePositiveOptional(_weightController.text);
    final duration = _parsePositiveOptional(_durationController.text);
    final distanceInput = _parsePositiveOptional(_distanceController.text);
    final assistanceInput = _parsePositiveOptional(_assistanceController.text);
    if ((sets == null && _setsController.text.trim().isNotEmpty) ||
        (reps == null && _repsController.text.trim().isNotEmpty) ||
        (weightInput == null && _weightController.text.trim().isNotEmpty) ||
        (duration == null && _durationController.text.trim().isNotEmpty) ||
        (distanceInput == null && _distanceController.text.trim().isNotEmpty) ||
        (assistanceInput == null &&
            _assistanceController.text.trim().isNotEmpty)) {
      setState(() {
        _errorText = _validationMessage;
      });
      return;
    }

    final exercise = switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        weightGrams: weightInput == null ? null : _normalizeWeight(weightInput),
      ),
      ExerciseMeasurementType.bodyweight => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
      ),
      ExerciseMeasurementType.duration => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        durationSeconds: duration,
      ),
      ExerciseMeasurementType.weightedDuration => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        weightGrams: weightInput == null ? null : _normalizeWeight(weightInput),
        durationSeconds: duration,
      ),
      ExerciseMeasurementType.cardio => TrainingExercise(
        exerciseId: widget.exercise.id,
        durationSeconds: duration,
        distanceMeters: distanceInput == null
            ? null
            : _normalizeDistance(distanceInput),
      ),
      ExerciseMeasurementType.assisted => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        assistanceWeightGrams: assistanceInput == null
            ? null
            : _normalizeWeight(assistanceInput),
      ),
    };

    Navigator.of(context).pop(exercise);
  }

  List<Widget> _buildFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = <Widget>[];
    switch (widget.exercise.measurementType) {
      case ExerciseMeasurementType.strength:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _weightController,
            label: l10n?.trainingExpectedWeightFieldLabel ?? 'Weight',
          ),
        ]);
        break;
      case ExerciseMeasurementType.bodyweight:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
        ]);
        break;
      case ExerciseMeasurementType.duration:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
        ]);
        break;
      case ExerciseMeasurementType.weightedDuration:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _weightController,
            label: l10n?.trainingExpectedWeightFieldLabel ?? 'Weight',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
        ]);
        break;
      case ExerciseMeasurementType.cardio:
        fields.addAll([
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
          const SizedBox(height: 12),
          _numberField(controller: _distanceController, label: 'Distance'),
        ]);
        break;
      case ExerciseMeasurementType.assisted:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _assistanceController,
            label: 'Assistance weight',
          ),
        ]);
        break;
    }
    return fields;
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
    );
  }

  String _targetSectionSubtitle() {
    return switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength => 'Set working sets, reps, and load.',
      ExerciseMeasurementType.bodyweight => 'Set working sets and reps.',
      ExerciseMeasurementType.duration => 'Set working sets and duration.',
      ExerciseMeasurementType.weightedDuration =>
        'Set working sets, load, and duration.',
      ExerciseMeasurementType.cardio =>
        'Set duration, distance, or both for the cardio target.',
      ExerciseMeasurementType.assisted =>
        'Set working sets, reps, and assistance weight.',
    };
  }

  String get _validationMessage {
    return switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength =>
        'Use positive values for any filled sets, reps, or weight fields.',
      ExerciseMeasurementType.bodyweight =>
        'Use positive values for any filled sets or reps fields.',
      ExerciseMeasurementType.duration =>
        'Use positive values for any filled sets or duration fields.',
      ExerciseMeasurementType.weightedDuration =>
        'Use positive values for any filled sets, weight, or duration fields.',
      ExerciseMeasurementType.cardio =>
        'Use positive values for any filled duration or distance fields.',
      ExerciseMeasurementType.assisted =>
        'Use positive values for any filled sets, reps, or assistance fields.',
    };
  }

  double? _parsePositiveOptional(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parsePositiveIntegerOptional(String value) {
    final parsed = _parsePositiveOptional(value);
    if (parsed == null || parsed != parsed.roundToDouble()) {
      return null;
    }
    return parsed;
  }

  double? _displayWeight(double? grams) {
    if (grams == null) {
      return null;
    }
    final kilograms = grams / 1000;
    return widget.store.workoutWeightUnit == WorkoutWeightUnit.pounds
        ? kilograms * 2.2046226218
        : kilograms;
  }

  double? _displayDistance(double? meters) {
    if (meters == null) {
      return null;
    }
    final kilometers = meters / 1000;
    return widget.store.distanceUnit == DistanceUnit.miles
        ? kilometers / 1.609344
        : kilometers;
  }

  double _normalizeWeight(double value) {
    final kilograms = widget.store.workoutWeightUnit == WorkoutWeightUnit.pounds
        ? value / 2.2046226218
        : value;
    return kilograms * 1000;
  }

  double _normalizeDistance(double value) {
    final kilometers = widget.store.distanceUnit == DistanceUnit.miles
        ? value * 1.609344
        : value;
    return kilometers * 1000;
  }

  String _formatInput(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
