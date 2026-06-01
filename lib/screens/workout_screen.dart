import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/forms/form_error_messages.dart';
import '../ui/core/layout/adaptive_page.dart';
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
        final mediaQuery = MediaQuery.of(context);
        final stats = widget.store.workoutStats;
        final activeSession = widget.store.activeWorkoutSession;
        final completedSessions = widget.store.completedWorkoutSessions;
        final l10n = AppLocalizations.of(context);
        final hasActiveSession = activeSession != null;
        final textScale = mediaQuery.textScaler.scale(1);
        final textScaleClearance =
            (textScale > 1 ? textScale - 1 : 0).clamp(0.0, 1.0) * 24.0;
        final fabClearance = 56.0 + 16.0 + textScaleClearance;
        final fabLabel = hasActiveSession
            ? l10n?.workoutOpenActiveTooltip ?? 'Open active workout'
            : l10n?.todayStartWorkoutAction ?? 'Start workout';
        return Scaffold(
          appBar: AppBar(title: Text(l10n?.workoutTitle ?? 'Workout')),
          floatingActionButton: FloatingActionButton.extended(
            tooltip: fabLabel,
            onPressed: () => hasActiveSession
                ? _openActiveWorkout(context)
                : _openStartWorkoutPicker(context),
            icon: Icon(
              hasActiveSession
                  ? Icons.fitness_center_outlined
                  : Icons.play_arrow,
            ),
            label: Text(fabLabel),
          ),
          body: AdaptivePage(
            children: [
              if (activeSession != null)
                TooltipVisibility(
                  visible: false,
                  child: ActiveWorkoutCard(
                    session: activeSession,
                    l10n: l10n,
                    onOpen: () => _openActiveWorkout(context),
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n?.workoutStatsTitle ?? 'Workout stats',
                subtitle: stats.latestSession == null
                    ? l10n?.workoutNoCompletedSessionsSubtitle ??
                          'No completed sessions yet.'
                    : l10n?.workoutLatestSessionSubtitle(
                            stats.latestSession!.trainingPlanName,
                          ) ??
                          'Latest: ${stats.latestSession!.trainingPlanName}',
              ),
              WorkoutStatsGrid(
                completedCount: stats.completedCount,
                totalDuration: stats.totalDuration,
                latestSessionName: stats.latestSession?.trainingPlanName,
                l10n: l10n,
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: l10n?.workoutHistoryTitle ?? 'Workout history',
              ),
              if (completedSessions.isEmpty)
                AppEmptyState(
                  icon: Icons.history_toggle_off,
                  title:
                      l10n?.workoutEmptyHistoryTitle ??
                      'No completed workouts yet',
                  message:
                      l10n?.workoutEmptyHistoryMessage ??
                      'Start a training plan to build your workout history.',
                )
              else
                ...completedSessions.reversed.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WorkoutHistoryCard(
                      session: session,
                      l10n: l10n,
                      onOpen: () => _openCompletedWorkout(context, session),
                      onDelete: () =>
                          _confirmDeleteCompletedWorkout(context, session),
                    ),
                  ),
                ),
              SizedBox(height: fabClearance),
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
                  AppLocalizations.of(sheetContext)?.workoutChoosePlanTitle ??
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanReadableFormError(
              error,
              resourceName: 'workout',
              fallback: 'Could not start workout.',
            ),
          ),
        ),
      );
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
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n?.workoutDeleteDialogTitle ?? 'Delete workout?'),
          content: Text(
            l10n?.workoutDeleteDialogMessage(
                  session.trainingPlanName,
                  formatWorkoutDate(session.startedAt),
                ) ??
                'Delete ${session.trainingPlanName} from ${formatWorkoutDate(session.startedAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n?.commonCancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n?.commonDelete ?? 'Delete'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            humanReadableFormError(
              error,
              resourceName: 'workout',
              fallback: 'Could not delete workout.',
            ),
          ),
        ),
      );
    }
  }
}
