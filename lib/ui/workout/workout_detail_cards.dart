import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../state/app_store.dart';
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
    final l10n = AppLocalizations.of(context);

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
              formatWorkoutTarget(
                result.target,
                store,
                targetPrefix: l10n?.workoutTargetPrefix ?? 'Target:',
                setsLabel: l10n?.workoutSetsLabel ?? 'sets',
                repsLabel: l10n?.workoutRepsLabel ?? 'reps',
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            WorkoutInfoPill(
              label: formatWorkoutSetCount(
                result.setLogs.length,
                setCountLoggedLabel: l10n?.workoutSetCountLogged,
              ),
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
    this.progressionHint,
    this.previousSetLabel,
    this.quickFillChips = const [],
  });

  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController timeController;
  final TrainingExercise target;
  final VoidCallback onLogSet;
  final String? progressionHint;
  final String? previousSetLabel;
  final List<Widget> quickFillChips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fast set logging',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (previousSetLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                previousSetLabel!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (progressionHint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  progressionHint!,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
            if (quickFillChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: quickFillChips),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 640
                    ? 180.0
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (target.reps != null)
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: repsController,
                          decoration: InputDecoration(
                            labelText: l10n?.workoutRepsFieldLabel ?? 'Reps',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    if (target.weight != null || target.unit == 'kg')
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: weightController,
                          decoration: InputDecoration(
                            labelText:
                                l10n?.workoutWeightFieldLabel ?? 'Weight',
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
                          labelText: l10n?.workoutTimeFieldLabel ?? 'Time',
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onLogSet,
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n?.workoutLogSetAction ?? 'Log set'),
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
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.workoutLoggedSetsTitle ?? 'Logged sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (setLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n?.workoutNoLoggedSetsYet ?? 'No logged sets yet',
                ),
              )
            else
              ...setLogs.indexed.map((entry) {
                final setNumber = entry.$1 + 1;
                final setLog = entry.$2;
                return Tooltip(
                  message:
                      l10n?.workoutUseSetTooltip(setNumber) ??
                      'Use Set $setNumber',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onFillSet(setLog),
                    title: Text(
                      l10n?.workoutSetLabel(setNumber) ?? 'Set $setNumber',
                    ),
                    subtitle: Text(
                      formatWorkoutSetLog(
                        target,
                        setLog,
                        store,
                        repsLabel: l10n?.workoutRepsLabel ?? 'reps',
                      ),
                    ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n?.workoutPreviousResultsTitle ?? 'Previous results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n?.workoutNoPreviousResults ??
                    'No previous results for this exercise',
              ),
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
                l10n: l10n,
              ),
            ),
          ),
      ],
    );
  }
}

class WorkoutCompletedSummaryCard extends StatelessWidget {
  const WorkoutCompletedSummaryCard({
    required this.session,
    super.key,
    this.l10n,
  });

  final WorkoutSession session;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = formatWorkoutDuration(
      session.duration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.workoutCompletedTitle ?? 'Completed workout',
              style: textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
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
                  label:
                      l10n?.workoutDateLabel(
                        formatWorkoutDate(session.startedAt),
                      ) ??
                      'Date: ${formatWorkoutDate(session.startedAt)}',
                ),
                WorkoutInfoPill(
                  label:
                      l10n?.workoutDurationLabel(duration) ??
                      'Duration: $duration',
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
    this.l10n,
  });

  final String exerciseName;
  final List<WorkoutExerciseResult> results;
  final AppStore store;
  final AppLocalizations? l10n;

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
                    l10n?.workoutEntryLabel(resultNumber) ??
                        'Entry $resultNumber',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  formatWorkoutTarget(
                    result.target,
                    store,
                    targetPrefix: l10n?.workoutTargetPrefix ?? 'Target:',
                    setsLabel: l10n?.workoutSetsLabel ?? 'sets',
                    repsLabel: l10n?.workoutRepsLabel ?? 'reps',
                  ),
                ),
                const SizedBox(height: 8),
                if (result.setLogs.isEmpty)
                  Text(l10n?.workoutNoSetsLogged ?? 'No sets logged')
                else
                  ...result.setLogs.indexed.map((setEntry) {
                    final setNumber = setEntry.$1 + 1;
                    final setLog = setEntry.$2;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n?.workoutSetLabel(setNumber) ?? 'Set $setNumber',
                      ),
                      subtitle: Text(
                        formatWorkoutSetLog(
                          result.target,
                          setLog,
                          store,
                          repsLabel: l10n?.workoutRepsLabel ?? 'reps',
                        ),
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
    this.l10n,
  });

  final WorkoutExerciseHistoryGroup group;
  final AppStore store;
  final WorkoutSetLogCallback onFillSet;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final duration = formatWorkoutDuration(
      group.session.duration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.session.trainingPlanName} • '
              '${formatWorkoutDate(group.session.startedAt)} • '
              '$duration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (group.results.every((result) => result.setLogs.isEmpty))
              Text(l10n?.workoutNoSetsLogged ?? 'No sets logged')
            else
              ...group.results.indexed.expand((resultEntry) {
                final resultNumber = resultEntry.$1 + 1;
                final result = resultEntry.$2;
                final hasMultipleResults = group.results.length > 1;
                return result.setLogs.indexed.map((setEntry) {
                  final setNumber = setEntry.$1 + 1;
                  final setLog = setEntry.$2;
                  final setLabel = hasMultipleResults
                      ? l10n?.workoutPreviousSetLabel(
                              resultNumber,
                              setNumber,
                            ) ??
                            'Entry $resultNumber • Set $setNumber'
                      : l10n?.workoutSetLabel(setNumber) ?? 'Set $setNumber';
                  final tooltipLabel = hasMultipleResults
                      ? l10n?.workoutUsePreviousEntrySetTooltip(
                              resultNumber,
                              setNumber,
                              group.session.trainingPlanName,
                            ) ??
                            'Use previous Entry $resultNumber Set $setNumber from ${group.session.trainingPlanName}'
                      : l10n?.workoutUsePreviousSetTooltip(
                              setNumber,
                              group.session.trainingPlanName,
                            ) ??
                            'Use previous Set $setNumber from ${group.session.trainingPlanName}';
                  return Tooltip(
                    message: tooltipLabel,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => onFillSet(setLog),
                      title: Text(setLabel),
                      subtitle: Text(
                        formatWorkoutSetLog(
                          result.target,
                          setLog,
                          store,
                          repsLabel: l10n?.workoutRepsLabel ?? 'reps',
                        ),
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
