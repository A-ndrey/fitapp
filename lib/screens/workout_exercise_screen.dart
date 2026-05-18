import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_detail_cards.dart';
import '../ui/workout/workout_formatters.dart';

class WorkoutExerciseScreen extends StatefulWidget {
  const WorkoutExerciseScreen({
    super.key,
    required this.store,
    required this.resultIndex,
  });

  final AppStore store;
  final int resultIndex;

  @override
  State<WorkoutExerciseScreen> createState() => _WorkoutExerciseScreenState();
}

class _WorkoutExerciseScreenState extends State<WorkoutExerciseScreen> {
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _assistanceWeightController =
      TextEditingController();
  DateTime? _restUntil;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _assistanceWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final session = widget.store.activeWorkoutSession;
        if (session == null ||
            widget.resultIndex < 0 ||
            widget.resultIndex >= session.results.length) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n?.workoutExerciseTitle ?? 'Workout exercise'),
            ),
            body: const AdaptivePage(children: []),
          );
        }
        final result = session.results[widget.resultIndex];
        final measurementType = _measurementTypeForResult(result);
        final exerciseOccurrenceIndex = _exerciseOccurrenceIndex(
          session.results,
          widget.resultIndex,
          result.exerciseId,
        );
        final history = widget.store.completedWorkoutHistoryForExercise(
          result.exerciseId,
        );
        final lastLoggedSet = result.setLogs.isEmpty
            ? null
            : result.setLogs.last;
        final previousCompletedSet = _previousCompletedSetForOccurrence(
          history,
          exerciseOccurrenceIndex,
        );
        final progressionHint = _progressionHint(
          result,
          measurementType,
          lastLoggedSet ?? previousCompletedSet,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.workoutExerciseTitle ?? 'Workout exercise'),
          ),
          floatingActionButton: _restUntil == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: null,
                  label: Text('Rest ${_restCountdownLabel()}'),
                  icon: const Icon(Icons.timer_outlined),
                ),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: l10n?.workoutExerciseTitle ?? 'Workout exercise',
                subtitle:
                    l10n?.workoutExerciseSubtitle ??
                    'Log sets and reuse recent performance.',
              ),
              WorkoutActiveExerciseSummaryCard(
                result: result,
                store: widget.store,
              ),
              const SizedBox(height: 16),
              WorkoutSetInputCard(
                repsController: _repsController,
                weightController: _weightController,
                durationController: _durationController,
                distanceController: _distanceController,
                assistanceWeightController: _assistanceWeightController,
                measurementType: measurementType,
                store: widget.store,
                previousSetLabel: _previousSetLabel(
                  result,
                  measurementType,
                  lastLoggedSet ?? previousCompletedSet,
                ),
                progressionHint: progressionHint,
                quickFillChips: _quickFillChips(
                  result,
                  measurementType,
                  lastLoggedSet,
                  previousCompletedSet,
                ),
                onLogSet: () => _logSet(context, measurementType),
              ),
              const SizedBox(height: 16),
              WorkoutLoggedSetsCard(
                measurementType: measurementType,
                setLogs: result.setLogs,
                store: widget.store,
                onFillSet: _fillSetLog,
              ),
              const SizedBox(height: 16),
              WorkoutPreviousResultsCard(
                history: history,
                store: widget.store,
                onFillSet: _fillSetLog,
              ),
            ],
          ),
        );
      },
    );
  }

  void _logSet(BuildContext context, ExerciseMeasurementType measurementType) {
    final setLog = WorkoutSetLog(
      reps: parseWorkoutInputValue(
        _repsController.text,
        WorkoutLogField.reps,
        widget.store,
      ),
      weightGrams: parseWorkoutInputValue(
        _weightController.text,
        WorkoutLogField.weight,
        widget.store,
      ),
      durationSeconds: parseWorkoutInputValue(
        _durationController.text,
        WorkoutLogField.duration,
        widget.store,
      ),
      distanceMeters: parseWorkoutInputValue(
        _distanceController.text,
        WorkoutLogField.distance,
        widget.store,
      ),
      assistanceWeightGrams: parseWorkoutInputValue(
        _assistanceWeightController.text,
        WorkoutLogField.assistanceWeight,
        widget.store,
      ),
    );
    try {
      widget.store.addActiveWorkoutSet(
        resultIndex: widget.resultIndex,
        setLog: setLog,
      );
      _fillSetLog(setLog);
      _startRestTimer();
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _fillSetLog(WorkoutSetLog setLog) {
    _repsController.text = formatWorkoutInputValue(
      WorkoutLogField.reps,
      setLog.reps,
      widget.store,
    );
    _weightController.text = formatWorkoutInputValue(
      WorkoutLogField.weight,
      setLog.weightGrams,
      widget.store,
    );
    _durationController.text = formatWorkoutInputValue(
      WorkoutLogField.duration,
      setLog.durationSeconds,
      widget.store,
    );
    _distanceController.text = formatWorkoutInputValue(
      WorkoutLogField.distance,
      setLog.distanceMeters,
      widget.store,
    );
    _assistanceWeightController.text = formatWorkoutInputValue(
      WorkoutLogField.assistanceWeight,
      setLog.assistanceWeightGrams,
      widget.store,
    );
  }

  List<Widget> _quickFillChips(
    WorkoutExerciseResult result,
    ExerciseMeasurementType measurementType,
    WorkoutSetLog? lastLoggedSet,
    WorkoutSetLog? previousCompletedSet,
  ) {
    final candidates = <WorkoutSetLog>{
      ...?lastLoggedSet == null ? null : [lastLoggedSet],
      ...?previousCompletedSet == null ? null : [previousCompletedSet],
      _targetSetLog(result.target),
    }.where(_hasAnySetValue);

    return [
      for (final setLog in candidates)
        ActionChip(
          label: Text(
            formatWorkoutSetLog(setLog, measurementType, widget.store),
          ),
          onPressed: () => _fillSetLog(setLog),
        ),
    ];
  }

  String? _previousSetLabel(
    WorkoutExerciseResult result,
    ExerciseMeasurementType measurementType,
    WorkoutSetLog? setLog,
  ) {
    if (setLog == null) {
      return null;
    }
    return 'Previous set '
        '${formatWorkoutSetLog(setLog, measurementType, widget.store)}';
  }

  String? _progressionHint(
    WorkoutExerciseResult result,
    ExerciseMeasurementType measurementType,
    WorkoutSetLog? referenceSet,
  ) {
    if (referenceSet == null) {
      return null;
    }
    switch (measurementType) {
      case ExerciseMeasurementType.strength:
        if ((referenceSet.reps ?? 0) >= (result.target.reps ?? 0)) {
          return 'Try +2.5 kg next set if technique stays clean.';
        }
        return 'Repeat the load and push until you hit the target reps.';
      case ExerciseMeasurementType.bodyweight:
      case ExerciseMeasurementType.assisted:
        return 'Repeat the set and aim to match the target reps cleanly.';
      case ExerciseMeasurementType.duration:
      case ExerciseMeasurementType.weightedDuration:
      case ExerciseMeasurementType.cardio:
        return 'Match the previous work set before increasing demand.';
    }
  }

  WorkoutSetLog _targetSetLog(TrainingExercise target) {
    return WorkoutSetLog(
      reps: target.reps,
      weightGrams: target.weightGrams,
      durationSeconds: target.durationSeconds,
      distanceMeters: target.distanceMeters,
      assistanceWeightGrams: target.assistanceWeightGrams,
    );
  }

  bool _hasAnySetValue(WorkoutSetLog setLog) {
    return setLog.reps != null ||
        setLog.weightGrams != null ||
        setLog.durationSeconds != null ||
        setLog.distanceMeters != null ||
        setLog.assistanceWeightGrams != null;
  }

  ExerciseMeasurementType _measurementTypeForResult(
    WorkoutExerciseResult result,
  ) {
    return widget.store.exerciseById(result.exerciseId)?.measurementType ??
        ExerciseMeasurementType.strength;
  }

  int _exerciseOccurrenceIndex(
    List<WorkoutExerciseResult> results,
    int resultIndex,
    String exerciseId,
  ) {
    var occurrenceIndex = 0;
    for (var index = 0; index < resultIndex; index++) {
      if (results[index].exerciseId == exerciseId) {
        occurrenceIndex++;
      }
    }
    return occurrenceIndex;
  }

  WorkoutSetLog? _previousCompletedSetForOccurrence(
    List<WorkoutExerciseHistoryGroup> history,
    int exerciseOccurrenceIndex,
  ) {
    for (final group in history) {
      if (exerciseOccurrenceIndex >= group.results.length) {
        continue;
      }
      final matchingResult = group.results[exerciseOccurrenceIndex];
      if (matchingResult.setLogs.isNotEmpty) {
        return matchingResult.setLogs.last;
      }
    }
    return null;
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restUntil = DateTime.now().add(const Duration(minutes: 2));
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restUntil == null || DateTime.now().isAfter(_restUntil!)) {
        setState(() {
          _restUntil = null;
        });
        timer.cancel();
        return;
      }
      setState(() {});
    });
    setState(() {});
  }

  String _restCountdownLabel() {
    final restUntil = _restUntil;
    if (restUntil == null) {
      return '';
    }
    final remaining = restUntil.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
