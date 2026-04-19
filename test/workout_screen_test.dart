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

  Future<void> choosePlan(WidgetTester tester, String planName) async {
    await tester.tap(find.widgetWithText(ListTile, planName));
    await tester.pumpAndSettle();
  }

  Future<void> enterResultValue(
    WidgetTester tester,
    String exerciseName,
    String label,
    String value,
  ) async {
    final row = find.ancestor(
      of: find.text(exerciseName),
      matching: find.byType(Card),
    );
    final field = find.descendant(
      of: row.first,
      matching: find.bySemanticsLabel(label),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
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

  testWidgets('starts, edits, and finishes an active workout', (tester) async {
    final store = AppStore();
    await pumpWorkoutScreen(tester, store: store);

    await openStartWorkoutPicker(tester);
    await choosePlan(tester, 'Chest day');

    expect(find.text('Active workout'), findsOneWidget);
    expect(find.text('Chest day'), findsWidgets);
    expect(find.textContaining('Elapsed'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.textContaining('3 sets'), findsWidgets);
    expect(find.textContaining('8 reps'), findsWidgets);

    await enterResultValue(tester, 'Bench press', 'Actual weight', 'abc');
    expect(tester.takeException(), isNull);
    expect(store.activeWorkoutSession!.results.first.actualWeight, isNull);

    await enterResultValue(tester, 'Bench press', 'Actual sets', '3');
    await enterResultValue(tester, 'Bench press', 'Actual reps', '8');
    await enterResultValue(tester, 'Bench press', 'Actual weight', '65');
    await enterResultValue(tester, 'Bench press', 'Actual time', '0');
    await enterResultValue(tester, 'Bench press', 'Actual unit', 'kg');

    final firstResult = store.activeWorkoutSession!.results.first;
    expect(firstResult.actualSets, 3);
    expect(firstResult.actualReps, 8);
    expect(firstResult.actualWeight, 65);
    expect(firstResult.actualTime, 0);
    expect(firstResult.actualUnit, 'kg');

    await enterResultValue(tester, 'Bench press', 'Actual weight', '');
    expect(store.activeWorkoutSession!.results.first.actualWeight, isNull);

    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions, hasLength(1));
    expect(find.text('Active workout'), findsNothing);
    expect(find.text('Latest workout: Chest day'), findsOneWidget);
    expect(find.text('Completed sessions: 1'), findsOneWidget);
    expect(find.text('Chest day'), findsWidgets);
  });
}
