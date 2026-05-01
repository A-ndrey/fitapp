import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/workout_session.dart';
import '../core/layout/responsive_layout.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/metric_card.dart';
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
                    color: AppTheme.energyOrange,
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
    this.latestSessionName,
    super.key,
    this.l10n,
  });

  final int completedCount;
  final Duration totalDuration;
  final String? latestSessionName;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final duration = formatWorkoutDuration(
      totalDuration,
      hourUnit: l10n?.workoutHourUnit ?? 'h',
      minuteUnit: l10n?.workoutMinuteUnit ?? 'min',
    );
    final cards = <Widget>[
      MetricCard(
        label: l10n?.workoutCompletedMetricLabel ?? 'Completed',
        value: completedCount.toString(),
        suffix:
            l10n?.workoutSessionCountSuffix(completedCount) ??
            (completedCount == 1 ? 'session' : 'sessions'),
        icon: Icons.check_circle_outline,
        color: AppTheme.energyOrange,
      ),
      MetricCard(
        label: l10n?.workoutTotalTimeMetricLabel ?? 'Total time',
        value: duration,
        icon: Icons.timer_outlined,
        color: AppTheme.recoveryBlue,
      ),
      if (latestSessionName != null)
        MetricCard(
          label: l10n?.workoutLatestMetricLabel ?? 'Latest',
          value: latestSessionName!,
          icon: Icons.history,
          color: Theme.of(context).colorScheme.tertiary,
        ),
    ];

    return ResponsiveWrap(maxItemExtent: 260, spacing: 12, children: cards);
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
    return Card(
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
        trailing: IconButton(
          tooltip:
              l10n?.workoutDeleteCompletedTooltip(session.trainingPlanName) ??
              'Delete completed ${session.trainingPlanName}',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
