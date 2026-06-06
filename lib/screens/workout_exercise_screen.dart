import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/forms/form_error_messages.dart';
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

  @override
  void dispose() {
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
        final exercise = widget.store.exerciseById(result.exerciseId);
        final history = widget.store.completedWorkoutHistoryForExercise(
          result.exerciseId,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.workoutExerciseTitle ?? 'Workout exercise'),
          ),
          body: AdaptivePage(
            children: [
              SectionHeader(title: result.exerciseName),
              if (exercise != null)
                WorkoutExerciseMetaBlock(exercise: exercise),
              const SizedBox(height: 16),
              WorkoutSetInputCard(
                target: result.target,
                repsController: _repsController,
                weightController: _weightController,
                durationController: _durationController,
                distanceController: _distanceController,
                assistanceWeightController: _assistanceWeightController,
                measurementType: measurementType,
                store: widget.store,
                onLogSet: () => _logSet(context, measurementType),
              ),
              const SizedBox(height: 16),
              WorkoutExerciseHistoryCard(
                measurementType: measurementType,
                currentSession: session,
                currentResult: result,
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
      _clearInputs();
    } on Object catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanReadableFormError(
              error,
              resourceName: 'set',
              fallback: 'Could not add set.',
            ),
          ),
        ),
      );
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

  void _clearInputs() {
    _repsController.clear();
    _weightController.clear();
    _durationController.clear();
    _distanceController.clear();
    _assistanceWeightController.clear();
  }

  ExerciseMeasurementType _measurementTypeForResult(
    WorkoutExerciseResult result,
  ) {
    return widget.store.exerciseById(result.exerciseId)?.measurementType ??
        ExerciseMeasurementType.strength;
  }
}
