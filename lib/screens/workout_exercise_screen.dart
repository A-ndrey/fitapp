import 'dart:async';

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
  DateTime? _restUntil;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
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
        final lastLoggedSet = result.setLogs.isEmpty
            ? null
            : result.setLogs.last;
        final previousCompletedSet = history.isEmpty
            ? null
            : history.first.results
                  .where((entry) => entry.setLogs.isNotEmpty)
                  .map((entry) => entry.setLogs.last)
                  .firstOrNull;
        final progressionHint = _progressionHint(
          result,
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
                timeController: _timeController,
                target: result.target,
                previousSetLabel: _previousSetLabel(
                  context,
                  result,
                  lastLoggedSet ?? previousCompletedSet,
                ),
                progressionHint: progressionHint,
                quickFillChips: _quickFillChips(
                  context,
                  result,
                  lastLoggedSet,
                  previousCompletedSet,
                ),
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
      _repsController.text = reps == null ? '' : reps.toStringAsFixed(0);
      _weightController.text = weight == null ? '' : _formatNumber(weight);
      _timeController.text = time == null ? '' : _formatNumber(time);
      _startRestTimer();
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

  List<Widget> _quickFillChips(
    BuildContext context,
    WorkoutExerciseResult result,
    WorkoutSetLog? lastLoggedSet,
    WorkoutSetLog? previousCompletedSet,
  ) {
    final candidates =
        <WorkoutSetLog>{
          ...?lastLoggedSet == null ? null : [lastLoggedSet],
          ...?previousCompletedSet == null ? null : [previousCompletedSet],
          WorkoutSetLog(
            reps: result.target.reps,
            weight: result.target.weight,
            time: result.target.time,
          ),
        }.where(
          (setLog) =>
              setLog.reps != null ||
              setLog.weight != null ||
              setLog.time != null,
        );

    return [
      for (final setLog in candidates)
        ActionChip(
          label: Text(_chipLabel(result, setLog)),
          onPressed: () => _fillSetLog(setLog),
        ),
    ];
  }

  String? _previousSetLabel(
    BuildContext context,
    WorkoutExerciseResult result,
    WorkoutSetLog? setLog,
  ) {
    if (setLog == null) {
      return null;
    }
    return 'Previous set ${_chipLabel(result, setLog)}';
  }

  String? _progressionHint(
    WorkoutExerciseResult result,
    WorkoutSetLog? referenceSet,
  ) {
    if (referenceSet == null) {
      return null;
    }
    if (result.target.weight != null &&
        (referenceSet.reps ?? 0) >= (result.target.reps ?? 0)) {
      return 'Try +2.5 kg next set if technique stays clean.';
    }
    if (result.target.reps != null) {
      return 'Repeat the load and push until you hit the target reps.';
    }
    return 'Match the previous work set before increasing demand.';
  }

  String _chipLabel(WorkoutExerciseResult result, WorkoutSetLog setLog) {
    return _formatWorkoutSetInline(result, setLog);
  }

  String _formatWorkoutSetInline(
    WorkoutExerciseResult result,
    WorkoutSetLog setLog,
  ) {
    final parts = <String>[];
    if (setLog.weight != null) {
      parts.add('${_formatNumber(setLog.weight!)} ${result.target.unit}');
    }
    if (setLog.reps != null) {
      parts.add('${_formatNumber(setLog.reps!)} reps');
    }
    if (setLog.time != null) {
      parts.add('${_formatNumber(setLog.time!)} ${result.target.unit}');
    }
    return parts.join(' x ');
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

  double? _parseNumber(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized) ?? double.nan;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
