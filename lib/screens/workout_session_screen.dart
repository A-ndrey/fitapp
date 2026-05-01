import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_formatters.dart';
import '../ui/workout/workout_session_cards.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.workoutSessionTitle ?? 'Workout session'),
          ),
          body: AdaptivePage(
            children: [
              WorkoutSessionHeaderCard(session: session, l10n: l10n),
              const SizedBox(height: 24),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkoutExerciseProgressCard(
                    exerciseLabel: exerciseLabel,
                    targetLabel: formatWorkoutTarget(
                      result.target,
                      widget.store,
                    ),
                    setCountLabel: formatWorkoutSetCount(result.setLogs.length),
                    tooltip: tooltipLabel,
                    onOpen: () => _openExercise(context, resultIndex),
                  ),
                );
              }),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _finishWorkout(context),
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n?.workoutFinishAction ?? 'Finish workout'),
              ),
            ],
          ),
        );
      },
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
