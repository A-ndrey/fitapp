import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../state/app_store.dart';
import 'workout_exercise_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncTimer);
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    if (widget.store.activeWorkoutSession == null) {
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
        if (session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout session')),
            body: const SafeArea(child: SizedBox.shrink()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Workout session')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  session.trainingPlanName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('Elapsed time: ${_formatDuration(session.duration)}'),
                const SizedBox(height: 24),
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...session.results.indexed.map((entry) {
                  final resultIndex = entry.$1;
                  final result = entry.$2;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Tooltip(
                      message: 'Open ${result.exerciseName}',
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openExercise(context, resultIndex),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.exerciseName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(_formatTarget(result.target)),
                                const SizedBox(height: 4),
                                Text(_formatSetCount(result.setLogs.length)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _finishWorkout(context),
                  child: const Text('Finish workout'),
                ),
              ],
            ),
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

  String _formatTarget(TrainingExercise target) {
    final parts = <String>[];
    if (target.sets != null) {
      parts.add('${_formatNumber(target.sets!)} sets');
    }
    if (target.reps != null) {
      parts.add('${_formatNumber(target.reps!)} reps');
    }
    if (target.weight != null) {
      parts.add('${_formatNumber(target.weight!)} ${target.unit}');
    } else if (target.time != null) {
      parts.add('${_formatNumber(target.time!)} ${target.unit}');
    } else if (parts.isEmpty) {
      parts.add(target.unit);
    }
    return 'Target: ${parts.join(' • ')}';
  }

  String _formatSetCount(int count) {
    if (count == 1) {
      return '1 set logged';
    }
    return '$count sets logged';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0 ? '$hours h' : '$hours h $minutes min';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    }
    return '0 min';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
