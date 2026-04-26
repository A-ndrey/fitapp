import 'package:flutter/material.dart';

import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../state/app_store.dart';
import '../core/theme/app_theme.dart';
import 'workout_formatters.dart';
import 'workout_session_cards.dart';

typedef WorkoutSetLogCallback = void Function(WorkoutSetLog setLog);

class WorkoutActiveExerciseSummaryCard extends StatelessWidget {
  const WorkoutActiveExerciseSummaryCard({
    required this.result,
    required this.store,
    super.key,
  });

  final WorkoutExerciseResult result;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.exerciseName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatWorkoutTarget(result.target, store),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            WorkoutInfoPill(
              label: formatWorkoutSetCount(result.setLogs.length),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutSetInputCard extends StatelessWidget {
  const WorkoutSetInputCard({
    required this.repsController,
    required this.weightController,
    required this.timeController,
    required this.target,
    required this.onLogSet,
    super.key,
  });

  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController timeController;
  final TrainingExercise target;
  final VoidCallback onLogSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        controller: repsController,
                        decoration: const InputDecoration(labelText: 'Reps'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          helperText: target.weight != null
                              ? target.unit
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
                        controller: timeController,
                        decoration: InputDecoration(
                          labelText: 'Time',
                          helperText: target.time != null ? target.unit : null,
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
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onLogSet,
                icon: const Icon(Icons.add),
                label: const Text('Log set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutLoggedSetsCard extends StatelessWidget {
  const WorkoutLoggedSetsCard({
    required this.target,
    required this.setLogs,
    required this.store,
    required this.onFillSet,
    super.key,
  });

  final TrainingExercise target;
  final List<WorkoutSetLog> setLogs;
  final AppStore store;
  final WorkoutSetLogCallback onFillSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logged sets', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (setLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No logged sets yet'),
              )
            else
              ...setLogs.indexed.map((entry) {
                final setNumber = entry.$1 + 1;
                final setLog = entry.$2;
                return Tooltip(
                  message: 'Use Set $setNumber',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onFillSet(setLog),
                    title: Text('Set $setNumber'),
                    subtitle: Text(formatWorkoutSetLog(target, setLog, store)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class WorkoutPreviousResultsCard extends StatelessWidget {
  const WorkoutPreviousResultsCard({
    required this.history,
    required this.store,
    required this.onFillSet,
    super.key,
  });

  final List<WorkoutExerciseHistoryGroup> history;
  final AppStore store;
  final WorkoutSetLogCallback onFillSet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Previous results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No previous results for this exercise'),
            ),
          )
        else
          ...history.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PreviousResultGroupCard(
                group: group,
                store: store,
                onFillSet: onFillSet,
              ),
            ),
          ),
      ],
    );
  }
}

class WorkoutCompletedSummaryCard extends StatelessWidget {
  const WorkoutCompletedSummaryCard({required this.session, super.key});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed workout',
              style: textTheme.labelLarge?.copyWith(
                color: AppTheme.recoveryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              session.trainingPlanName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                WorkoutInfoPill(
                  label: 'Date: ${formatWorkoutDate(session.startedAt)}',
                ),
                WorkoutInfoPill(
                  label: 'Duration: ${formatWorkoutDuration(session.duration)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutCompletedExerciseResultGroupCard extends StatelessWidget {
  const WorkoutCompletedExerciseResultGroupCard({
    required this.exerciseName,
    required this.results,
    required this.store,
    super.key,
  });

  final String exerciseName;
  final List<WorkoutExerciseResult> results;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exerciseName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...results.indexed.expand((entry) {
              final resultNumber = entry.$1 + 1;
              final result = entry.$2;
              return <Widget>[
                if (results.length > 1) ...[
                  Text(
                    'Entry $resultNumber',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(formatWorkoutTarget(result.target, store)),
                const SizedBox(height: 8),
                if (result.setLogs.isEmpty)
                  const Text('No sets logged')
                else
                  ...result.setLogs.indexed.map((setEntry) {
                    final setNumber = setEntry.$1 + 1;
                    final setLog = setEntry.$2;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Set $setNumber'),
                      subtitle: Text(
                        formatWorkoutSetLog(result.target, setLog, store),
                      ),
                    );
                  }),
                if (resultNumber < results.length) const SizedBox(height: 12),
              ];
            }),
          ],
        ),
      ),
    );
  }
}

class _PreviousResultGroupCard extends StatelessWidget {
  const _PreviousResultGroupCard({
    required this.group,
    required this.store,
    required this.onFillSet,
  });

  final WorkoutExerciseHistoryGroup group;
  final AppStore store;
  final WorkoutSetLogCallback onFillSet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.session.trainingPlanName} • '
              '${formatWorkoutDate(group.session.startedAt)} • '
              '${formatWorkoutDuration(group.session.duration)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (group.results.every((result) => result.setLogs.isEmpty))
              const Text('No sets logged')
            else
              ...group.results.indexed.expand((resultEntry) {
                final resultNumber = resultEntry.$1 + 1;
                final result = resultEntry.$2;
                final hasMultipleResults = group.results.length > 1;
                return result.setLogs.indexed.map((setEntry) {
                  final setNumber = setEntry.$1 + 1;
                  final setLog = setEntry.$2;
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
                      onTap: () => onFillSet(setLog),
                      title: Text(setLabel),
                      subtitle: Text(
                        formatWorkoutSetLog(result.target, setLog, store),
                      ),
                    ),
                  );
                });
              }),
          ],
        ),
      ),
    );
  }
}
