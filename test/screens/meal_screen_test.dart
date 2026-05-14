import 'package:fitapp/screens/meal_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {AppStore? store}) async {
    await tester.pumpWidget(
      MaterialApp(home: MealScreen(store: store ?? AppStore())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAddMealAction(WidgetTester tester) async {
    final action = tester.any(find.byType(FloatingActionButton))
        ? find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.byTooltip('Log food'),
          )
        : find.widgetWithText(FilledButton, 'Log food');
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> openRiceAmountSheet(WidgetTester tester) async {
    await tapAddMealAction(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSheetLogFood(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet).last,
        matching: find.widgetWithText(FilledButton, 'Log food'),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextField labeledField(WidgetTester tester, String label) {
    return tester.widget<TextField>(
      find.ancestor(
        of: find.bySemanticsLabel(label),
        matching: find.byType(TextField),
      ),
    );
  }

  testWidgets('meal logging defaults servings to 1', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);
    await tester.tap(find.text('Servings'));
    await tester.pumpAndSettle();

    final servingsField = labeledField(tester, 'Servings');
    expect(servingsField.controller?.text, '1');

    await tapSheetLogFood(tester);

    expect(store.mealEntries, hasLength(1));
    expect(store.mealEntries.single.enteredQuantity, 1);
  });

  testWidgets('meal logging amount field rejects letters', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);
    await tester.enterText(find.bySemanticsLabel('Grams'), 'abc');
    await tester.pumpAndSettle();

    final gramsField = labeledField(tester, 'Grams');
    expect(gramsField.controller?.text, isEmpty);

    await tapSheetLogFood(tester);

    expect(store.mealEntries, isEmpty);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('meal picker does not overflow on compact-height viewports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    await pumpScreen(tester, store: store);

    await tapAddMealAction(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
