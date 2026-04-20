import 'dart:async';

import 'package:flutter/material.dart';

import '../models/training_plan.dart';
import '../state/app_store.dart';
import 'workout_session_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.store,
    this.isCurrentTab = true,
  });

  final AppStore store;
  final bool isCurrentTab;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncTimer);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store) {
      if (oldWidget.isCurrentTab != widget.isCurrentTab) {
        _syncTimer();
      }
    } else {
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
    final hasActiveSession =
        widget.isCurrentTab && widget.store.activeWorkoutSession != null;
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
        return Scaffold(
          appBar: AppBar(title: const Text('Workout')),
          floatingActionButton: activeSession == null
              ? FloatingActionButton.extended(
                  tooltip: 'Start workout',
                  onPressed: () => _openStartWorkoutPicker(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start workout'),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeSession != null) ...[
                  Text(
                    'Active workout',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: 'Open active workout',
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _openActiveWorkout(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeSession.trainingPlanName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Elapsed time: ${_formatDuration(activeSession.duration)}',
                              ),
                              const SizedBox(height: 4),
                              Text('${activeSession.results.length} exercises'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Workout stats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('Completed sessions: ${stats.completedCount}'),
                const SizedBox(height: 4),
                Text(
                  'Total workout time: ${_formatDuration(stats.totalDuration)}',
                ),
                if (stats.latestSession != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Latest workout: ${stats.latestSession!.trainingPlanName}',
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Workout history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (widget.store.completedWorkoutSessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No completed workouts yet'),
                  )
                else
                  ...widget.store.completedWorkoutSessions.reversed.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(session.trainingPlanName),
                          subtitle: Text(
                            'Completed • ${_formatDuration(session.duration)}',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
    }
  }

  Future<void> _openActiveWorkout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkoutSessionScreen(store: widget.store),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0 ? '$hours h' : '$hours h $minutes min';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    }
    return '0 min';
  }
}
