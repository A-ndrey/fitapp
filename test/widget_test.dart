import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';

void main() {
  Future<void> openFoodTab(WidgetTester tester) async {
    await tester.tap(find.text('Food'));
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

  Future<void> fillTomatoNutrition(WidgetTester tester) async {
    await enterLabeledText(tester, 'Description', 'Fresh tomato');
    await enterLabeledText(tester, 'Serving size grams', '100');
    await enterLabeledText(tester, 'Calories', '18');
    await enterLabeledText(tester, 'Protein', '0.9');
    await enterLabeledText(tester, 'Fat', '0.2');
    await enterLabeledText(tester, 'Carbs', '3.9');
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
}
