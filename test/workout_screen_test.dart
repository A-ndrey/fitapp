import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/screens/workout_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWorkoutScreen(WidgetTester tester, {AppStore? store}) async {
    await tester.pumpWidget(
      MaterialApp(home: WorkoutScreen(store: store ?? AppStore())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openStartWorkoutPicker(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Start workout'));
    await tester.pumpAndSettle();
  }

  Future<void> openActiveWorkout(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open active workout'));
    await tester.pumpAndSettle();
  }

  Future<void> openExercise(WidgetTester tester, String exerciseName) async {
    await tester.tap(find.byTooltip('Open $exerciseName'));
    await tester.pumpAndSettle();
  }

  Future<void> enterWorkoutSet(
    WidgetTester tester, {
    required String reps,
    required String weight,
    required String time,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Reps'), reps);
    await tester.enterText(find.bySemanticsLabel('Weight'), weight);
    await tester.enterText(find.bySemanticsLabel('Time'), time);
    await tester.pumpAndSettle();
  }

  void finishChestWorkoutWithBenchSet(
    AppStore store, {
    required DateTime startedAt,
    required DateTime finishedAt,
    double reps = 8,
    double weight = 62.5,
  }) {
    store.startWorkout(trainingPlanId: 'chest-day', startedAt: startedAt);
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: WorkoutSetLog(reps: reps, weight: weight),
    );
    store.finishActiveWorkout(finishedAt: finishedAt);
  }

  void createRepeatPushupsPlan(AppStore store) {
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'repeat-pushups',
        name: 'Repeat pushups',
        description: 'Same exercise twice',
        exercises: [
          TrainingExercise(exerciseId: 'pushups', reps: 10, unit: 'reps'),
          TrainingExercise(exerciseId: 'pushups', reps: 8, unit: 'reps'),
        ],
      ),
    );
  }

  void finishRepeatPushupsWorkout(AppStore store) {
    store.startWorkout(
      trainingPlanId: 'repeat-pushups',
      startedAt: DateTime(2026, 4, 18, 9),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 10),
    );
    store.addActiveWorkoutSet(
      resultIndex: 1,
      setLog: const WorkoutSetLog(reps: 8),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 18, 9, 30));
  }

  testWidgets('shows workout stats and opens the plan picker', (tester) async {
    await pumpWorkoutScreen(tester);

    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Completed sessions: 0'), findsOneWidget);
    expect(find.text('Total workout time: 0 min'), findsOneWidget);
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('No completed workouts yet'), findsOneWidget);

    await openStartWorkoutPicker(tester);

    expect(find.text('Start workout'), findsWidgets);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Leg day'), findsOneWidget);
  });

  testWidgets('opens workout session immediately after starting a workout', (
    tester,
  ) async {
    final store = AppStore();
    await pumpWorkoutScreen(tester, store: store);

    await openStartWorkoutPicker(tester);
    await tester.tap(find.text('Chest day'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession?.trainingPlanName, 'Chest day');
    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });

  testWidgets('active session card opens the workout session screen', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);

    expect(find.text('Active workout'), findsOneWidget);
    expect(find.text('Workout session'), findsNothing);

    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });

  testWidgets('exercise rows open the workout exercise screen', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    expect(find.text('Workout exercise'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
  });

  testWidgets('logging a set clears fields and shows the logged set', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    await enterWorkoutSet(tester, reps: '8', weight: '65', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.textContaining('8'), findsWidgets);
    expect(find.textContaining('65'), findsWidgets);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    final repsField = fields[0];
    final weightField = fields[1];
    final timeField = fields[2];

    expect(repsField.controller?.text, isEmpty);
    expect(weightField.controller?.text, isEmpty);
    expect(timeField.controller?.text, isEmpty);

    await tester.tap(find.byTooltip('Use Set 1'));
    await tester.pumpAndSettle();

    expect(repsField.controller?.text, '8');
    expect(weightField.controller?.text, '65');
    expect(timeField.controller?.text, isEmpty);
  });

  testWidgets('multiple set logs accumulate', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    await enterWorkoutSet(tester, reps: '8', weight: '65', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    await enterWorkoutSet(tester, reps: '6', weight: '67.5', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(2));
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Set 2'), findsOneWidget);
  });

  testWidgets('workout displays render pounds when weight unit is pounds', (
    tester,
  ) async {
    final store = AppStore();
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);

    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);

    await openExercise(tester, 'Bench press');
    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);

    await enterWorkoutSet(tester, reps: '8', weight: '62.5', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(find.text('8 reps • 137.8 lbs'), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[1].controller?.text, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open completed Chest day'));
    await tester.pumpAndSettle();

    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);
    expect(find.text('8 reps • 137.8 lbs'), findsOneWidget);
  });

  testWidgets('finishing from session screen returns to workout overview', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);

    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession, isNull);
    expect(find.text('Workout session'), findsNothing);
    expect(find.text('Active workout'), findsNothing);
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Completed sessions: 1'), findsOneWidget);
    expect(find.text('Latest workout: Chest day'), findsOneWidget);
  });

  testWidgets('finishes active session after switching tabs', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('Active workout'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Active workout'), findsNothing);

    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();
    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);

    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions, hasLength(1));
    expect(find.text('Workout session'), findsNothing);
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Completed sessions: 1'), findsOneWidget);
  });

  testWidgets(
    'history card opens completed workout details under workout tab',
    (tester) async {
      final store = AppStore();
      finishChestWorkoutWithBenchSet(
        store,
        startedAt: DateTime(2026, 4, 18, 9),
        finishedAt: DateTime(2026, 4, 18, 9, 45),
      );

      await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open completed Chest day'));
      await tester.pumpAndSettle();

      expect(find.text('Completed workout'), findsOneWidget);
      expect(find.text('Chest day'), findsOneWidget);
      expect(find.text('Date: 2026-04-18'), findsOneWidget);
      expect(find.text('Duration: 45 min'), findsOneWidget);
      expect(find.textContaining('Started:'), findsNothing);
      expect(find.textContaining('Finished:'), findsNothing);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('8 reps • 62.5 kg'), findsOneWidget);
      expect(find.text('Workout'), findsWidgets);
      expect(find.text('Trainings'), findsWidgets);
    },
  );

  testWidgets('workout history shows started date and can delete records', (
    tester,
  ) async {
    final store = AppStore();
    finishChestWorkoutWithBenchSet(
      store,
      startedAt: DateTime(2026, 4, 18, 9),
      finishedAt: DateTime(2026, 4, 18, 9, 45),
    );

    await pumpWorkoutScreen(tester, store: store);

    expect(find.text('Date: 2026-04-18'), findsOneWidget);
    expect(find.text('Completed • 45 min'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete completed Chest day'));
    await tester.pumpAndSettle();

    expect(find.text('Delete workout?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.completedWorkoutSessions, isEmpty);
    expect(find.text('No completed workouts yet'), findsOneWidget);
    expect(find.text('Date: 2026-04-18'), findsNothing);
  });

  testWidgets('completed workout details group repeated exercises', (
    tester,
  ) async {
    final store = AppStore.empty();
    createRepeatPushupsPlan(store);
    finishRepeatPushupsWorkout(store);

    await pumpWorkoutScreen(tester, store: store);

    await tester.tap(find.byTooltip('Open completed Repeat pushups'));
    await tester.pumpAndSettle();

    expect(find.text('Completed workout'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.text('Entry 2'), findsOneWidget);
    expect(find.text('10 reps'), findsWidgets);
    expect(find.text('8 reps'), findsWidgets);
  });

  testWidgets('previous exercise results refill active set form', (
    tester,
  ) async {
    final store = AppStore();
    finishChestWorkoutWithBenchSet(
      store,
      startedAt: DateTime(2026, 4, 18, 9),
      finishedAt: DateTime(2026, 4, 18, 9, 45),
    );
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    expect(find.text('Previous results'), findsOneWidget);
    expect(find.text('Chest day • 2026-04-18 • 45 min'), findsOneWidget);
    expect(find.text('8 reps • 62.5 kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Use previous Set 1 from Chest day'));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '8');
    expect(fields[1].controller?.text, '62.5');
    expect(fields[2].controller?.text, isEmpty);

    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs,
      hasLength(1),
    );
  });

  testWidgets('previous repeated exercise results use distinct refill rows', (
    tester,
  ) async {
    final store = AppStore.empty();
    createRepeatPushupsPlan(store);
    finishRepeatPushupsWorkout(store);
    store.startWorkout(
      trainingPlanId: 'repeat-pushups',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    expect(find.text('Pushups (1)'), findsOneWidget);
    expect(find.text('Pushups (2)'), findsOneWidget);
    expect(find.byTooltip('Open Pushups entry 1'), findsOneWidget);
    expect(find.byTooltip('Open Pushups entry 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Pushups entry 1'));
    await tester.pumpAndSettle();

    expect(find.text('Entry 1 • Set 1'), findsOneWidget);
    expect(find.text('Entry 2 • Set 1'), findsOneWidget);

    final secondPreviousSet = find.byTooltip(
      'Use previous Entry 2 Set 1 from Repeat pushups',
    );
    await tester.ensureVisible(secondPreviousSet);
    await tester.pumpAndSettle();
    await tester.tap(secondPreviousSet);
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '8');
    expect(fields[1].controller?.text, isEmpty);
    expect(fields[2].controller?.text, isEmpty);
  });

  testWidgets('keeps workout tab visible on session and exercise screens', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();

    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Trainings'), findsWidgets);
    expect(find.text('Meal'), findsWidgets);
    expect(find.text('Food'), findsWidgets);

    await openExercise(tester, 'Bench press');

    expect(find.text('Workout exercise'), findsOneWidget);
    expect(find.text('Workout'), findsWidgets);
    expect(find.text('Trainings'), findsWidgets);

    await tester.tap(find.byIcon(Icons.fitness_center_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Training plans'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Workout exercise'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
  });
}
