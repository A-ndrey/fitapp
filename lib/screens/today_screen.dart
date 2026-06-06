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

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.store,
    required this.onOpenTrain,
    required this.onOpenNutrition,
    required this.onOpenLibrary,
  });

  final AppStore store;
  final VoidCallback onOpenTrain;
  final VoidCallback onOpenNutrition;
  final VoidCallback onOpenLibrary;

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
        final nextPlan = activeSession == null
            ? widget.store.trainingPlans.firstOrNull
            : widget.store.trainingPlanById(activeSession.trainingPlanId);

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
              DashboardPanel(
                title:
                    activeSession?.trainingPlanName ??
                    (nextPlan?.name ?? 'Workout'),
                eyebrow: activeSession == null
                    ? 'Today workout'
                    : 'Active workout',
                emphasis: activeSession == null
                    ? DashboardPanelEmphasis.defaultSurface
                    : DashboardPanelEmphasis.live,
                trailing: activeSession == null
                    ? null
                    : DashboardStatChip(
                        label: _formatDuration(activeSession.duration),
                        icon: Icons.timer_outlined,
                        tone: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                child: _TodayWorkoutContent(
                  plan: nextPlan,
                  activeSession: activeSession,
                  formatVolume: _formatVolume,
                  sessionVolume: _sessionVolume,
                  completedExercises: _completedExercises,
                ),
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
}

class _TodayWorkoutContent extends StatelessWidget {
  const _TodayWorkoutContent({
    required this.plan,
    required this.activeSession,
    required this.formatVolume,
    required this.sessionVolume,
    required this.completedExercises,
  });

  final TrainingPlan? plan;
  final WorkoutSession? activeSession;
  final String Function(double volume) formatVolume;
  final double Function(WorkoutSession session) sessionVolume;
  final int Function(WorkoutSession session) completedExercises;

  @override
  Widget build(BuildContext context) {
    final session = activeSession;
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

    if (plan == null) {
      return Text(
        'No training plan for today.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final previewExercises = plan!.exercises.take(3).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final exercise in previewExercises)
              DashboardStatChip(
                label: exercise.exerciseId.replaceAll('-', ' '),
                icon: Icons.fitness_center_outlined,
                tone: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ],
    );
  }
}
