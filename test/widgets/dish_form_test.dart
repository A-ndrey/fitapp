import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/widgets/dish_form.dart';

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField("$label")',
  );
}

String _textFieldValue(WidgetTester tester, Finder finder) {
  final field = tester.widget<TextField>(finder);
  final controller = field.controller;
  expect(controller, isNotNull);
  return controller!.text;
}

Widget _wrapForTest(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets(
    'recipe adds ingredient from search sheet and edits grams inline',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = AppStore();
      addTearDown(store.dispose);

      await tester.pumpWidget(_wrapForTest(DishForm(store: store)));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
      await tester.pumpAndSettle();

      expect(_textFieldWithLabel('Search ingredients'), findsOneWidget);
      expect(_textFieldWithLabel('Ingredient grams'), findsNothing);

      await tester.enterText(_textFieldWithLabel('Search ingredients'), 'Rice');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rice').last);
      await tester.pumpAndSettle();

      await tester.enterText(_textFieldWithLabel('Recipe name'), 'Rice bowl');
      await tester.enterText(
        _textFieldWithLabel('Recipe serving size grams'),
        '175',
      );
      await tester.enterText(_textFieldWithLabel('Ingredient grams'), '175');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save recipe'));
      await tester.pumpAndSettle();

      final createdDish = store.items
          .firstWhere((item) => item.name == 'Rice bowl')
          .dish;
      expect(createdDish, isNotNull);
      expect(createdDish!.components, hasLength(1));
      expect(createdDish.components.single.itemId, 'rice');
      expect(createdDish.components.single.grams, 175);
    },
  );

  testWidgets('recipe ingredient grams field rejects letters', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore();
    addTearDown(store.dispose);
    const initialDish = DishItem(
      id: 'rice-bowl',
      name: 'Rice bowl',
      description: 'Simple bowl',
      servingSizeGrams: 100,
      components: <DishComponent>[DishComponent(itemId: 'rice', grams: 100)],
    );

    await tester.pumpWidget(
      _wrapForTest(DishForm(store: store, initialDish: initialDish)),
    );

    final gramsField = _textFieldWithLabel('Ingredient grams');
    expect(gramsField, findsOneWidget);

    await tester.enterText(gramsField, '12');
    await tester.pump();
    expect(_textFieldValue(tester, gramsField), '12');

    await tester.enterText(gramsField, '12a');
    await tester.pump();
    expect(_textFieldValue(tester, gramsField), '12');
  });

  testWidgets('recipe serving size grams field rejects letters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(_wrapForTest(DishForm(store: store)));

    final servingSizeField = _textFieldWithLabel('Recipe serving size grams');
    expect(servingSizeField, findsOneWidget);

    await tester.enterText(servingSizeField, '12');
    await tester.pump();
    expect(_textFieldValue(tester, servingSizeField), '12');

    await tester.enterText(servingSizeField, '12a');
    await tester.pump();
    expect(_textFieldValue(tester, servingSizeField), '12');
  });

  testWidgets('recipe save blocks when inline ingredient grams are empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = AppStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(_wrapForTest(DishForm(store: store)));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add ingredient'));
    await tester.pumpAndSettle();
    await tester.enterText(_textFieldWithLabel('Search ingredients'), 'Rice');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    await tester.enterText(_textFieldWithLabel('Recipe name'), 'Rice bowl');
    await tester.enterText(
      _textFieldWithLabel('Recipe serving size grams'),
      '175',
    );
    await tester.enterText(_textFieldWithLabel('Ingredient grams'), '');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Save recipe'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose an item and enter valid ingredient grams.'),
      findsOneWidget,
    );
    expect(store.items.where((item) => item.name == 'Rice bowl'), isEmpty);
  });
}
