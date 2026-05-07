import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/layout/responsive_layout.dart';
import '../ui/core/theme/app_theme.dart';
import '../ui/core/widgets/action_card.dart';
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
  static const _calorieGoal = 3200.0;
  static const _proteinGoal = 220.0;

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
        final nextPlan = activeSession == null
            ? widget.store.trainingPlans.firstOrNull
            : widget.store.trainingPlanById(activeSession.trainingPlanId);
        final performanceInsight = _buildPerformanceInsight(
          context,
          l10n,
          activeSession,
        );

        return Scaffold(
          appBar: AppBar(title: Text(l10n?.destinationToday ?? 'Today')),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: activeSession == null
                    ? 'Daily progress'
                    : 'Active workout',
                subtitle: activeSession == null
                    ? 'Track macros, stay on plan, and move straight into training.'
                    : 'Stay on pace with the current session and keep your next actions obvious.',
              ),
              DashboardPanel(
                title: activeSession?.trainingPlanName ?? 'Daily progress',
                eyebrow: activeSession == null ? 'Fuel' : 'Live session',
                subtitle: activeSession == null
                    ? 'Calories and protein stay front and center because they drive the day.'
                    : 'Chest day',
                emphasis: activeSession == null
                    ? DashboardPanelEmphasis.raisedSurface
                    : DashboardPanelEmphasis.live,
                trailing: activeSession == null
                    ? DashboardStatChip(
                        label: _adherenceLabel(
                          dailyTotals.calories / _calorieGoal,
                          dailyTotals.protein / _proteinGoal,
                        ),
                        icon: Icons.track_changes_outlined,
                        tone: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : DashboardStatChip(
                        label: _formatDuration(activeSession.duration),
                        icon: Icons.timer_outlined,
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
                          '${_formatDouble(_calorieGoal)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
                      progress: dailyTotals.calories / _calorieGoal,
                      statusLabel:
                          '${_formatDouble((_calorieGoal - dailyTotals.calories).clamp(0, _calorieGoal))} left',
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
                          '${_formatDouble(_proteinGoal)} ${l10n?.nutritionGramUnit ?? 'g'}',
                      progress: dailyTotals.protein / _proteinGoal,
                      statusLabel:
                          '${_formatDouble((_proteinGoal - dailyTotals.protein).clamp(0, _proteinGoal))} left',
                      leading: const Icon(
                        Icons.egg_alt_outlined,
                        color: AppTheme.proteinAccent,
                      ),
                      barColor: AppTheme.proteinAccent,
                    ),
                    if (activeSession != null) ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          DashboardStatChip(
                            label:
                                'Total volume ${_formatVolume(_sessionVolume(activeSession))}',
                            icon: Icons.bar_chart_outlined,
                            tone: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          DashboardStatChip(
                            label:
                                '${_completedExercises(activeSession)}/${activeSession.results.length} exercises',
                            icon: Icons.check_circle_outline,
                            tone: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ResponsiveWrap(
                maxItemExtent: 420,
                minItemExtent: 300,
                spacing: 16,
                children: [
                  DashboardPanel(
                    title: nextPlan?.name ?? 'Next workout',
                    eyebrow: 'Next workout',
                    subtitle: nextPlan == null
                        ? 'Create a training plan to keep the split moving.'
                        : nextPlan.description,
                    child: _NextWorkoutContent(
                      plan: nextPlan,
                      onOpenTrain: widget.onOpenTrain,
                    ),
                  ),
                  DashboardPanel(
                    title: performanceInsight.title,
                    eyebrow: 'Performance insight',
                    subtitle: performanceInsight.subtitle,
                    child: performanceInsight.content,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n?.todayQuickActionsTitle ?? 'Quick actions',
              ),
              ResponsiveWrap(
                maxItemExtent: 360,
                minItemExtent: 300,
                spacing: 12,
                children: [
                  ActionCard(
                    title: activeSession == null
                        ? l10n?.todayStartWorkoutAction ?? 'Start workout'
                        : l10n?.todayOpenWorkoutAction ?? 'Open workout',
                    subtitle: activeSession == null
                        ? 'Jump into the next plan without leaving today.'
                        : 'Return to the live session and continue logging.',
                    semanticHint: l10n?.todayOpenTrainHint ?? 'Opens Train tab',
                    icon: activeSession == null
                        ? Icons.play_arrow_rounded
                        : Icons.open_in_new,
                    onTap: widget.onOpenTrain,
                  ),
                  ActionCard(
                    title: l10n?.todayLogMealAction ?? 'Log meal',
                    subtitle:
                        'Add food fast and close the remaining macro gap.',
                    semanticHint:
                        l10n?.todayOpenNutritionHint ?? 'Opens Nutrition tab',
                    icon: Icons.restaurant,
                    onTap: widget.onOpenNutrition,
                  ),
                  ActionCard(
                    title: l10n?.todayManageLibraryAction ?? 'Manage library',
                    subtitle:
                        'Update foods, plans, and exercises without breaking flow.',
                    semanticHint:
                        l10n?.todayOpenLibraryHint ?? 'Opens Library tab',
                    icon: Icons.inventory_2_outlined,
                    onTap: widget.onOpenLibrary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  _PerformanceInsight _buildPerformanceInsight(
    BuildContext context,
    AppLocalizations? l10n,
    WorkoutSession? activeSession,
  ) {
    final latest = widget.store.workoutStats.latestSession;
    if (activeSession != null) {
      final currentExercise = activeSession.results.firstWhere(
        (result) => result.setLogs.length < (result.target.sets?.toInt() ?? 1),
        orElse: () => activeSession.results.first,
      );
      final suggestion = currentExercise.target.weight == null
          ? 'Match the target reps before adding load.'
          : 'If bar speed is solid, try +2.5 kg on the final work set.';
      return _PerformanceInsight(
        title: currentExercise.exerciseName,
        subtitle: 'Keep the quality sets moving and protect progression.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total volume', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              _formatVolume(_sessionVolume(activeSession)),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(suggestion, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (latest != null) {
      return _PerformanceInsight(
        title: latest.trainingPlanName,
        subtitle: 'Recent work gives you the best signal for the next session.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DashboardStatChip(
                  label: '${latest.results.length} exercises',
                  icon: Icons.fitness_center_outlined,
                  tone: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                DashboardStatChip(
                  label: _formatVolume(_sessionVolume(latest)),
                  icon: Icons.bar_chart_outlined,
                  tone: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Latest completed session is ready to use as your progression baseline.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return _PerformanceInsight(
      title: 'Build your first baseline',
      subtitle: 'The app becomes more useful once it can compare recent work.',
      content: Text(
        'Complete one workout and the dashboard will start surfacing volume and progression cues here.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  double _sessionVolume(WorkoutSession session) {
    var total = 0.0;
    for (final result in session.results) {
      for (final set in result.setLogs) {
        total += (set.weight ?? 0) * (set.reps ?? 0);
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

class _NextWorkoutContent extends StatelessWidget {
  const _NextWorkoutContent({required this.plan, required this.onOpenTrain});

  final TrainingPlan? plan;
  final VoidCallback onOpenTrain;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return FilledButton.icon(
        onPressed: onOpenTrain,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Create training plan'),
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
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onOpenTrain,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open train tab'),
        ),
      ],
    );
  }
}

class _PerformanceInsight {
  const _PerformanceInsight({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final Widget content;
}
