import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/food_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/widgets/dish_form.dart';

void main() {
  Future<void> openFoodTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> openMealTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.restaurant));
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

  Future<void> scrollToText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapRowAction(
    WidgetTester tester,
    String itemName,
    String tooltip,
    IconData icon,
  ) async {
    expect(find.byTooltip(tooltip), findsOneWidget);
    final visibleFoodItemText = find.descendant(
      of: find.byType(FoodScreen),
      matching: find.text(itemName),
    );
    final row = find.ancestor(
      of: visibleFoodItemText,
      matching: find.byType(ListTile),
    );
    final action = find.descendant(
      of: row,
      matching: find.widgetWithIcon(IconButton, icon),
    );
    await tester.ensureVisible(action);
    tester.widget<IconButton>(action).onPressed!();
    await tester.pumpAndSettle();
  }

  Future<void> logRice150g(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Rice'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Grams'), '150');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();
  }

  Future<void> fillTomatoNutrition(WidgetTester tester) async {
    await enterLabeledText(tester, 'Description', 'Fresh tomato');
    await enterLabeledText(tester, 'Serving size grams', '100');
    await enterLabeledText(tester, 'Calories', '18');
    await enterLabeledText(tester, 'Protein', '0.9');
    await enterLabeledText(tester, 'Fat', '0.2');
    await enterLabeledText(tester, 'Carbs', '3.9');
  }

  Future<void> createSimpleSalad(WidgetTester tester) async {
    await openFoodTab(tester);
    await tester.tap(find.byTooltip('Add food or dish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dish'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Dish name', 'Simple salad');
    await enterLabeledText(tester, 'Dish description', 'Carrot');
    await enterLabeledText(tester, 'Dish serving size grams', '100');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Component grams', '100');
    await tester.tap(find.text('Save component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows Meal and Food tabs with sample content', (tester) async {
    await tester.pumpWidget(const FitApp());

    expect(find.text('Meal'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Daily totals'), findsOneWidget);
    expect(find.text('Chicken breast'), findsNothing);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Food set'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('food'), findsWidgets);
  });

  testWidgets('daily totals update after logging sample food by grams', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicken breast').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Grams'), '200');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.textContaining('330'), findsWidgets);
    expect(find.textContaining('62'), findsWidgets);
  });

  testWidgets('creates a food from the Food tab', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openFoodTab(tester);
    await tester.tap(find.byTooltip('Add food or dish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food item'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Name', 'Tomato');
    await fillTomatoNutrition(tester);
    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Tomato');
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('creates a dish from existing foods', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openFoodTab(tester);
    await tester.tap(find.byTooltip('Add food or dish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dish'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Dish name', 'Simple salad');
    await enterLabeledText(tester, 'Dish description', 'Carrot and onion');
    await enterLabeledText(tester, 'Dish serving size grams', '150');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Component grams', '100');
    await tester.tap(find.text('Save component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Simple salad');
    expect(find.text('Simple salad'), findsOneWidget);
    expect(find.text('dish'), findsWidgets);
    expect(find.textContaining('150 g serving'), findsWidgets);
  });

  testWidgets('creates a missing item from Meal search and logs it', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Tomato',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create "Tomato"'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Tomato'), findsOneWidget);
    await enterLabeledText(tester, 'Description', 'Fresh tomato');
    await enterLabeledText(tester, 'Serving size grams', '100');
    await enterLabeledText(tester, 'Calories', '18');
    await enterLabeledText(tester, 'Protein', '0.9');
    await enterLabeledText(tester, 'Fat', '0.2');
    await enterLabeledText(tester, 'Carbs', '3.9');
    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Grams'), '100');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.textContaining('18'), findsWidgets);
  });

  testWidgets('logs renamed food created from Meal search', (tester) async {
    await tester.pumpWidget(const FitApp());

    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'tom',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create "tom"'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Name', 'Tomato');
    await fillTomatoNutrition(tester);
    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Grams'), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Grams'), '100');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.textContaining('18'), findsWidgets);
  });

  testWidgets('does not offer create action for exact Meal search match', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();

    expect(find.text('Create "Rice"'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
  });

  testWidgets('deleting a logged item keeps meal snapshot', (tester) async {
    await tester.pumpWidget(const FitApp());

    await logRice150g(tester);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.text('Calories: 195 kcal'), findsOneWidget);

    await openFoodTab(tester);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    await tapRowAction(tester, 'Rice', 'Delete Rice', Icons.delete_outline);
    expect(find.text('Delete Rice?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);

    await openMealTab(tester);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.text('Calories: 195 kcal'), findsOneWidget);
  });

  testWidgets('blocks deleting an item referenced by a dish', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openFoodTab(tester);
    await tester.tap(find.byTooltip('Add food or dish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dish'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Dish name', 'Simple salad');
    await enterLabeledText(tester, 'Dish description', 'Carrot');
    await enterLabeledText(tester, 'Dish serving size grams', '100');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Component grams', '100');
    await tester.tap(find.text('Save component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();

    await tapRowAction(tester, 'Carrot', 'Delete Carrot', Icons.delete_outline);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Carrot'), findsOneWidget);
    expect(find.textContaining('used by a dish'), findsOneWidget);
  });

  testWidgets(
    'editing a food updates catalog but not existing meal snapshots',
    (tester) async {
      await tester.pumpWidget(const FitApp());

      await logRice150g(tester);
      expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
      expect(find.text('Calories: 195 kcal'), findsOneWidget);

      await openFoodTab(tester);
      await tapRowAction(tester, 'Rice', 'Edit Rice', Icons.edit_outlined);

      await enterLabeledText(tester, 'Name', 'Brown rice');
      await enterLabeledText(tester, 'Calories', '200');
      await tester.tap(find.text('Save food'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Brown rice'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);

      await openMealTab(tester);
      expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
      expect(find.text('Calories: 195 kcal'), findsOneWidget);
    },
  );

  testWidgets('editing a dish updates the dish row', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openFoodTab(tester);
    await tester.tap(find.byTooltip('Add food or dish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dish'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Dish name', 'Simple salad');
    await enterLabeledText(tester, 'Dish description', 'Carrot and onion');
    await enterLabeledText(tester, 'Dish serving size grams', '150');
    await tester.tap(find.text('Add component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Component grams', '100');
    await tester.tap(find.text('Save component'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Simple salad');
    await tapRowAction(
      tester,
      'Simple salad',
      'Edit Simple salad',
      Icons.edit_outlined,
    );
    await enterLabeledText(tester, 'Dish name', 'Carrot salad');
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Carrot salad'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Simple salad'), findsNothing);
  });

  testWidgets('editing a dish component updates dish nutrition', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await createSimpleSalad(tester);
    await scrollToText(tester, 'Simple salad');
    expect(find.textContaining('41 kcal per serving'), findsOneWidget);

    await tapRowAction(
      tester,
      'Simple salad',
      'Edit Simple salad',
      Icons.edit_outlined,
    );
    await tester.tap(find.byTooltip('Edit Carrot component'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Component grams', '50');
    await tester.tap(find.text('Save component'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Dish name', 'Half carrot salad');
    await tester.tap(find.text('Save dish'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Half carrot salad'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Simple salad'), findsNothing);
    expect(find.textContaining('20.5 kcal per serving'), findsOneWidget);
  });

  testWidgets('editing a dish preserves unchanged fractional inputs', (
    tester,
  ) async {
    final store = AppStore.empty();
    const carrot = FoodItem(
      id: 'carrot',
      name: 'Carrot',
      description: 'Raw carrot',
      servingSizeGrams: 100,
      basis: NutritionBasis.per100g,
      nutrition: NutritionValues(calories: 100, protein: 0, fat: 0, carbs: 0),
    );
    const salad = DishItem(
      id: 'fractional-salad',
      name: 'Fractional salad',
      description: 'Fractional amounts',
      servingSizeGrams: 100.25,
      components: [DishComponent(itemId: 'carrot', grams: 33.33)],
    );
    store.createFood(carrot);
    store.createDish(salad);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DishForm(store: store, initialDish: salad),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Edit Carrot component'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '33.33'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save component'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save dish'));
    await tester.pumpAndSettle();

    final updated = store.itemById('fractional-salad')!.dish!;
    expect(updated.servingSizeGrams, closeTo(100.25, 0.0001));
    expect(updated.components.single.grams, closeTo(33.33, 0.0001));
    expect(
      updated.nutritionPerServing(store.catalog).calories,
      closeTo(33.33, 0.0001),
    );
  });
}
