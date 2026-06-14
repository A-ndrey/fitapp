import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/theme/app_theme.dart';
import '../ui/core/widgets/dashboard_panels.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_formatters.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.store,
    required this.onOpenTrain,
    required this.onOpenNutrition,
    required this.onOpenLibrary,
    this.onOpenActiveWorkout,
    this.onStartWorkout,
    this.currentDateTime,
  });

  final AppStore store;
  final VoidCallback onOpenTrain;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenLibrary;
  final VoidCallback? onOpenActiveWorkout;
  final FutureOr<void> Function(TrainingPlan plan)? onStartWorkout;
  final DateTime Function()? currentDateTime;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
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
    if (widget.store.activeWorkoutSession == null) {
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
        final l10n = AppLocalizations.of(context);
        final activeSession = widget.store.activeWorkoutSession;
        final dailyTotals = widget.store.dailyTotals;
        final dailyMacroTargets = widget.store.dailyMacroTargets;
        final workoutRecommendation = widget.currentDateTime == null
            ? widget.store.todayWorkoutRecommendation
            : widget.store.trainingPlans.isEmpty
            ? null
            : widget.store.todayWorkoutRecommendationAt(
                widget.currentDateTime!(),
              );

        return Scaffold(
          appBar: AppBar(title: Text(l10n?.destinationToday ?? 'Today')),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: activeSession == null
                    ? 'Daily progress'
                    : 'Active workout',
              ),
              DashboardPanel(
                title: 'Nutrition',
                eyebrow: 'Today',
                emphasis: DashboardPanelEmphasis.raisedSurface,
                trailing: DashboardStatChip(
                  label: _adherenceLabel(
                    dailyTotals.calories / dailyMacroTargets.calories,
                    dailyTotals.protein / dailyMacroTargets.protein,
                  ),
                  icon: Icons.track_changes_outlined,
                  tone: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoalProgressRow(
                      label: l10n?.nutritionCalories ?? 'Calories',
                      valueLabel:
                          '${_formatDouble(dailyTotals.calories)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
                      targetLabel:
                          '${_formatDouble(dailyMacroTargets.calories)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
                      progress:
                          dailyTotals.calories / dailyMacroTargets.calories,
                      statusLabel:
                          '${_formatDouble((dailyMacroTargets.calories - dailyTotals.calories).clamp(0, dailyMacroTargets.calories))} left',
                      leading: const Icon(
                        Icons.local_fire_department_outlined,
                        color: AppTheme.calorieAccent,
                      ),
                      barColor: AppTheme.calorieAccent,
                    ),
                    const SizedBox(height: 16),
                    GoalProgressRow(
                      label: l10n?.nutritionProtein ?? 'Protein',
                      valueLabel:
                          '${_formatDouble(dailyTotals.protein)} ${l10n?.nutritionGramUnit ?? 'g'}',
                      targetLabel:
                          '${_formatDouble(dailyMacroTargets.protein)} ${l10n?.nutritionGramUnit ?? 'g'}',
                      progress: dailyTotals.protein / dailyMacroTargets.protein,
                      statusLabel:
                          '${_formatDouble((dailyMacroTargets.protein - dailyTotals.protein).clamp(0, dailyMacroTargets.protein))} left',
                      leading: const Icon(
                        Icons.egg_alt_outlined,
                        color: AppTheme.proteinAccent,
                      ),
                      barColor: AppTheme.proteinAccent,
                    ),
                  ],
                ),
              ),
              const AppPageSectionGap(),
              _TodayWorkoutPanel(
                recommendation: workoutRecommendation,
                onTap: _workoutCardAction(workoutRecommendation),
                formatDuration: _formatDuration,
                formatVolume: _formatVolume,
                sessionVolume: _sessionVolume,
                completedExercises: _completedExercises,
                exerciseLabel: _exerciseLabel,
              ),
            ],
          ),
        );
      },
    );
  }

  double _sessionVolume(WorkoutSession session) {
    var total = 0.0;
    for (final result in session.results) {
      for (final set in result.setLogs) {
        total += ((set.weightGrams ?? 0) / 1000) * (set.reps ?? 0);
      }
    }
    return total;
  }

  int _completedExercises(WorkoutSession session) {
    return session.results.where((result) => result.setLogs.isNotEmpty).length;
  }

  String _adherenceLabel(double caloriesRatio, double proteinRatio) {
    final score = ((caloriesRatio + proteinRatio) / 2).clamp(0.0, 1.0);
    if (score >= 0.95) {
      return 'On target';
    }
    if (score >= 0.65) {
      return 'In range';
    }
    return 'Behind';
  }

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatVolume(double volume) {
    if (volume <= 0) {
      return '0 kg';
    }
    return '${volume.toStringAsFixed(volume >= 1000 ? 0 : 1)} kg';
  }

  String _exerciseLabel(TrainingExercise exercise) {
    return widget.store.exerciseById(exercise.exerciseId)?.name ??
        exercise.exerciseId.replaceAll('-', ' ');
  }

  VoidCallback? _workoutCardAction(TodayWorkoutRecommendation? recommendation) {
    if (recommendation == null ||
        recommendation.status == TodayWorkoutStatus.completedToday) {
      return null;
    }
    if (recommendation.status == TodayWorkoutStatus.active) {
      return widget.onOpenActiveWorkout ?? widget.onOpenTrain;
    }
    return () => _confirmStartWorkout(recommendation.plan);
  }

  Future<void> _confirmStartWorkout(TrainingPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Start ${plan.name}?'),
          content: Text('Begin a new workout session for ${plan.name}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start workout'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final startWorkout = widget.onStartWorkout;
    if (startWorkout == null) {
      widget.onOpenTrain();
      return;
    }
    await startWorkout(plan);
  }
}

class _TodayWorkoutPanel extends StatelessWidget {
  const _TodayWorkoutPanel({
    required this.recommendation,
    required this.onTap,
    required this.formatDuration,
    required this.formatVolume,
    required this.sessionVolume,
    required this.completedExercises,
    required this.exerciseLabel,
  });

  final TodayWorkoutRecommendation? recommendation;
  final VoidCallback? onTap;
  final String Function(Duration duration) formatDuration;
  final String Function(double volume) formatVolume;
  final double Function(WorkoutSession session) sessionVolume;
  final int Function(WorkoutSession session) completedExercises;
  final String Function(TrainingExercise exercise) exerciseLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = recommendation?.status;
    final isActive = status == TodayWorkoutStatus.active;
    final isDoneToday = status == TodayWorkoutStatus.completedToday;
    final radius = AppTheme.standardSurfaceRadius(colorScheme.brightness);

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: DashboardPanel(
            title: recommendation?.plan.name ?? 'Workout',
            eyebrow: switch (status) {
              TodayWorkoutStatus.active => 'Active workout',
              TodayWorkoutStatus.completedToday => 'Today workout',
              TodayWorkoutStatus.notStarted => 'Today workout',
              null => 'Today workout',
            },
            emphasis: isActive
                ? DashboardPanelEmphasis.live
                : DashboardPanelEmphasis.defaultSurface,
            trailing: isActive
                ? DashboardStatChip(
                    label: formatDuration(recommendation!.session!.duration),
                    icon: Icons.timer_outlined,
                    tone: colorScheme.onSurfaceVariant,
                  )
                : isDoneToday
                ? DashboardStatChip(
                    label: 'Done today',
                    icon: Icons.check_circle_outline,
                    tone: colorScheme.secondary,
                  )
                : null,
            child: _TodayWorkoutContent(
              recommendation: recommendation,
              formatVolume: formatVolume,
              sessionVolume: sessionVolume,
              completedExercises: completedExercises,
              exerciseLabel: exerciseLabel,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayWorkoutContent extends StatelessWidget {
  const _TodayWorkoutContent({
    required this.recommendation,
    required this.formatVolume,
    required this.sessionVolume,
    required this.completedExercises,
    required this.exerciseLabel,
  });

  final TodayWorkoutRecommendation? recommendation;
  final String Function(double volume) formatVolume;
  final double Function(WorkoutSession session) sessionVolume;
  final int Function(WorkoutSession session) completedExercises;
  final String Function(TrainingExercise exercise) exerciseLabel;

  @override
  Widget build(BuildContext context) {
    final session = recommendation?.session;
    if (session != null) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          DashboardStatChip(
            label: 'Total volume ${formatVolume(sessionVolume(session))}',
            icon: Icons.bar_chart_outlined,
            tone: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          DashboardStatChip(
            label:
                '${completedExercises(session)}/${session.results.length} exercises',
            icon: Icons.check_circle_outline,
            tone: Theme.of(context).colorScheme.secondary,
          ),
        ],
      );
    }

    final plan = recommendation?.plan;
    if (plan == null) {
      return Text(
        'No training plan for today.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final previewExercises = plan.exercises.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DashboardStatChip(
              label: recommendation?.lastCompletedAt == null
                  ? 'No history yet'
                  : 'Last done ${formatWorkoutDate(recommendation!.lastCompletedAt!)}',
              icon: Icons.history_outlined,
              tone: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            for (final exercise in previewExercises)
              DashboardStatChip(
                label: exerciseLabel(exercise),
                icon: Icons.fitness_center_outlined,
                tone: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }
}
