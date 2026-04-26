import 'package:flutter/material.dart';

import '../../models/workout_session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/metric_card.dart';
import 'workout_formatters.dart';
import 'workout_session_cards.dart';

class ActiveWorkoutCard extends StatelessWidget {
  const ActiveWorkoutCard({
    required this.session,
    required this.onOpen,
    super.key,
  });

  final WorkoutSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: 'Open active workout',
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
                  'Active workout',
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
                          'Elapsed ${formatWorkoutDuration(session.duration)}',
                    ),
                    WorkoutInfoPill(
                      label:
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
  });

  final int completedCount;
  final Duration totalDuration;
  final String? latestSessionName;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      MetricCard(
        label: 'Completed',
        value: completedCount.toString(),
        suffix: completedCount == 1 ? 'session' : 'sessions',
        icon: Icons.check_circle_outline,
        color: AppTheme.energyOrange,
      ),
      MetricCard(
        label: 'Total time',
        value: formatWorkoutDuration(totalDuration),
        icon: Icons.timer_outlined,
        color: AppTheme.recoveryBlue,
      ),
      if (latestSessionName != null)
        MetricCard(
          label: 'Latest',
          value: latestSessionName!,
          icon: Icons.history,
          color: Theme.of(context).colorScheme.tertiary,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 480
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class WorkoutHistoryCard extends StatelessWidget {
  const WorkoutHistoryCard({
    required this.session,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final WorkoutSession session;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        title: Tooltip(
          message: 'Open completed ${session.trainingPlanName}',
          child: Text(session.trainingPlanName),
        ),
        subtitle: Text(
          '${formatWorkoutDate(session.startedAt)} • '
          '${formatWorkoutDuration(session.duration)}',
        ),
        trailing: IconButton(
          tooltip: 'Delete completed ${session.trainingPlanName}',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
