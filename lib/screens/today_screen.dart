import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/theme/app_theme.dart';
import '../ui/core/widgets/action_card.dart';
import '../ui/core/widgets/metric_card.dart';
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
        final activeSession = widget.store.activeWorkoutSession;
        final dailyTotals = widget.store.dailyTotals;
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(title: Text(l10n?.destinationToday ?? 'Today')),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: activeSession == null
                    ? l10n?.todayReadyState ?? 'Ready state'
                    : l10n?.todayInSession ?? 'In session',
              ),
              _MetricGrid(
                children: [
                  if (activeSession == null)
                    MetricCard(
                      label:
                          l10n?.todayCompletedWorkouts ?? 'Completed workouts',
                      value: widget.store.workoutStats.completedCount
                          .toString(),
                      suffix: l10n?.todaySessionsSuffix ?? 'sessions',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.recoveryBlue,
                    )
                  else
                    MetricCard(
                      label: activeSession.trainingPlanName,
                      value: _formatDuration(activeSession.duration),
                      semanticValue: _formatDurationSemantic(
                        activeSession.duration,
                        l10n,
                      ),
                      suffix: l10n?.todayElapsedSuffix ?? 'elapsed',
                      icon: Icons.timer_outlined,
                      color: AppTheme.energyOrange,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: l10n?.todayDailyFuelTitle ?? 'Daily fuel',
                subtitle: l10n?.todayDailyFuelSubtitle ?? 'Macros logged today',
              ),
              _MetricGrid(
                children: [
                  MetricCard(
                    label: l10n?.nutritionCalories ?? 'Calories',
                    value: _formatDouble(dailyTotals.calories),
                    suffix: 'kcal',
                    semanticSuffix:
                        l10n?.nutritionKilocaloriesSemantic ?? 'kilocalories',
                    icon: Icons.local_fire_department_outlined,
                    color: AppTheme.energyOrange,
                  ),
                  MetricCard(
                    label: l10n?.nutritionProtein ?? 'Protein',
                    value: _formatDouble(dailyTotals.protein),
                    suffix: 'g',
                    semanticSuffix: l10n?.nutritionGramsSemantic ?? 'grams',
                    icon: Icons.egg_alt_outlined,
                    color: AppTheme.pulseLime,
                  ),
                  MetricCard(
                    label: l10n?.nutritionCarbs ?? 'Carbs',
                    value: _formatDouble(dailyTotals.carbs),
                    suffix: 'g',
                    semanticSuffix: l10n?.nutritionGramsSemantic ?? 'grams',
                    icon: Icons.grain_outlined,
                    color: AppTheme.recoveryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: l10n?.todayQuickActionsTitle ?? 'Quick actions',
              ),
              ActionCard(
                title: activeSession == null
                    ? l10n?.todayStartWorkoutAction ?? 'Start workout'
                    : l10n?.todayOpenWorkoutAction ?? 'Open workout',
                subtitle: activeSession == null
                    ? l10n?.todayStartWorkoutSubtitle ??
                          'Choose a plan and begin training'
                    : l10n?.todayOpenWorkoutSubtitle ??
                          'Return to the active session',
                semanticHint: l10n?.todayOpenTrainHint ?? 'Opens Train tab',
                icon: activeSession == null
                    ? Icons.play_arrow
                    : Icons.open_in_new,
                onTap: widget.onOpenTrain,
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: l10n?.todayLogMealAction ?? 'Log meal',
                subtitle:
                    l10n?.todayLogMealSubtitle ??
                    'Add calories and macros for today',
                semanticHint:
                    l10n?.todayOpenNutritionHint ?? 'Opens Nutrition tab',
                icon: Icons.restaurant,
                onTap: widget.onOpenNutrition,
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: l10n?.todayManageLibraryAction ?? 'Manage library',
                subtitle:
                    l10n?.todayManageLibrarySubtitle ??
                    'Update foods, dishes, exercises, and plans',
                semanticHint: l10n?.todayOpenLibraryHint ?? 'Opens Library tab',
                icon: Icons.inventory_2_outlined,
                onTap: widget.onOpenLibrary,
              ),
            ],
          ),
        );
      },
    );
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

  String _formatDurationSemantic(Duration duration, AppLocalizations? l10n) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return l10n?.durationHoursMinutesSemantic(hours, minutes) ??
          _formatDuration(duration);
    }
    if (minutes > 0) {
      return l10n?.durationMinutesSecondsSemantic(minutes, seconds) ??
          _formatDuration(duration);
    }
    return l10n?.durationSecondsSemantic(seconds) ?? _formatDuration(duration);
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 720 => 3,
          >= 560 => 2,
          _ => 1,
        };
        final spacing = columns == 1 ? 12.0 : 16.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
