import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/meal_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/widgets/barcode_input_screen.dart';
import 'package:fitapp/widgets/food_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/fake_barcode_camera.dart';

const milk = FoodItem(
  id: 'milk',
  name: 'Milk',
  description: 'Whole milk',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 60, protein: 3, fat: 3, carbs: 5),
);

Future<void> enterBarcode(WidgetTester tester, String code) async {
  expect(find.byType(MobileScanner), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextField, 'Barcode digits'),
    code,
  );
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Use barcode'));
  await tester.tap(find.widgetWithText(FilledButton, 'Use barcode'));
  await tester.pumpAndSettle();
}

Future<void> openLoggingScanner(WidgetTester tester, AppStore store) async {
  await tester.pumpWidget(MaterialApp(home: MealScreen(store: store)));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Log food'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Scan barcode'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FakeBarcodeCamera camera;
  late MobileScannerPlatform original;
  setUp(() {
    original = MobileScannerPlatform.instance;
    camera = FakeBarcodeCamera();
    MobileScannerPlatform.instance = camera;
  });
  tearDown(() async {
    MobileScannerPlatform.instance = original;
    await camera.close();
  });

  testWidgets('known barcode opens amount entry and requires confirmation', (
    tester,
  ) async {
    final store = AppStore()
      ..createFood(milk.copyWith(barcodes: ['0012345678905']));
    addTearDown(store.dispose);
    await openLoggingScanner(tester, store);
    await enterBarcode(tester, '012345678905');
    expect(find.byType(BarcodeInputScreen), findsNothing);
    expect(find.widgetWithText(TextField, 'Grams'), findsOneWidget);
    expect(store.mealEntries, isEmpty);
    await tester.enterText(find.widgetWithText(TextField, 'Grams'), '200');
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(FilledButton, 'Log food'),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.mealEntries.single.consumedGrams, 200);
    expect(store.mealEntries.single.nutrition.calories, 120);
  });

  testWidgets(
    'unknown barcode binds an existing food, excludes recipes and returns to logging',
    (tester) async {
      final store = AppStore()
        ..createFood(milk)
        ..createDish(
          const DishItem(
            id: 'recipe',
            name: 'Milk shake',
            description: '',
            servingSizeGrams: 100,
            components: [DishComponent(itemId: 'milk', grams: 100)],
          ),
        );
      addTearDown(store.dispose);
      await openLoggingScanner(tester, store);
      await enterBarcode(tester, '0012345678905');
      expect(find.text('Product not found'), findsOneWidget);
      await tester.tap(find.text('Link existing food'));
      await tester.pumpAndSettle();
      expect(find.text('Milk shake'), findsNothing);
      await tester.tap(find.text('Milk').last);
      await tester.pumpAndSettle();
      expect(store.foodByBarcode('0012345678905')?.id, 'milk');
      expect(store.mealEntries, isEmpty);
      expect(find.widgetWithText(TextField, 'Grams'), findsOneWidget);
    },
  );

  testWidgets(
    'unknown barcode prefills new food and continues logging after save',
    (tester) async {
      final store = AppStore();
      addTearDown(store.dispose);
      await openLoggingScanner(tester, store);
      await enterBarcode(tester, '0012345678905');
      await tester.tap(find.text('Create food'));
      await tester.pumpAndSettle();
      expect(find.byType(FoodForm), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Milk');
      for (final label in [
        'Serving size grams',
        'Calories',
        'Protein',
        'Fat',
        'Carbs',
      ]) {
        final field = find.widgetWithText(TextField, label);
        await tester.ensureVisible(field);
        await tester.enterText(
          field,
          label == 'Serving size grams' ? '100' : '1',
        );
      }
      await tester.ensureVisible(find.text('0012345678905'));
      expect(find.text('0012345678905'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save food'));
      await tester.pumpAndSettle();
      expect(store.foodByBarcode('0012345678905')?.name, 'Milk');
      expect(find.widgetWithText(TextField, 'Grams'), findsOneWidget);
      expect(store.mealEntries, isEmpty);
    },
  );

  testWidgets('cancelling unknown code creates no food or meal', (
    tester,
  ) async {
    final store = AppStore();
    addTearDown(store.dispose);
    await openLoggingScanner(tester, store);
    await enterBarcode(tester, '0012345678905');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.items, isEmpty);
    expect(store.mealEntries, isEmpty);
  });

  testWidgets('editing supports several codes and removing a binding', (
    tester,
  ) async {
    final store = AppStore()
      ..createFood(milk.copyWith(barcodes: ['0012345678905']));
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodForm(
            store: store,
            initialFood: store.itemById('milk')!.food,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Add barcode'),
    );
    await enterBarcode(tester, '96385074');
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Add barcode'),
    );
    await enterBarcode(tester, '012345678905');
    expect(find.text('0012345678905'), findsOneWidget);
    expect(find.text('012345678905'), findsNothing);
    final originalRow = find.ancestor(
      of: find.text('0012345678905'),
      matching: find.byType(ListTile),
    );
    await tapVisible(
      tester,
      find.descendant(
        of: originalRow,
        matching: find.byTooltip('Remove barcode'),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save food'));
    await tester.pumpAndSettle();
    expect(store.itemById('milk')!.food!.barcodes, ['96385074']);
  });

  testWidgets('a code already owned by another food cannot be added', (
    tester,
  ) async {
    final store = AppStore()
      ..createFood(milk.copyWith(barcodes: ['0012345678905']))
      ..createFood(milk.copyWith(id: 'other', name: 'Other'));
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodForm(
            store: store,
            initialFood: store.itemById('other')!.food,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Add barcode'),
    );
    await enterBarcode(tester, '0012345678905');
    final error = find.text('This barcode is already linked to Milk.');
    await tester.ensureVisible(error);
    expect(error, findsOneWidget);
    expect(store.foodByBarcode('0012345678905')?.id, 'milk');
  });

  testWidgets('manual entry validates input on a compact phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBarcodeInput(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await enterBarcode(tester, '123');
    expect(find.text('Enter 8, 12, 13 or 14 digits.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await enterBarcode(tester, '0012345678905');
    expect(find.byType(BarcodeInputScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
