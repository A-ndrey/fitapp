import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/meal_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  void seedRice(AppStore store) {
    store.createFood(
      const FoodItem(
        id: 'rice',
        name: 'Rice',
        description: 'Cooked white rice',
        servingSizeGrams: 150,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(
          calories: 130,
          protein: 2.7,
          fat: 0.3,
          carbs: 28,
        ),
      ),
    );
  }

  void seedRiceBowl(AppStore store) {
    store.createDish(
      const DishItem(
        id: 'rice-bowl',
        name: 'Rice bowl',
        description: 'Rice with vegetables and sauce',
        servingSizeGrams: 350,
        components: [DishComponent(itemId: 'rice', grams: 150)],
      ),
    );
  }

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
    seedRice(store);
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

  testWidgets('meal logging defaults grams to one serving', (tester) async {
    final store = AppStore();
    seedRice(store);
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);

    final gramsField = labeledField(tester, 'Grams');
    expect(gramsField.controller?.text, '150');
  });

  testWidgets('meal logging amount sheet shows food serving details', (
    tester,
  ) async {
    final store = AppStore();
    seedRice(store);
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Cooked white rice'), findsOneWidget);
    expect(find.text('150 g per serving'), findsOneWidget);
  });

  testWidgets('meal logging keeps separate grams and servings values', (
    tester,
  ) async {
    final store = AppStore();
    seedRice(store);
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);
    await tester.enterText(find.bySemanticsLabel('Grams'), '200');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servings'));
    await tester.pumpAndSettle();
    var servingsField = labeledField(tester, 'Servings');
    expect(servingsField.controller?.text, '1');

    await tester.enterText(find.bySemanticsLabel('Servings'), '2');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grams'));
    await tester.pumpAndSettle();
    final gramsField = labeledField(tester, 'Grams');
    expect(gramsField.controller?.text, '200');

    await tester.tap(find.text('Servings'));
    await tester.pumpAndSettle();
    servingsField = labeledField(tester, 'Servings');
    expect(servingsField.controller?.text, '2');
  });

  testWidgets('meal logging amount field rejects letters', (tester) async {
    final store = AppStore();
    seedRice(store);
    await pumpScreen(tester, store: store);

    await openRiceAmountSheet(tester);
    await tester.enterText(find.bySemanticsLabel('Grams'), '');
    await tester.pumpAndSettle();
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

  testWidgets('meal picker rows show details and library icons', (
    tester,
  ) async {
    final store = AppStore();
    seedRice(store);
    seedRiceBowl(store);
    await pumpScreen(tester, store: store);

    await tapAddMealAction(tester);

    final riceTile = find.ancestor(
      of: find.text('Rice').last,
      matching: find.byType(ListTile),
    );
    final riceBowlTile = find.ancestor(
      of: find.text('Rice bowl').last,
      matching: find.byType(ListTile),
    );

    expect(
      find.descendant(of: riceTile, matching: find.byIcon(Icons.eco_outlined)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: riceBowlTile,
        matching: find.byIcon(Icons.ramen_dining_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: riceTile, matching: find.text('Cooked white rice')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: riceBowlTile,
        matching: find.text('Rice with vegetables and sauce'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: riceTile, matching: find.text('150 g serving')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: riceBowlTile, matching: find.text('350 g serving')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: riceTile, matching: find.text('food')),
      findsNothing,
    );
    expect(
      find.descendant(of: riceBowlTile, matching: find.text('recipe')),
      findsNothing,
    );

    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.bySemanticsLabel('Grams'),
        matching: find.byType(TextField),
      ),
      findsOneWidget,
    );
    expect(find.text('Servings'), findsOneWidget);
  });

  testWidgets(
    'meal screen groups history by date and shows newest entries first',
    (tester) async {
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

      store.addMealByGrams(
        itemId: 'tomato',
        grams: 100,
        loggedAt: todayMorning,
      );
      store.addMealByGrams(itemId: 'tomato', grams: 200, loggedAt: previousDay);
      store.addMealByGrams(
        itemId: 'tomato',
        grams: 150,
        loggedAt: todayEvening,
      );

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
    },
  );
}
