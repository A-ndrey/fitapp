import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.store,
    this.isCurrentTab = true,
  });

  final AppStore store;
  final bool isCurrentTab;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store) {
      if (oldWidget.isCurrentTab != widget.isCurrentTab) {
        _syncTimer();
      }
    } else {
      oldWidget.store.removeListener(_syncTimer);
      widget.store.addListener(_syncTimer);
      _syncTimer();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncTimer);
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final hasActiveSession =
        widget.isCurrentTab && widget.store.activeWorkoutSession != null;
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
        final stats = widget.store.workoutStats;
        final activeSession = widget.store.activeWorkoutSession;
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          floatingActionButton: activeSession == null
              ? FloatingActionButton.extended(
                  tooltip: 'Start workout',
                  onPressed: () => _openStartWorkoutPicker(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start workout'),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeSession != null) ...[
                  Text(
                    'Active workout',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeSession.trainingPlanName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elapsed time: ${_formatDuration(activeSession.duration)}',
                  ),
                  const SizedBox(height: 16),
                  ...activeSession.results.indexed.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkoutResultCard(
                        resultIndex: entry.$1,
                        result: entry.$2,
                        store: widget.store,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: () => _finishWorkout(context),
                    child: const Text('Finish workout'),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Workout stats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('Completed sessions: ${stats.completedCount}'),
                const SizedBox(height: 4),
                Text(
                  'Total workout time: ${_formatDuration(stats.totalDuration)}',
                ),
                if (stats.latestSession != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Latest workout: ${stats.latestSession!.trainingPlanName}',
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Workout history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (widget.store.completedWorkoutSessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No completed workouts yet'),
                  )
                else
                  ...widget.store.completedWorkoutSessions.reversed.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(session.trainingPlanName),
                          subtitle: Text(
                            'Completed • ${_formatDuration(session.duration)}',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openStartWorkoutPicker(BuildContext context) async {
    final plan = await showModalBottomSheet<TrainingPlan>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose a training plan',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.store.trainingPlans.map(
                (trainingPlan) => ListTile(
                  leading: const Icon(Icons.playlist_add_check_outlined),
                  title: Text(trainingPlan.name),
                  subtitle: Text(trainingPlan.description),
                  onTap: () => Navigator.of(sheetContext).pop(trainingPlan),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!context.mounted || plan == null) {
      return;
    }
    try {
      widget.store.startWorkout(trainingPlanId: plan.id);
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _finishWorkout(BuildContext context) async {
    try {
      widget.store.finishActiveWorkout();
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
}

class _WorkoutResultCard extends StatelessWidget {
  const _WorkoutResultCard({
    required this.resultIndex,
    required this.result,
    required this.store,
  });

  final int resultIndex;
  final WorkoutExerciseResult result;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.exerciseName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(_formatTarget(result.target)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 640
                    ? 180.0
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _WorkoutResultField(
                      width: fieldWidth,
                      label: 'Actual sets',
                      value: result.actualSets,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (text) {
                        _updateResult(
                          updateSets: true,
                          sets: _parseNumber(text),
                        );
                      },
                    ),
                    _WorkoutResultField(
                      width: fieldWidth,
                      label: 'Actual reps',
                      value: result.actualReps,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (text) {
                        _updateResult(
                          updateReps: true,
                          reps: _parseNumber(text),
                        );
                      },
                    ),
                    _WorkoutResultField(
                      width: fieldWidth,
                      label: 'Actual weight',
                      value: result.actualWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (text) {
                        _updateResult(
                          updateWeight: true,
                          weight: _parseNumber(text),
                        );
                      },
                    ),
                    _WorkoutResultField(
                      width: fieldWidth,
                      label: 'Actual time',
                      value: result.actualTime,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (text) {
                        _updateResult(
                          updateTime: true,
                          time: _parseNumber(text),
                        );
                      },
                    ),
                    _WorkoutResultField(
                      width: fieldWidth,
                      label: 'Actual unit',
                      value: result.actualUnit,
                      keyboardType: TextInputType.text,
                      onChanged: (text) {
                        _updateResult(
                          unit: text.trim().isEmpty ? result.actualUnit : text,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateResult({
    bool updateSets = false,
    double? sets,
    bool updateReps = false,
    double? reps,
    bool updateWeight = false,
    double? weight,
    bool updateTime = false,
    double? time,
    String? unit,
  }) {
    final session = store.activeWorkoutSession;
    if (session == null ||
        resultIndex < 0 ||
        resultIndex >= session.results.length) {
      return;
    }
    final current = session.results[resultIndex];
    try {
      store.updateActiveWorkoutResult(
        resultIndex: resultIndex,
        actualSets: updateSets ? sets : current.actualSets,
        actualReps: updateReps ? reps : current.actualReps,
        actualWeight: updateWeight ? weight : current.actualWeight,
        actualTime: updateTime ? time : current.actualTime,
        actualUnit: unit ?? current.actualUnit,
      );
    } on Object {
      // Ignore transient invalid input while the user edits a field.
    }
  }

  double? _parseNumber(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized) ?? double.nan;
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _WorkoutResultField extends StatelessWidget {
  const _WorkoutResultField({
    required this.width,
    required this.label,
    required this.value,
    required this.keyboardType,
    required this.onChanged,
  });

  final double width;
  final String label;
  final Object? value;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: _formatValue(value),
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }

  String _formatValue(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toStringAsFixed(0);
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}
