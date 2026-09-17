import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/forms/form_error_messages.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_formatters.dart';
import '../ui/workout/workout_session_cards.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/training_exercise_dialog.dart';
import 'workout_exercise_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.store,
    this.isCurrentTab = true,
    this.isCurrentTabListenable,
  });

  final AppStore store;
  final bool isCurrentTab;
  final ValueListenable<bool>? isCurrentTabListenable;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _timer;
  bool _isTakingOver = false;
  bool _isReplacingExercise = false;
  bool get _isCurrentTab =>
      widget.isCurrentTabListenable?.value ?? widget.isCurrentTab;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    widget.isCurrentTabListenable?.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant WorkoutSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_syncTimer);
      widget.store.addListener(_syncTimer);
    }
    if (oldWidget.isCurrentTabListenable != widget.isCurrentTabListenable) {
      oldWidget.isCurrentTabListenable?.removeListener(_syncTimer);
      widget.isCurrentTabListenable?.addListener(_syncTimer);
    }
    if (oldWidget.isCurrentTab != widget.isCurrentTab ||
        oldWidget.store != widget.store ||
        oldWidget.isCurrentTabListenable != widget.isCurrentTabListenable) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncTimer);
    widget.isCurrentTabListenable?.removeListener(_syncTimer);
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final hasActiveSession =
        _isCurrentTab && widget.store.activeWorkoutSession != null;
    if (!hasActiveSession) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final session = widget.store.activeWorkoutSession;
        final l10n = AppLocalizations.of(context);
        if (session == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n?.workoutSessionTitle ?? 'Workout session'),
            ),
            body: const AdaptivePage(children: []),
          );
        }
        final exerciseCounts = _exerciseCounts(session.results);
        final seenExercises = <String, int>{};
        final isReadOnly = widget.store.isActiveWorkoutReadOnly;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.workoutSessionTitle ?? 'Workout session'),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: isReadOnly ? null : () => _finishWorkout(context),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n?.workoutFinishAction ?? 'Finish workout'),
            ),
          ),
          body: AdaptivePage(
            children: [
              if (isReadOnly) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout active on another device',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This workout is read-only until you explicitly '
                          'continue it on this device.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _isTakingOver
                              ? null
                              : () => _takeOverWorkout(context),
                          child: Text(
                            _isTakingOver ? 'Taking over…' : 'Continue here',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const AppPageSectionGap(),
              ],
              WorkoutSessionHeaderCard(
                session: session,
                store: widget.store,
                l10n: l10n,
              ),
              const AppPageSectionGap(),
              SectionHeader(
                title: l10n?.workoutExerciseQueueTitle ?? 'Exercise queue',
                subtitle:
                    l10n?.workoutExerciseQueueSubtitle ??
                    'Open an exercise to log sets and compare history.',
              ),
              ...session.results.indexed.map((entry) {
                final resultIndex = entry.$1;
                final result = entry.$2;
                final occurrence = (seenExercises[result.exerciseId] ?? 0) + 1;
                seenExercises[result.exerciseId] = occurrence;
                final hasRepeatedExercise =
                    (exerciseCounts[result.exerciseId] ?? 0) > 1;
                final measurementType =
                    result.measurementType ??
                    widget.store
                        .exerciseById(result.exerciseId)
                        ?.measurementType ??
                    ExerciseMeasurementType.strength;
                final exerciseLabel = hasRepeatedExercise
                    ? '${result.exerciseName} ($occurrence)'
                    : result.exerciseName;
                final tooltipLabel = hasRepeatedExercise
                    ? l10n?.workoutOpenExerciseEntryTooltip(
                            result.exerciseName,
                            occurrence,
                          ) ??
                          'Open ${result.exerciseName} entry $occurrence'
                    : l10n?.workoutOpenExerciseTooltip(result.exerciseName) ??
                          'Open ${result.exerciseName}';
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppPageSpacing.itemGap,
                  ),
                  child: WorkoutExerciseProgressCard(
                    key: ObjectKey(result),
                    exerciseLabel: exerciseLabel,
                    targetLabel: formatWorkoutTarget(
                      result.target,
                      measurementType,
                      widget.store,
                      targetPrefix: l10n?.workoutTargetPrefix ?? 'Target:',
                      setsLabel: l10n?.workoutSetsLabel ?? 'sets',
                      repsLabel: l10n?.workoutRepsLabel ?? 'reps',
                    ),
                    setCountLabel: formatWorkoutSetCount(
                      result.setLogs.length,
                      setCountLoggedLabel: l10n?.workoutSetCountLogged,
                    ),
                    tooltip: tooltipLabel,
                    onOpen: () => _openExercise(context, resultIndex),
                    onReplace:
                        isReadOnly ||
                            result.setLogs.isNotEmpty ||
                            _isReplacingExercise
                        ? null
                        : () => _replaceExercise(session, resultIndex),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _replaceExercise(WorkoutSession session, int resultIndex) async {
    final original = session.results[resultIndex];
    final l10n = AppLocalizations.of(context);
    setState(() => _isReplacingExercise = true);
    try {
      final replacement = await showModalBottomSheet<Exercise>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ExercisePickerSheet(
          exercises: widget.store.exercises
              .where((exercise) => exercise.id != original.exerciseId)
              .toList(growable: false),
          initialMuscleGroups:
              widget.store.exerciseById(original.exerciseId)?.muscleGroups ??
              const [],
        ),
      );
      if (!mounted || replacement == null) return;
      final target = await Navigator.of(context).push<TrainingExercise>(
        MaterialPageRoute<TrainingExercise>(
          fullscreenDialog: true,
          builder: (_) => TrainingExerciseDialog(
            store: widget.store,
            exercise: replacement,
            initialExercise: original.target.forReplacement(replacement),
            fullScreen: true,
            title: l10n?.workoutReplaceExerciseAction ?? 'Replace exercise',
            primaryActionLabel: l10n?.workoutReplaceAction ?? 'Replace',
          ),
        ),
      );
      if (!mounted || target == null) return;
      final isDuplicate =
          widget.store.activeWorkoutSession?.results.indexed.any(
            (entry) =>
                entry.$1 != resultIndex &&
                entry.$2.exerciseId == replacement.id,
          ) ??
          false;
      if (isDuplicate) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              l10n?.workoutDuplicateExerciseTitle ??
                  'Exercise already in workout',
            ),
            content: Text(
              l10n?.workoutDuplicateExerciseMessage(replacement.name) ??
                  '${replacement.name} is already in this workout. Replace anyway? Each entry will keep its own targets and sets.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n?.commonCancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n?.workoutReplaceAction ?? 'Replace'),
              ),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      widget.store.replaceActiveWorkoutExercise(
        sessionId: session.id,
        resultIndex: resultIndex,
        expectedResult: original,
        replacement: replacement,
        target: target,
        allowDuplicate: isDuplicate,
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              humanReadableFormError(
                error,
                resourceName: 'exercise',
                fallback:
                    l10n?.workoutReplaceExerciseError ??
                    'Could not replace exercise.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReplacingExercise = false);
    }
  }

  Future<void> _openExercise(BuildContext context, int resultIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkoutExerciseScreen(
          store: widget.store,
          resultIndex: resultIndex,
        ),
      ),
    );
  }

  Future<void> _finishWorkout(BuildContext context) async {
    try {
      widget.store.finishActiveWorkout();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanReadableFormError(
              error,
              resourceName: 'workout',
              fallback: 'Could not finish workout.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _takeOverWorkout(BuildContext context) async {
    setState(() => _isTakingOver = true);
    try {
      final didTakeOver = await widget.store.takeOverActiveWorkout();
      if (!didTakeOver && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take over the workout.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTakingOver = false);
      }
    }
  }

  Map<String, int> _exerciseCounts(List<WorkoutExerciseResult> results) {
    final counts = <String, int>{};
    for (final result in results) {
      counts[result.exerciseId] = (counts[result.exerciseId] ?? 0) + 1;
    }
    return counts;
  }
}
