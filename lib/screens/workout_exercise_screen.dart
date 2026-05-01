import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  final TextEditingController _timeController = TextEditingController();

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _timeController.dispose();
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
        final history = widget.store.completedWorkoutHistoryForExercise(
          result.exerciseId,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.workoutExerciseTitle ?? 'Workout exercise'),
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
                timeController: _timeController,
                target: result.target,
                onLogSet: () => _logSet(context),
              ),
              const SizedBox(height: 16),
              WorkoutLoggedSetsCard(
                target: result.target,
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

  void _logSet(BuildContext context) {
    final reps = _parseNumber(_repsController.text);
    final weight = _parseNumber(_weightController.text);
    final time = _parseNumber(_timeController.text);
    try {
      widget.store.addActiveWorkoutSet(
        resultIndex: widget.resultIndex,
        setLog: WorkoutSetLog(reps: reps, weight: weight, time: time),
      );
      _repsController.clear();
      _weightController.clear();
      _timeController.clear();
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _fillSetLog(WorkoutSetLog setLog) {
    _repsController.text = formatWorkoutInputNumber(setLog.reps);
    _weightController.text = formatWorkoutInputNumber(setLog.weight);
    _timeController.text = formatWorkoutInputNumber(setLog.time);
  }

  double? _parseNumber(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized) ?? double.nan;
  }
}
