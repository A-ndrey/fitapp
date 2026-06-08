import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/widgets/food_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField("$label")',
  );
}

void main() {
  Future<void> pumpForm(WidgetTester tester, AppStore store) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodForm(store: store)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillNutrition(WidgetTester tester) async {
    await tester.enterText(_textFieldWithLabel('Serving size grams'), '100');
    await tester.enterText(_textFieldWithLabel('Calories'), '10');
    await tester.enterText(_textFieldWithLabel('Protein'), '1');
    await tester.enterText(_textFieldWithLabel('Fat'), '1');
    await tester.enterText(_textFieldWithLabel('Carbs'), '1');
  }

  testWidgets('touched food numeric field rejects letters', (tester) async {
    await pumpForm(tester, AppStore.empty());

    await tester.enterText(find.bySemanticsLabel('Serving size grams'), 'abc');
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.ancestor(
        of: find.bySemanticsLabel('Serving size grams'),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('food form creates a UUID when name has no slug text', (
    tester,
  ) async {
    final store = AppStore.empty();

    await pumpForm(tester, store);

    await tester.enterText(_textFieldWithLabel('Name'), '!!!');
    await fillNutrition(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save food'));
    await tester.pumpAndSettle();

    final food = store.items.single.food;
    expect(food?.id, matches(_uuidPattern));
    expect(food?.name, '!!!');
    expect(find.text('Food id must not be empty.'), findsNothing);
  });

  testWidgets('food form blocks duplicate names', (tester) async {
    final store = AppStore.empty();
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

    await pumpForm(tester, store);

    await tester.enterText(_textFieldWithLabel('Name'), ' tomato ');
    await fillNutrition(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save food'));
    await tester.pumpAndSettle();

    expect(find.text('A food with this name already exists.'), findsOneWidget);
  });
}
