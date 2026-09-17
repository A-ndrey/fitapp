import 'package:fitapp/l10n/app_localizations.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/screens/workout_session_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/workout/workout_session_cards.dart';
import 'package:fitapp/widgets/exercise_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/workout_replacement_fixture.dart';

Future<void> pumpSession(
  WidgetTester tester,
  AppStore store, {
  bool compact = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = compact
      ? const Size(390, 844)
      : const Size(1000, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WorkoutSessionScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openPicker(WidgetTester tester, {bool compact = false}) async {
  if (compact) {
    expect(find.byTooltip('Replace exercise'), findsNothing);
    await tester.drag(
      find.byType(WorkoutExerciseProgressCard).first,
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swipe-action-Replace')));
  } else {
    await tester.tap(find.byTooltip('Replace exercise').first);
  }
  await tester.pumpAndSettle();
}

Future<void> choosePushups(WidgetTester tester) async {
  final option = find.widgetWithText(ListTile, 'Pushups');
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  for (final compact in [true, false]) {
    testWidgets(
      'replaces exercise with compatible editable targets on ${compact ? 'phone' : 'desktop'}',
      (tester) async {
        final store = workoutReplacementFixture();
        await pumpSession(tester, store, compact: compact);
        await openPicker(tester, compact: compact);
        for (final muscle in ['Chest', 'Triceps']) {
          expect(
            tester
                .widget<FilterChip>(find.widgetWithText(FilterChip, muscle))
                .selected,
            isTrue,
          );
        }
        expect(find.widgetWithText(ListTile, 'Bench press'), findsNothing);
        expect(find.widgetWithText(ListTile, 'Chest fly'), findsNothing);
        expect(find.widgetWithText(ListTile, 'Plank'), findsNothing);
        await choosePushups(tester);
        expect(tester.widget<TextField>(field('Sets')).controller!.text, '3');
        expect(tester.widget<TextField>(field('Reps')).controller!.text, '8');
        expect(field('Weight'), findsNothing);
        await tester.enterText(field('Reps'), '10');
        await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
        await tester.pumpAndSettle();
        final result = store.activeWorkoutSession!.results.single;
        expect(result.exerciseName, 'Pushups');
        expect(result.target.reps, 10);
        expect(result.target.sets, 3);
        expect(result.target.weightGrams, isNull);
        expect(
          store.trainingPlanById('plan')!.exercises.single.exerciseId,
          'bench',
        );
        expect(find.text('Pushups'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      },
    );
  }

  testWidgets('filters can be relaxed and search still applies', (
    tester,
  ) async {
    final store = workoutReplacementFixture();
    await pumpSession(tester, store);
    await openPicker(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Triceps'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Chest fly'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Chest'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Plank'), findsOneWidget);
    await tester.enterText(field('Search exercises'), 'plank');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Pushups'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'Plank'));
    await tester.pumpAndSettle();
    expect(field('Reps'), findsNothing);
    expect(field('Weight'), findsNothing);
    expect(
      tester.widget<TextField>(field('Duration')).controller!.text,
      isEmpty,
    );
    await tester.enterText(field('Duration'), '45');
    await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
    await tester.pumpAndSettle();
    expect(
      store.activeWorkoutSession!.results.single.target.durationSeconds,
      45,
    );
    expect(store.activeWorkoutSession!.results.single.target.reps, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('cancelling picker or target form leaves workout unchanged', (
    tester,
  ) async {
    final store = workoutReplacementFixture();
    final original = store.activeWorkoutSession;
    await pumpSession(tester, store);
    await openPicker(tester);
    Navigator.of(tester.element(find.byType(ExercisePickerSheet))).pop();
    await tester.pumpAndSettle();
    expect(store.activeWorkoutSession, same(original));
    await openPicker(tester);
    await choosePushups(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(store.activeWorkoutSession, same(original));
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets(
    'duplicate is applied only after confirmation; cancel preserves both entries',
    (tester) async {
      final store = workoutReplacementFixture(duplicate: true);
      final original = store.activeWorkoutSession;
      await pumpSession(tester, store);
      for (final confirm in [false, true]) {
        await openPicker(tester);
        await choosePushups(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
        await tester.pumpAndSettle();
        expect(find.text('Exercise already in workout'), findsOneWidget);
        expect(store.activeWorkoutSession, same(original));
        await tester.tap(
          find.widgetWithText(
            confirm ? FilledButton : TextButton,
            confirm ? 'Replace' : 'Cancel',
          ),
        );
        await tester.pumpAndSettle();
        if (!confirm) expect(store.activeWorkoutSession, same(original));
      }
      expect(store.activeWorkoutSession!.results.map((r) => r.exerciseId), [
        'pushups',
        'pushups',
      ]);
      expect(
        store.activeWorkoutSession!.results[1],
        same(original!.results[1]),
      );
      expect(find.text('Pushups (1)'), findsOneWidget);
      expect(find.text('Pushups (2)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  for (final compact in [true, false]) {
    testWidgets(
      'logged exercise has no replacement action on ${compact ? 'phone' : 'desktop'}',
      (tester) async {
        final store = workoutReplacementFixture();
        store.addActiveWorkoutSet(
          resultIndex: 0,
          setLog: const WorkoutSetLog(reps: 8, weightGrams: 60000),
        );
        await pumpSession(tester, store, compact: compact);
        await tester.drag(
          find.byType(WorkoutExerciseProgressCard),
          const Offset(-180, 0),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Replace exercise'), findsNothing);
        expect(
          find.byKey(const ValueKey('swipe-action-Replace')),
          findsNothing,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      },
    );
  }

  testWidgets('lease lost while form is open prevents replacement', (
    tester,
  ) async {
    final store = workoutReplacementFixture();
    final readOnly = ValueNotifier(false);
    store.bindActiveWorkoutLeaseController(
      listenable: readOnly,
      isReadOnly: () => readOnly.value,
      takeOver: () async => false,
    );
    final original = store.activeWorkoutSession;
    await pumpSession(tester, store);
    await openPicker(tester);
    await choosePushups(tester);
    readOnly.value = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
    await tester.pumpAndSettle();
    expect(store.activeWorkoutSession, same(original));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byTooltip('Replace exercise'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    readOnly.dispose();
  });
}
