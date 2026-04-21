import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';

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
        final session = widget.store.activeWorkoutSession;
        if (session == null ||
            widget.resultIndex < 0 ||
            widget.resultIndex >= session.results.length) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout exercise')),
            body: const SafeArea(child: SizedBox.shrink()),
          );
        }
        final result = session.results[widget.resultIndex];
        final history = widget.store.completedWorkoutHistoryForExercise(
          result.exerciseId,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Workout exercise')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  result.exerciseName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(_formatTarget(result.target)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth >= 640
                        ? 180.0
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _repsController,
                            decoration: const InputDecoration(
                              labelText: 'Reps',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'Weight',
                              helperText: result.target.weight != null
                                  ? result.target.unit
                                  : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _timeController,
                            decoration: InputDecoration(
                              labelText: 'Time',
                              helperText: result.target.time != null
                                  ? result.target.unit
                                  : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _logSet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Log set'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Logged sets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (result.setLogs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No logged sets yet'),
                  )
                else
                  ...result.setLogs.indexed.map((entry) {
                    final setNumber = entry.$1 + 1;
                    final setLog = entry.$2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Tooltip(
                        message: 'Use Set $setNumber',
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => _fillSetLog(setLog),
                            title: Text('Set $setNumber'),
                            subtitle: Text(
                              _formatSetLog(result.target, setLog),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Text(
                  'Previous results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No previous results for this exercise'),
                  )
                else
                  ...history.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${group.session.trainingPlanName} • ${_formatDuration(group.session.duration)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              if (group.results.every(
                                (historyResult) =>
                                    historyResult.setLogs.isEmpty,
                              ))
                                const Text('No sets logged')
                              else
                                ...group.results.expand((historyResult) {
                                  final resultNumber =
                                      group.results.indexOf(historyResult) + 1;
                                  final hasMultipleResults =
                                      group.results.length > 1;
                                  return historyResult.setLogs.indexed.map((
                                    entry,
                                  ) {
                                    final setNumber = entry.$1 + 1;
                                    final setLog = entry.$2;
                                    final setLabel = hasMultipleResults
                                        ? 'Entry $resultNumber • Set $setNumber'
                                        : 'Set $setNumber';
                                    final tooltipLabel = hasMultipleResults
                                        ? 'Use previous Entry $resultNumber Set $setNumber from ${group.session.trainingPlanName}'
                                        : 'Use previous Set $setNumber from ${group.session.trainingPlanName}';
                                    return Tooltip(
                                      message: tooltipLabel,
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () => _fillSetLog(setLog),
                                        title: Text(setLabel),
                                        subtitle: Text(
                                          _formatSetLog(
                                            historyResult.target,
                                            setLog,
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
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
    _repsController.text = _formatInputNumber(setLog.reps);
    _weightController.text = _formatInputNumber(setLog.weight);
    _timeController.text = _formatInputNumber(setLog.time);
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

  String _formatInputNumber(double? value) {
    if (value == null) {
      return '';
    }
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}
