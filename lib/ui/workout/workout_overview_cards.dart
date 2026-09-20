import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/workout_session.dart';
import '../core/layout/app_breakpoints.dart';
import '../core/widgets/swipe_action_card.dart';
import 'workout_formatters.dart';
import 'workout_session_cards.dart';

class ActiveWorkoutCard extends StatelessWidget {
  const ActiveWorkoutCard({
    required this.session,
    required this.onOpen,
    super.key,
    this.l10n,
  });

  final WorkoutSession session;
  final VoidCallback onOpen;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final duration = formatWorkoutDuration(
      session.duration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );

    return Tooltip(
      message: l10n?.workoutOpenActiveTooltip ?? 'Open active workout',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.workoutActiveLabel ?? 'Active workout',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
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
                          l10n?.workoutElapsedLabel(duration) ??
                          'Elapsed $duration',
                    ),
                    WorkoutInfoPill(
                      label:
                          l10n?.workoutExerciseCount(session.results.length) ??
                          '${session.results.length} ${session.results.length == 1 ? 'exercise' : 'exercises'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutStatsGrid extends StatelessWidget {
  const WorkoutStatsGrid({
    required this.completedCount,
    required this.totalDuration,
    required this.setCount,
    super.key,
    this.l10n,
  });

  final int completedCount;
  final Duration totalDuration;
  final int setCount;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final duration = formatWorkoutDuration(
      totalDuration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );
    final cards = [
      _WorkoutMetric(
        label: l10n?.workoutPeriodWorkouts ?? 'Workouts',
        value: '$completedCount',
      ),
      _WorkoutMetric(label: l10n?.workoutPeriodTime ?? 'Time', value: duration),
      _WorkoutMetric(
        label: l10n?.workoutPeriodSets ?? 'Sets',
        value: '$setCount',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumWidth = 85 * MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < minimumWidth * 3 + 16) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                cards[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  const _WorkoutMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label, $value',
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({
    required this.session,
    required this.onOpen,
    required this.onDelete,
    super.key,
    this.l10n,
  });

  final WorkoutSession session;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final duration = formatWorkoutDuration(
      session.duration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    return SwipeActionCard(
      actions: [
        SwipeCardAction(
          label: l10n?.commonDelete ?? 'Delete',
          icon: Icons.delete_outline,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: onDelete,
        ),
      ],
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onOpen,
          title: Tooltip(
            message:
                l10n?.workoutOpenCompletedTooltip(session.trainingPlanName) ??
                'Open completed ${session.trainingPlanName}',
            child: Text(session.trainingPlanName),
          ),
          subtitle: Text(
            '${formatWorkoutDate(session.startedAt)} • '
            '$duration',
          ),
          trailing: isCompact
              ? null
              : IconButton(
                  tooltip:
                      l10n?.workoutDeleteCompletedTooltip(
                        session.trainingPlanName,
                      ) ??
                      'Delete completed ${session.trainingPlanName}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
        ),
      ),
    );
  }
}
