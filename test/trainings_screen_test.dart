import 'package:fitapp/screens/trainings_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {AppStore? store}) async {
    await tester.pumpWidget(
      MaterialApp(home: TrainingsScreen(store: store ?? AppStore())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterLabeledText(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final finder = find.bySemanticsLabel(label);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: scrollable ?? find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openExercisesView(WidgetTester tester) async {
    await tester.tap(find.text('Exercises').first);
    await tester.pumpAndSettle();
  }

  Future<void> openExerciseForm(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Add exercise'));
    await tester.pumpAndSettle();
  }

  Future<void> openPlanView(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 5000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans').first);
    await tester.pumpAndSettle();
  }

  Future<void> fillExerciseForm(
    WidgetTester tester, {
    required String name,
    required String description,
    required String instruction,
    required String muscleGroups,
  }) async {
    await enterLabeledText(tester, 'Exercise name', name);
    await enterLabeledText(tester, 'Exercise description', description);
    await enterLabeledText(tester, 'Exercise instruction', instruction);
    await enterLabeledText(tester, 'Muscle groups', muscleGroups);
  }

  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    final finder = find.byTooltip(tooltip);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lists sample training plans and exposes row actions', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Leg day'), findsOneWidget);
    expect(find.byTooltip('Add training plan'), findsOneWidget);
    expect(find.byTooltip('Edit Chest day'), findsOneWidget);
    expect(find.byTooltip('Delete Chest day'), findsOneWidget);
  });

  testWidgets('creates a training plan from predefined exercises', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Training name', 'Push day');
    await enterLabeledText(
      tester,
      'Training description',
      'Bodyweight and pressing work',
    );

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Pushups'), findsWidgets);
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Expected sets', '4');
    await enterLabeledText(tester, 'Expected reps', '12');
    await enterLabeledText(tester, 'Expected weight', '0');
    await enterLabeledText(tester, 'Expected time', '0');
    await enterLabeledText(tester, 'Unit', 'reps');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('4 sets'), findsOneWidget);

    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('keeps invalid training plan form open and can edit/delete', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Training name'), findsOneWidget);

    await enterLabeledText(tester, 'Training name', 'Push day');
    await enterLabeledText(tester, 'Training description', 'Upper body');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Expected sets', '3');
    await enterLabeledText(tester, 'Expected reps', '10');
    await enterLabeledText(tester, 'Expected weight', '0');
    await enterLabeledText(tester, 'Expected time', '0');
    await enterLabeledText(tester, 'Unit', 'reps');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit Push day'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Training name', 'Push day updated');
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day updated'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Push day updated'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Push day updated'), findsNothing);
  });

  testWidgets('switches to exercises view and exposes exercise actions', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);

    expect(
      find.byWidgetPredicate((widget) => widget is SegmentedButton),
      findsOneWidget,
    );
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.byTooltip('Add exercise'), findsOneWidget);
    expect(find.byTooltip('Edit Pushups'), findsOneWidget);
    expect(find.byTooltip('Delete Pushups'), findsOneWidget);
  });

  testWidgets('creates a custom exercise and shows it in the plan picker', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom burpee',
      description: 'Full-body conditioning',
      instruction: 'Drop, jump back, return, and stand tall.',
      muscleGroups: 'Full body, Cardio',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.text('Custom burpee'));
    expect(find.text('Custom burpee'), findsOneWidget);
    expect(find.text('Full body, Cardio'), findsOneWidget);

    await openPlanView(tester);
    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(
      tester,
      find.text('Custom burpee'),
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Custom burpee'), findsOneWidget);
  });

  testWidgets('keeps exercise form open when name cannot create an id', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: '---',
      description: 'Invalid generated id',
      instruction: 'This should stay open.',
      muscleGroups: 'Core',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter a valid exercise name.'), findsOneWidget);
  });

  testWidgets('edits a custom exercise', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom plank',
      description: 'Static core hold',
      instruction: 'Brace and hold a straight line.',
      muscleGroups: 'Core',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.byTooltip('Edit Custom plank'));
    await tapTooltip(tester, 'Edit Custom plank');
    await fillExerciseForm(
      tester,
      name: 'Custom plank',
      description: 'Updated core hold',
      instruction: 'Keep ribs down and hips level.',
      muscleGroups: 'Core, Glutes',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Updated core hold'), findsOneWidget);
    expect(find.text('Core, Glutes'), findsOneWidget);
  });

  testWidgets('deletes an unused custom exercise', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom bridge',
      description: 'Posterior chain work',
      instruction: 'Drive hips up and squeeze glutes.',
      muscleGroups: 'Glutes, Hamstrings',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.byTooltip('Delete Custom bridge'));
    await tapTooltip(tester, 'Delete Custom bridge');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Custom bridge'), findsNothing);
  });

  testWidgets('blocks deleting a sample exercise used by a plan', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await tapTooltip(tester, 'Delete Pushups');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise is used by a training plan.'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });
}
