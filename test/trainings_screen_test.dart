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
}
