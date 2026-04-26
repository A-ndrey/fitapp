import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/action_card.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_formatters.dart';
import '../ui/workout/workout_overview_cards.dart';
import 'completed_workout_screen.dart';
import 'workout_session_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.store,
    this.isCurrentTab = true,
    this.isCurrentTabListenable,
  });

  final AppStore store;
  final bool isCurrentTab;
  final ValueListenable<bool>? isCurrentTabListenable;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;
  bool get _isCurrentTab =>
      widget.isCurrentTabListenable?.value ?? widget.isCurrentTab;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    widget.isCurrentTabListenable?.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_syncTimer);
      widget.store.addListener(_syncTimer);
    }
    if (oldWidget.isCurrentTabListenable != widget.isCurrentTabListenable) {
      oldWidget.isCurrentTabListenable?.removeListener(_syncTimer);
      widget.isCurrentTabListenable?.addListener(_syncTimer);
    }
    if (oldWidget.isCurrentTab != widget.isCurrentTab ||
        oldWidget.store != widget.store ||
        oldWidget.isCurrentTabListenable != widget.isCurrentTabListenable) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncTimer);
    widget.isCurrentTabListenable?.removeListener(_syncTimer);
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final hasActiveSession =
        _isCurrentTab && widget.store.activeWorkoutSession != null;
    if (!hasActiveSession) {
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
        final stats = widget.store.workoutStats;
        final activeSession = widget.store.activeWorkoutSession;
        final completedSessions = widget.store.completedWorkoutSessions;
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          floatingActionButton: null,
          body: AdaptivePage(
            children: [
              const SectionHeader(
                title: 'Training cockpit',
                subtitle: 'Start, resume, and review workout sessions.',
              ),
              if (activeSession != null)
                ActiveWorkoutCard(
                  session: activeSession,
                  onOpen: () => _openActiveWorkout(context),
                )
              else
                ActionCard(
                  title: 'Start workout',
                  subtitle: 'Choose a training plan and begin tracking sets.',
                  icon: Icons.play_arrow,
                  tooltip: 'Start workout',
                  onTap: () => _openStartWorkoutPicker(context),
                ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Workout stats',
                subtitle: stats.latestSession == null
                    ? 'No completed sessions yet.'
                    : 'Latest: ${stats.latestSession!.trainingPlanName}',
              ),
              WorkoutStatsGrid(
                completedCount: stats.completedCount,
                totalDuration: stats.totalDuration,
                latestSessionName: stats.latestSession?.trainingPlanName,
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Workout history'),
              if (completedSessions.isEmpty)
                AppEmptyState(
                  icon: Icons.history_toggle_off,
                  title: 'No completed workouts yet',
                  message:
                      'Start a training plan to build your workout history.',
                )
              else
                ...completedSessions.reversed.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WorkoutHistoryCard(
                      session: session,
                      onOpen: () => _openCompletedWorkout(context, session),
                      onDelete: () =>
                          _confirmDeleteCompletedWorkout(context, session),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStartWorkoutPicker(BuildContext context) async {
    final plan = await showModalBottomSheet<TrainingPlan>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose a training plan',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.store.trainingPlans.map(
                (trainingPlan) => ListTile(
                  leading: const Icon(Icons.playlist_add_check_outlined),
                  title: Text(trainingPlan.name),
                  subtitle: Text(trainingPlan.description),
                  onTap: () => Navigator.of(sheetContext).pop(trainingPlan),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!context.mounted || plan == null) {
      return;
    }
    try {
      widget.store.startWorkout(trainingPlanId: plan.id);
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (context.mounted) {
      await _openActiveWorkout(context);
    }
  }

  Future<void> _openActiveWorkout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkoutSessionScreen(
          store: widget.store,
          isCurrentTab: widget.isCurrentTab,
          isCurrentTabListenable: widget.isCurrentTabListenable,
        ),
      ),
    );
  }

  Future<void> _openCompletedWorkout(
    BuildContext context,
    WorkoutSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            CompletedWorkoutScreen(store: widget.store, session: session),
      ),
    );
  }

  Future<void> _confirmDeleteCompletedWorkout(
    BuildContext context,
    WorkoutSession session,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete workout?'),
          content: Text(
            'Delete ${session.trainingPlanName} from ${formatWorkoutDate(session.startedAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || shouldDelete != true) {
      return;
    }
    try {
      widget.store.deleteCompletedWorkoutSession(session.id);
    } on Object catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
