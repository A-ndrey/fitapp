import 'dart:async';

import 'package:flutter/material.dart';

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

        return Scaffold(
          appBar: AppBar(title: const Text('Today')),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: activeSession == null ? 'Ready state' : 'In session',
              ),
              _MetricGrid(
                children: [
                  if (activeSession == null)
                    MetricCard(
                      label: 'Completed workouts',
                      value: widget.store.workoutStats.completedCount
                          .toString(),
                      suffix: 'sessions',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.recoveryBlue,
                    )
                  else
                    MetricCard(
                      label: activeSession.trainingPlanName,
                      value: _formatDuration(activeSession.duration),
                      suffix: 'elapsed',
                      icon: Icons.timer_outlined,
                      color: AppTheme.energyOrange,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Daily fuel',
                subtitle: 'Macros logged today',
              ),
              _MetricGrid(
                children: [
                  MetricCard(
                    label: 'Calories',
                    value: _formatDouble(dailyTotals.calories),
                    suffix: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    color: AppTheme.energyOrange,
                  ),
                  MetricCard(
                    label: 'Protein',
                    value: _formatDouble(dailyTotals.protein),
                    suffix: 'g',
                    icon: Icons.egg_alt_outlined,
                    color: AppTheme.pulseLime,
                  ),
                  MetricCard(
                    label: 'Carbs',
                    value: _formatDouble(dailyTotals.carbs),
                    suffix: 'g',
                    icon: Icons.grain_outlined,
                    color: AppTheme.recoveryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Quick actions'),
              ActionCard(
                title: activeSession == null ? 'Start workout' : 'Open workout',
                subtitle: activeSession == null
                    ? 'Choose a plan and begin training'
                    : 'Return to the active session',
                icon: activeSession == null
                    ? Icons.play_arrow
                    : Icons.open_in_new,
                onTap: widget.onOpenTrain,
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: 'Log meal',
                subtitle: 'Add calories and macros for today',
                icon: Icons.restaurant,
                onTap: widget.onOpenNutrition,
              ),
              const SizedBox(height: 12),
              ActionCard(
                title: 'Manage library',
                subtitle: 'Update foods, dishes, exercises, and plans',
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
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 1;
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
