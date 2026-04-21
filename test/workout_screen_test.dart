import 'package:fitapp/main.dart';
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

    await pumpWorkoutScreen(tester, store: store);
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
