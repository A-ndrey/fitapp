import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/meal_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

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

  testWidgets('meal screen groups history by date and shows newest entries first', (
    tester,
  ) async {
    final store = AppStore.empty();
    final now = DateTime.now();
    final todayMorning = DateTime(now.year, now.month, now.day, 9);
    final todayEvening = DateTime(now.year, now.month, now.day, 20);
    final previousDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1)).copyWith(hour: 18);
    store.createFood(
      const FoodItem(
        id: 'tomato',
        name: 'Tomato',
        description: 'Fresh tomato',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(
          calories: 18,
          protein: 0.9,
          fat: 0.2,
          carbs: 3.9,
        ),
      ),
    );

    store.addMealByGrams(itemId: 'tomato', grams: 100, loggedAt: todayMorning);
    store.addMealByGrams(itemId: 'tomato', grams: 200, loggedAt: previousDay);
    store.addMealByGrams(itemId: 'tomato', grams: 150, loggedAt: todayEvening);

    await pumpScreen(tester, store: store);

    final locale = Localizations.localeOf(
      tester.element(find.byType(MealScreen)),
    ).toString();
    final dateFormat = DateFormat.yMMMMd(locale);

    expect(find.textContaining('45 kcal'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(dateFormat.format(todayMorning)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(dateFormat.format(todayMorning)), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(dateFormat.format(previousDay)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(dateFormat.format(previousDay)), findsOneWidget);
    expect(find.textContaining('36 kcal'), findsOneWidget);
  });
}
