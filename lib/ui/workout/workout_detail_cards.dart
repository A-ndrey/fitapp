import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../state/app_store.dart';
import '../core/widgets/swipe_action_card.dart';
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
    required this.target,
    required this.repsController,
    required this.weightController,
    required this.durationController,
    required this.distanceController,
    required this.assistanceWeightController,
    required this.measurementType,
    required this.store,
    required this.onLogSet,
    super.key,
  });

  final TrainingExercise target;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
  final TextEditingController distanceController;
  final TextEditingController assistanceWeightController;
  final ExerciseMeasurementType measurementType;
  final AppStore store;
  final VoidCallback onLogSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatWorkoutTarget(
            target,
            measurementType,
            store,
            targetPrefix: null,
            setsLabel: l10n?.workoutSetsLabel ?? 'sets',
            repsLabel: l10n?.workoutRepsLabel ?? 'reps',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
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
    final unit = preferredWorkoutFieldUnit(field, store);
    switch (field) {
      case WorkoutLogField.reps:
        return l10n?.workoutRepsFieldLabel ?? 'Reps';
      case WorkoutLogField.weight:
        return _fieldLabelWithUnit(
          l10n?.workoutWeightFieldLabel ?? 'Weight',
          unit,
        );
      case WorkoutLogField.duration:
        return _fieldLabelWithUnit('Duration', unit);
      case WorkoutLogField.distance:
        return _fieldLabelWithUnit('Distance', unit);
      case WorkoutLogField.assistanceWeight:
        return _fieldLabelWithUnit('Assistance weight', unit);
    }
  }

  String _fieldLabelWithUnit(String label, String unit) {
    if (unit.isEmpty) {
      return label;
    }
    return '$label, $unit';
  }
}

class WorkoutExerciseMetaBlock extends StatefulWidget {
  const WorkoutExerciseMetaBlock({required this.exercise, super.key});

  final Exercise exercise;

  @override
  State<WorkoutExerciseMetaBlock> createState() =>
      _WorkoutExerciseMetaBlockState();
}

class _WorkoutExerciseMetaBlockState extends State<WorkoutExerciseMetaBlock> {
  bool _instructionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.exercise.description.trim();
    final instruction = widget.exercise.instruction.trim();
    if (description.isEmpty && instruction.isEmpty) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty)
          Text(description, style: textTheme.bodyLarge),
        if (description.isNotEmpty && instruction.isNotEmpty)
          const SizedBox(height: 8),
        if (instruction.isNotEmpty)
          _ExpandableInstructionText(
            instruction: instruction,
            expanded: _instructionExpanded,
            onToggle: () {
              setState(() {
                _instructionExpanded = !_instructionExpanded;
              });
            },
          ),
      ],
    );
  }
}

class _ExpandableInstructionText extends StatelessWidget {
  const _ExpandableInstructionText({
    required this.instruction,
    required this.expanded,
    required this.onToggle,
  });

  final String instruction;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final painter = TextPainter(
          text: TextSpan(text: instruction, style: textStyle),
          textDirection: direction,
          maxLines: 3,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflowing = painter.didExceedMaxLines;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isOverflowing ? onToggle : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instruction,
                style: textStyle,
                maxLines: expanded ? null : 3,
                overflow: expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (isOverflowing) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onToggle,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(expanded ? 'Show less' : 'Show more'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class WorkoutExerciseHistoryCard extends StatelessWidget {
  const WorkoutExerciseHistoryCard({
    required this.measurementType,
    required this.currentSession,
    required this.currentResult,
    required this.history,
    required this.store,
    required this.onFillSet,
    super.key,
  });

  final ExerciseMeasurementType measurementType;
  final WorkoutSession currentSession;
  final WorkoutExerciseResult currentResult;
  final List<WorkoutExerciseHistoryGroup> history;
  final AppStore store;
  final WorkoutSetLogCallback onFillSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final historyGroups = _historyGroups(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (historyGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n?.workoutNoPreviousResults ??
                  'No previous results for this exercise',
            ),
          )
        else
          ...historyGroups.expand(
            (group) => <Widget>[
              _WorkoutHistoryDivider(title: group.title),
              ...group.rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SwipeActionCard(
                    enabled: row.onDelete != null,
                    actions: row.onDelete == null
                        ? const []
                        : [
                            SwipeCardAction(
                              label: l10n?.commonDelete ?? 'Delete',
                              icon: Icons.delete_outline,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              onPressed: row.onDelete!,
                            ),
                          ],
                    child: Card(
                      child: ListTile(
                        title: Text(row.label),
                        onTap: () => onFillSet(row.setLog),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<_WorkoutHistoryRenderGroup> _historyGroups(AppLocalizations? l10n) {
    final groups = <_WorkoutHistoryRenderGroup>[];
    final currentRows = _rowsForResults(
      [currentResult],
      l10n,
      activeResultIndex: currentSession.results.indexOf(currentResult),
    );
    if (currentRows.isNotEmpty) {
      groups.add(
        _WorkoutHistoryRenderGroup(
          title:
              '${currentSession.trainingPlanName} • '
              '${formatWorkoutTimestamp(currentSession.startedAt)}',
          rows: currentRows,
        ),
      );
    }
    for (final group in history) {
      final rows = _rowsForResults(group.results, l10n);
      if (rows.isEmpty) {
        continue;
      }
      groups.add(
        _WorkoutHistoryRenderGroup(
          title:
              '${group.session.trainingPlanName} • '
              '${formatWorkoutTimestamp(group.session.startedAt)}',
          rows: rows,
        ),
      );
    }
    return groups;
  }

  List<_WorkoutHistoryRenderRow> _rowsForResults(
    List<WorkoutExerciseResult> results,
    AppLocalizations? l10n, {
    int? activeResultIndex,
  }) {
    final rows = <_WorkoutHistoryRenderRow>[];
    for (
      var resultOffset = results.length - 1;
      resultOffset >= 0;
      resultOffset--
    ) {
      final result = results[resultOffset];
      for (var index = result.setLogs.length - 1; index >= 0; index--) {
        final setLog = result.setLogs[index];
        final setNumber = index + 1;
        rows.add(
          _WorkoutHistoryRenderRow(
            label:
                '#$setNumber • '
                '${formatWorkoutSetLog(setLog, measurementType, store, repsLabel: l10n?.workoutRepsLabel ?? 'reps')}',
            setLog: setLog,
            onDelete: activeResultIndex == null
                ? null
                : () => store.removeActiveWorkoutSet(
                    resultIndex: activeResultIndex + resultOffset,
                    setIndex: index,
                  ),
          ),
        );
      }
    }
    return rows;
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

class _WorkoutHistoryDivider extends StatelessWidget {
  const _WorkoutHistoryDivider({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _WorkoutHistoryRenderGroup {
  const _WorkoutHistoryRenderGroup({required this.title, required this.rows});

  final String title;
  final List<_WorkoutHistoryRenderRow> rows;
}

class _WorkoutHistoryRenderRow {
  const _WorkoutHistoryRenderRow({
    required this.label,
    required this.setLog,
    this.onDelete,
  });

  final String label;
  final WorkoutSetLog setLog;
  final VoidCallback? onDelete;
}

ExerciseMeasurementType _measurementTypeForResult(
  AppStore store,
  WorkoutExerciseResult result,
) {
  return store.exerciseById(result.exerciseId)?.measurementType ??
      ExerciseMeasurementType.strength;
}
