import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/workout_session.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/workout/workout_detail_cards.dart';

class CompletedWorkoutScreen extends StatelessWidget {
  const CompletedWorkoutScreen({
    super.key,
    required this.store,
    required this.session,
  });

  final AppStore store;
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final resultGroups = _groupResults(session.results);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.workoutCompletedTitle ?? 'Completed workout'),
      ),
      body: AdaptivePage(
        children: [
          WorkoutCompletedSummaryCard(session: session, l10n: l10n),
          const SizedBox(height: 24),
          SectionHeader(title: l10n?.workoutExercisesTitle ?? 'Exercises'),
          ...resultGroups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WorkoutCompletedExerciseResultGroupCard(
                exerciseName: group.exerciseName,
                results: group.results,
                store: store,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_WorkoutExerciseResultGroup> _groupResults(
    List<WorkoutExerciseResult> results,
  ) {
    final groups = <_WorkoutExerciseResultGroup>[];
    for (final result in results) {
      final existingIndex = groups.indexWhere(
        (group) => group.exerciseId == result.exerciseId,
      );
      if (existingIndex == -1) {
        groups.add(
          _WorkoutExerciseResultGroup(
            exerciseId: result.exerciseId,
            exerciseName: result.exerciseName,
            results: <WorkoutExerciseResult>[result],
          ),
        );
      } else {
        groups[existingIndex] = groups[existingIndex].copyWithResult(result);
      }
    }
    return groups;
  }
}

class _WorkoutExerciseResultGroup {
  const _WorkoutExerciseResultGroup({
    required this.exerciseId,
    required this.exerciseName,
    required this.results,
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutExerciseResult> results;

  _WorkoutExerciseResultGroup copyWithResult(WorkoutExerciseResult result) {
    return _WorkoutExerciseResultGroup(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      results: <WorkoutExerciseResult>[...results, result],
    );
  }
}
