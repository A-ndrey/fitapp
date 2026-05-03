import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/workout_session.dart';
import 'workout_formatters.dart';

class WorkoutSessionHeaderCard extends StatelessWidget {
  const WorkoutSessionHeaderCard({required this.session, super.key, this.l10n});

  final WorkoutSession session;
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
    final totalVolume = session.results.fold<double>(0, (total, result) {
      final resultVolume = result.setLogs.fold<double>(
        0,
        (setTotal, setLog) =>
            setTotal + (setLog.weight ?? 0) * (setLog.reps ?? 0),
      );
      return total + resultVolume;
    });
    final completedExercises = session.results
        .where((result) => result.setLogs.isNotEmpty)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.workoutSessionCockpitLabel ?? 'Active session',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
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
                WorkoutInfoPill(
                  label:
                      'Total volume ${totalVolume <= 0 ? '0 kg' : '${totalVolume.toStringAsFixed(totalVolume >= 1000 ? 0 : 1)} kg'}',
                ),
                WorkoutInfoPill(
                  label:
                      '$completedExercises/${session.results.length} completed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutExerciseProgressCard extends StatelessWidget {
  const WorkoutExerciseProgressCard({
    required this.exerciseLabel,
    required this.targetLabel,
    required this.setCountLabel,
    required this.tooltip,
    required this.onOpen,
    super.key,
  });

  final String exerciseLabel;
  final String targetLabel;
  final String setCountLabel;
  final String tooltip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.14,
                  ),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.fitness_center),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseLabel,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        targetLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        setCountLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WorkoutInfoPill extends StatelessWidget {
  const WorkoutInfoPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
