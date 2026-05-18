import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
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
    final measurementType = _measurementTypeForResult(store, result);

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
                measurementType,
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
    required this.durationController,
    required this.distanceController,
    required this.assistanceWeightController,
    required this.measurementType,
    required this.store,
    required this.onLogSet,
    super.key,
    this.progressionHint,
    this.previousSetLabel,
    this.quickFillChips = const [],
  });

  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
  final TextEditingController distanceController;
  final TextEditingController assistanceWeightController;
  final ExerciseMeasurementType measurementType;
  final AppStore store;
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
                final fields = workoutFieldsForMeasurementType(measurementType);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final field in fields)
                      SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _controllerFor(field),
                          decoration: InputDecoration(
                            labelText: _fieldLabel(field, l10n),
                            helperText: _fieldHelperText(field),
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

  TextEditingController _controllerFor(WorkoutLogField field) {
    switch (field) {
      case WorkoutLogField.reps:
        return repsController;
      case WorkoutLogField.weight:
        return weightController;
      case WorkoutLogField.duration:
        return durationController;
      case WorkoutLogField.distance:
        return distanceController;
      case WorkoutLogField.assistanceWeight:
        return assistanceWeightController;
    }
  }

  String _fieldLabel(WorkoutLogField field, AppLocalizations? l10n) {
    switch (field) {
      case WorkoutLogField.reps:
        return l10n?.workoutRepsFieldLabel ?? 'Reps';
      case WorkoutLogField.weight:
        return l10n?.workoutWeightFieldLabel ?? 'Weight';
      case WorkoutLogField.duration:
        return 'Duration';
      case WorkoutLogField.distance:
        return 'Distance';
      case WorkoutLogField.assistanceWeight:
        return 'Assistance weight';
    }
  }

  String? _fieldHelperText(WorkoutLogField field) {
    final unit = preferredWorkoutFieldUnit(field, store);
    return unit.isEmpty ? null : unit;
  }
}

class WorkoutLoggedSetsCard extends StatelessWidget {
  const WorkoutLoggedSetsCard({
    required this.measurementType,
    required this.setLogs,
    required this.store,
    required this.onFillSet,
    super.key,
  });

  final ExerciseMeasurementType measurementType;
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
                        setLog,
                        measurementType,
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
                    _measurementTypeForResult(store, result),
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
                          setLog,
                          _measurementTypeForResult(store, result),
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
                          setLog,
                          _measurementTypeForResult(store, result),
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

ExerciseMeasurementType _measurementTypeForResult(
  AppStore store,
  WorkoutExerciseResult result,
) {
  return store.exerciseById(result.exerciseId)?.measurementType ??
      ExerciseMeasurementType.strength;
}
