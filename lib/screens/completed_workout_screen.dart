import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../models/workout_session.dart';

class CompletedWorkoutScreen extends StatelessWidget {
  const CompletedWorkoutScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final resultGroups = _groupResults(session.results);
    return Scaffold(
      appBar: AppBar(title: const Text('Completed workout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              session.trainingPlanName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Duration: ${_formatDuration(session.duration)}'),
            const SizedBox(height: 4),
            Text('Started: ${_formatDateTime(session.startedAt)}'),
            if (session.finishedAt != null) ...[
              const SizedBox(height: 4),
              Text('Finished: ${_formatDateTime(session.finishedAt!)}'),
            ],
            const SizedBox(height: 24),
            Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...resultGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...group.results.indexed.expand((resultEntry) {
                          final resultNumber = resultEntry.$1 + 1;
                          final result = resultEntry.$2;
                          return <Widget>[
                            if (group.results.length > 1) ...[
                              Text(
                                'Entry $resultNumber',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(_formatTarget(result.target)),
                            const SizedBox(height: 8),
                            if (result.setLogs.isEmpty)
                              const Text('No sets logged')
                            else
                              ...result.setLogs.indexed.map((entry) {
                                final setNumber = entry.$1 + 1;
                                final setLog = entry.$2;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Set $setNumber'),
                                  subtitle: Text(
                                    _formatSetLog(result.target, setLog),
                                  ),
                                );
                              }),
                            if (resultNumber < group.results.length)
                              const SizedBox(height: 12),
                          ];
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_WorkoutExerciseResultGroup> _groupResults(
    List<WorkoutExerciseResult> results,
  ) {
    final groups = <_WorkoutExerciseResultGroup>[];
    for (final result in results) {
      final existingIndex = groups.indexWhere(
        (group) => group.exerciseId == result.exerciseId,
      );
      if (existingIndex == -1) {
        groups.add(
          _WorkoutExerciseResultGroup(
            exerciseId: result.exerciseId,
            exerciseName: result.exerciseName,
            results: <WorkoutExerciseResult>[result],
          ),
        );
      } else {
        groups[existingIndex] = groups[existingIndex].copyWithResult(result);
      }
    }
    return groups;
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

  String _formatSetLog(TrainingExercise target, WorkoutSetLog setLog) {
    final parts = <String>[];
    if (setLog.reps != null) {
      parts.add('${_formatNumber(setLog.reps!)} reps');
    }
    if (setLog.weight != null) {
      parts.add('${_formatNumber(setLog.weight!)} ${target.unit}');
    }
    if (setLog.time != null) {
      parts.add('${_formatNumber(setLog.time!)} ${target.unit}');
    }
    return parts.join(' • ');
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

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _WorkoutExerciseResultGroup {
  const _WorkoutExerciseResultGroup({
    required this.exerciseId,
    required this.exerciseName,
    required this.results,
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutExerciseResult> results;

  _WorkoutExerciseResultGroup copyWithResult(WorkoutExerciseResult result) {
    return _WorkoutExerciseResultGroup(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      results: <WorkoutExerciseResult>[...results, result],
    );
  }
}
