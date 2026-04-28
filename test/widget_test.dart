import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/meal_entry.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/screens/food_screen.dart';
import 'package:fitapp/screens/library_screen.dart';
import 'package:fitapp/screens/meal_screen.dart';
import 'package:fitapp/screens/today_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/core/widgets/empty_state.dart';
import 'package:fitapp/ui/core/theme/app_theme.dart';
import 'package:fitapp/ui/library/library_cards.dart';
import 'package:fitapp/ui/core/widgets/section_header.dart';
import 'package:fitapp/ui/nutrition/nutrition_cards.dart';
import 'package:fitapp/ui/nutrition/nutrition_formatters.dart';
import 'package:fitapp/widgets/dish_form.dart';
import 'package:fitapp/widgets/food_form.dart';

void main() {
  const tomatoNutrition = NutritionValues(
    calories: 18,
    protein: 0.9,
    fat: 0.2,
    carbs: 3.9,
  );

  const tomatoEntry = MealEntry(
    id: 'meal-tomato',
    sourceItemId: 'tomato',
    itemName: 'Tomato',
    itemType: CatalogItemType.food,
    servingSizeGrams: 100,
    consumedGrams: 150,
    mode: MealEntryMode.grams,
    enteredQuantity: 150,
    nutrition: tomatoNutrition,
  );

  const saladEntry = MealEntry(
    id: 'meal-salad',
    sourceItemId: 'salad',
    itemName: 'Simple salad',
    itemType: CatalogItemType.dish,
    servingSizeGrams: 200,
    consumedGrams: 300,
    mode: MealEntryMode.servings,
    enteredQuantity: 1.5,
    nutrition: NutritionValues(
      calories: 62.5,
      protein: 4,
      fat: 1.2,
      carbs: 9.8,
    ),
  );

  const tomatoItem = CatalogItem.food(
    FoodItem(
      id: 'tomato',
      name: 'Tomato',
      description: 'Fresh tomato',
      servingSizeGrams: 100,
      basis: NutritionBasis.per100g,
      nutrition: tomatoNutrition,
    ),
  );

  Future<void> pumpAtSurfaceSize(
    WidgetTester tester,
    Size size,
    Widget widget,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  test('nutrition formatters render compact labels and meal quantities', () {
    final store = AppStore.empty();

    expect(formatNutritionNumber(18), '18');
    expect(formatNutritionNumber(0.9), '0.9');
    expect(formatNutritionNumber(62.5), '62.5');
    expect(
      formatNutritionLine(tomatoNutrition),
      '18 kcal • 0.9 g protein • 0.2 g fat • 3.9 g carbs',
    );
    expect(
      formatNutritionLine(
        tomatoNutrition,
        kilocalorieLabel: 'kilocalorie-unit',
        gramLabel: 'gram-unit',
        proteinLabel: 'protein-label',
        fatLabel: 'fat-label',
        carbsLabel: 'carbs-label',
      ),
      '18 kilocalorie-unit • 0.9 gram-unit protein-label • 0.2 gram-unit fat-label • 3.9 gram-unit carbs-label',
    );
    expect(formatMealQuantity(tomatoEntry, store), '150 g');
    expect(formatMealQuantity(saladEntry, store), '1.5 servings');
    expect(
      formatMealQuantity(saladEntry, store, servingsLabel: 'servings-label'),
      '1.5 servings-label',
    );

    store.setDishWeightUnit(DishWeightUnit.ounces);
    expect(formatMealQuantity(tomatoEntry, store), '5.3 oz');
  });

  testWidgets(
    'NutritionSummaryGrid renders metric cards with labels and units',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NutritionSummaryGrid(values: tomatoNutrition)),
        ),
      );

      expect(find.text('Calories'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('kcal'), findsOneWidget);
      expect(find.text('g'), findsNWidgets(3));
      expect(find.text('18'), findsOneWidget);
      expect(find.text('0.9'), findsOneWidget);
      expect(find.text('0.2'), findsOneWidget);
      expect(find.text('3.9'), findsOneWidget);
    },
  );

  testWidgets('MealEntryCard shows entry details and calls remove callback', (
    tester,
  ) async {
    var removeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealEntryCard(
            store: AppStore.empty(),
            entry: tomatoEntry,
            onRemove: () => removeCount++,
          ),
        ),
      ),
    );

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.textContaining('150 g logged'), findsOneWidget);
    expect(find.textContaining('18 kcal • 0.9 g protein'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove meal entry'));
    await tester.pump();

    expect(removeCount, 1);
  });

  testWidgets('MealSearchResultTile shows subtype and calls tap callback', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealSearchResultTile(item: tomatoItem, onTap: () => tapCount++),
        ),
      ),
    );

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Tomato'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('nutrition cards render at narrow width without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(240, 640)),
          child: Scaffold(
            body: SizedBox(
              width: 240,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const NutritionSummaryGrid(values: tomatoNutrition),
                    MealEntryCard(
                      store: AppStore.empty(),
                      entry: saladEntry,
                      onRemove: () {},
                    ),
                    MealSearchResultTile(item: tomatoItem, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Simple salad'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('food form groups basics and nutrition validation', (
    tester,
  ) async {
    final store = AppStore.empty();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodForm(store: store)),
      ),
    );

    expect(find.text('Food basics'), findsOneWidget);
    expect(find.text('Nutrition facts'), findsOneWidget);

    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a name and valid nutrition values.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('dish form groups basics and empty components', (tester) async {
    final store = AppStore.empty();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DishForm(store: store)),
      ),
    );

    expect(find.text('Dish basics'), findsOneWidget);
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('No components yet'), findsOneWidget);
    expect(
      find.text('Add foods or dishes to calculate this recipe.'),
      findsOneWidget,
    );
    expect(find.text('Add component'), findsOneWidget);
  });

  testWidgets('uses FitApp performance cockpit theme', (tester) async {
    await tester.pumpWidget(const FitApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.colorScheme.primary, AppTheme.energyOrange);
    expect(app.darkTheme?.colorScheme.surface, AppTheme.deepSurface);
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
  });

  testWidgets('Today dashboard shows workout and nutrition summary', (
    tester,
  ) async {
    final store = AppStore();
    var trainTapCount = 0;
    var nutritionTapCount = 0;
    var libraryTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          store: store,
          onOpenTrain: () => trainTapCount++,
          onOpenNutrition: () => nutritionTapCount++,
          onOpenLibrary: () => libraryTapCount++,
        ),
      ),
    );

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Ready state'), findsOneWidget);
    expect(find.text('Daily fuel'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Start workout'));
    await tester.pump();
    expect(trainTapCount, 1);

    await tester.scrollUntilVisible(
      find.text('Log meal'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log meal'), findsOneWidget);
    await tester.tap(find.text('Log meal'));
    await tester.pump();
    expect(nutritionTapCount, 1);

    await tester.scrollUntilVisible(
      find.text('Manage library'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Manage library'));
    await tester.pump();
    expect(libraryTapCount, 1);
  });

  testWidgets('Today dashboard shows active session state', (tester) async {
    var trainTapCount = 0;
    final store = AppStore()
      ..startWorkout(
        trainingPlanId: 'chest-day',
        startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: TodayScreen(
          store: store,
          onOpenTrain: () => trainTapCount++,
          onOpenNutrition: () {},
          onOpenLibrary: () {},
        ),
      ),
    );

    expect(find.text('Today'), findsWidgets);
    expect(find.text('In session'), findsOneWidget);
    expect(find.text('Open workout'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('elapsed'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pump();
    await tester.tap(find.text('Open workout'));
    await tester.pump();
    expect(trainTapCount, 1);
  });

  testWidgets(
    'Today metric grid uses one column on compact and two on medium',
    (tester) async {
      for (final entry in <({Size size, bool sameRow})>[
        (size: Size(390, 844), sameRow: false),
        (size: Size(700, 900), sameRow: true),
      ]) {
        await pumpAtSurfaceSize(
          tester,
          entry.size,
          MaterialApp(
            home: TodayScreen(
              store: AppStore(),
              onOpenTrain: () {},
              onOpenNutrition: () {},
              onOpenLibrary: () {},
            ),
          ),
        );

        final caloriesTopLeft = tester.getTopLeft(find.text('Calories'));
        final proteinTopLeft = tester.getTopLeft(find.text('Protein'));

        if (entry.sameRow) {
          expect((proteinTopLeft.dy - caloriesTopLeft.dy).abs(), lessThan(1));
          expect(proteinTopLeft.dx, greaterThan(caloriesTopLeft.dx));
        } else {
          expect(proteinTopLeft.dy, greaterThan(caloriesTopLeft.dy));
          expect((proteinTopLeft.dx - caloriesTopLeft.dx).abs(), lessThan(1));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('LibraryScreen switches between training and food libraries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LibraryScreen(store: AppStore())),
    );

    expect(find.text('Library'), findsNWidgets(2));
    expect(
      find.text('Manage reusable plans, exercises, foods, and dishes.'),
      findsOneWidget,
    );
    expect(find.byType(SectionHeader), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Foods'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Trainings'), findsNothing);
    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);

    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsNWidgets(2));
    expect(
      find.text('Manage reusable plans, exercises, foods, and dishes.'),
      findsOneWidget,
    );
    expect(find.byType(SectionHeader), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Food set'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
  });

  testWidgets('redesigned primary screens stay stable at target widths', (
    tester,
  ) async {
    const targetSizes = <Size>[
      Size(390, 844),
      Size(700, 900),
      Size(1024, 768),
      Size(1440, 900),
    ];

    for (final size in targetSizes) {
      await pumpAtSurfaceSize(
        tester,
        size,
        MaterialApp(
          home: TodayScreen(
            store: AppStore(),
            onOpenTrain: () {},
            onOpenNutrition: () {},
            onOpenLibrary: () {},
          ),
        ),
      );

      expect(find.text('Ready state'), findsOneWidget);
      expect(find.text('Daily fuel'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAtSurfaceSize(
        tester,
        size,
        MaterialApp(home: MealScreen(store: AppStore())),
      );

      expect(find.text('Nutrition cockpit'), findsOneWidget);
      expect(find.text('Daily totals'), findsOneWidget);
      expect(find.text('Meal entries'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAtSurfaceSize(
        tester,
        size,
        MaterialApp(home: LibraryScreen(store: AppStore())),
      );

      expect(find.text('Library'), findsNWidgets(2));
      expect(find.text('Training plans'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Foods'));
      await tester.pumpAndSettle();

      expect(find.text('Food set'), findsOneWidget);
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  const rootDestinationLabels = [
    'Today',
    'Train',
    'Nutrition',
    'Library',
    'More',
  ];

  Future<void> tapRootDestination(WidgetTester tester, String label) async {
    if (tester.any(find.byType(NavigationBar))) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            )
            .last,
      );
      return;
    }

    final index = rootDestinationLabels.indexOf(label);
    if (index == -1) {
      throw ArgumentError.value(label, 'label', 'Unknown root destination');
    }
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    rail.onDestinationSelected?.call(index);
  }

  Future<void> openLibraryFoodsSection(WidgetTester tester) async {
    await tapRootDestination(tester, 'Library');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foods').last);
    await tester.pumpAndSettle();
  }

  Future<void> openNutritionDestination(WidgetTester tester) async {
    await tapRootDestination(tester, 'Nutrition');
    await tester.pumpAndSettle();
  }

  Future<void> openLibraryDestination(WidgetTester tester) async {
    await tapRootDestination(tester, 'Library');
    await tester.pumpAndSettle();
  }

  Future<void> openMoreDestination(WidgetTester tester) async {
    await tapRootDestination(tester, 'More');
    await tester.pumpAndSettle();
  }

  Future<void> openAddFoodOrDish(WidgetTester tester) async {
    final tooltip = find.byTooltip('Add food or dish');
    if (tester.any(tooltip)) {
      await tester.tap(tooltip);
    } else {
      await tester.tap(find.widgetWithText(FilledButton, 'Add food or dish'));
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapAddMealFab(WidgetTester tester) async {
    final action = tester.any(find.byType(FloatingActionButton))
        ? find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.byTooltip('Add meal item'),
          )
        : find.widgetWithText(FilledButton, 'Add meal item');
    await tester.tap(action);
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
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapRowAction(
    WidgetTester tester,
    String itemName,
    String tooltip,
    IconData icon,
  ) async {
    if (!tester.any(find.byTooltip(tooltip))) {
      await tester.scrollUntilVisible(
        find.byTooltip(tooltip),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
    }
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
    await openNutritionDestination(tester);
    await tapAddMealFab(tester);
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
    await openLibraryFoodsSection(tester);
    await openAddFoodOrDish(tester);
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

  testWidgets('shows Today, Train, Nutrition, Library and More destinations', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Train'), findsWidgets);
    expect(find.text('Nutrition'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('More'), findsWidgets);
    expect(find.text('Ready state'), findsOneWidget);
    expect(find.text('Chicken breast'), findsNothing);

    await openLibraryDestination(tester);

    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);

    await openNutritionDestination(tester);

    expect(find.text('Daily totals'), findsOneWidget);

    await openLibraryFoodsSection(tester);

    expect(find.text('Food set'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('food'), findsWidgets);
  });

  testWidgets('Nutrition shell shows cockpit header and add action', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await openNutritionDestination(tester);

    expect(find.text('Meal'), findsWidgets);
    expect(find.text('Nutrition cockpit'), findsOneWidget);
    expect(
      find.text('Log food, review macros, and keep today visible.'),
      findsOneWidget,
    );
    expect(find.text('Daily totals'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('No meal entries yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add meal item'), findsOneWidget);
    expect(find.byTooltip('Add meal item'), findsOneWidget);
  });

  testWidgets('Nutrition uses one primary add action per responsive mode', (
    tester,
  ) async {
    await pumpAtSurfaceSize(
      tester,
      const Size(390, 844),
      MaterialApp(home: MealScreen(store: AppStore())),
    );

    expect(find.widgetWithText(FilledButton, 'Add meal item'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Add meal item'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAtSurfaceSize(
      tester,
      const Size(1024, 768),
      MaterialApp(home: MealScreen(store: AppStore())),
    );

    expect(find.widgetWithText(FilledButton, 'Add meal item'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Add meal item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows More tab and opens settings screen', (tester) async {
    await tester.pumpWidget(const FitApp());

    expect(find.text('More'), findsWidgets);

    await openMoreDestination(tester);

    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
    await scrollToText(tester, 'Language');
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('sync buttons depend on login state', (tester) async {
    final store = AppStore.empty();

    await tester.pumpWidget(FitApp(store: store));
    await openMoreDestination(tester);

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsNothing);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('more screen controls update store and theme immediately', (
    tester,
  ) async {
    final store = AppStore.empty();

    await tester.pumpWidget(FitApp(store: store));
    await openMoreDestination(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();
    expect(store.workoutWeightUnit, WorkoutWeightUnit.pounds);

    await scrollToText(tester, 'Ounces');
    await tester.tap(find.text('Ounces'));
    await tester.pumpAndSettle();
    expect(store.dishWeightUnit, DishWeightUnit.ounces);

    await scrollToText(tester, 'Inches');
    await tester.tap(find.text('Inches'));
    await tester.pumpAndSettle();
    expect(store.heightUnit, HeightUnit.inches);

    await scrollToText(tester, 'Miles');
    await tester.tap(find.text('Miles'));
    await tester.pumpAndSettle();
    expect(store.distanceUnit, DistanceUnit.miles);

    await scrollToText(tester, 'Dark');
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(store.appearancePreference, AppearancePreference.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(store.appearancePreference, AppearancePreference.light);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('daily totals update after logging sample food by grams', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
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

  testWidgets('Meal search sheet shows title, helper, and result subtype', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Add meal item'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search your saved foods and dishes, or create a new food from your query.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Search foods and dishes'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);
  });

  testWidgets('creates a food from the Food tab', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryFoodsSection(tester);
    await openAddFoodOrDish(tester);
    await tester.tap(find.text('Food item'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Name', 'Tomato');
    await fillTomatoNutrition(tester);
    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Tomato');
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('FoodScreen uses adaptive catalog cards for saved foods', (
    tester,
  ) async {
    final store = AppStore();
    store.setDishWeightUnit(DishWeightUnit.ounces);

    await tester.pumpWidget(MaterialApp(home: FoodScreen(store: store)));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.byType(FoodCatalogCard), findsWidgets);
    expect(find.text('Food set'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('5.3 oz serving'), findsWidgets);
    expect(find.textContaining('41 kcal per serving'), findsWidgets);
    expect(find.byTooltip('Add food or dish'), findsOneWidget);
    expect(find.byTooltip('Edit Rice'), findsOneWidget);
    expect(find.byTooltip('Delete Rice'), findsOneWidget);
  });

  testWidgets('embedded empty FoodScreen is scaffold-free with empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FoodScreen(store: AppStore.empty(), embedded: true)),
    );

    expect(find.byType(Scaffold), findsNothing);
    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Food set'), findsOneWidget);
    expect(find.text('No foods or dishes yet'), findsOneWidget);
    expect(
      find.text('Use Add food or dish to build your reusable catalog.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Add food or dish'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('creates a dish from existing foods', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryFoodsSection(tester);
    await openAddFoodOrDish(tester);
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

  testWidgets('food and meal displays render ounces when dish unit is ounces', (
    tester,
  ) async {
    final store = AppStore();
    store.setDishWeightUnit(DishWeightUnit.ounces);

    await tester.pumpWidget(FitApp(store: store));

    await openLibraryFoodsSection(tester);
    await scrollToText(tester, 'Rice');
    expect(find.textContaining('5.3 oz serving'), findsWidgets);

    await logRice150g(tester);

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('5.3 oz logged'), findsOneWidget);
  });

  testWidgets('training plan target labels render pounds in plan editor', (
    tester,
  ) async {
    final store = AppStore();
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    await tester.pumpWidget(FitApp(store: store));
    await openLibraryDestination(tester);

    await tester.tap(find.byTooltip('Edit Chest day'));
    await tester.pumpAndSettle();

    expect(find.text('132.3 lbs weight'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Weight'), findsNothing);
  });

  testWidgets('creates a missing item from Meal search and logs it', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Tomato',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Add meal item'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search your saved foods and dishes, or create a new food from your query.',
      ),
      findsOneWidget,
    );
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
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
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
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();

    expect(find.text('Create "Rice"'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
  });

  testWidgets('rejects invalid meal amounts without adding or closing', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Rice'));
    await tester.pumpAndSettle();

    expect(
      find.text("Choose how much you ate, then add it to today's meal log."),
      findsOneWidget,
    );
    expect(find.text('Grams'), findsWidgets);
    expect(find.text('Servings'), findsOneWidget);

    for (final value in ['abc', '0', '-1', 'NaN', 'Infinity']) {
      await tester.enterText(find.bySemanticsLabel('Grams'), value);
      await tester.tap(find.text('Add to meal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);
      expect(find.text('No meal entries yet'), findsOneWidget);
    }
  });

  testWidgets('logs an existing meal item by grams', (tester) async {
    await tester.pumpWidget(const FitApp());

    await logRice150g(tester);

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('150 g logged'), findsOneWidget);
    expect(find.textContaining('195 kcal'), findsOneWidget);
  });

  testWidgets('removes a logged meal entry from Nutrition screen', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await logRice150g(tester);

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('195 kcal'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove meal entry'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);
    expect(find.text('No meal entries yet'), findsOneWidget);
    expect(find.textContaining('195 kcal'), findsNothing);
  });

  testWidgets('logs an existing meal item by servings', (tester) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and dishes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Rice'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servings'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Servings'), '2');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('2 servings logged'), findsOneWidget);
    expect(find.textContaining('390 kcal'), findsOneWidget);
  });

  testWidgets('deleting a logged item keeps meal snapshot', (tester) async {
    await tester.pumpWidget(const FitApp());

    await logRice150g(tester);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('195 kcal'), findsOneWidget);

    await openLibraryFoodsSection(tester);
    await scrollToText(tester, 'Rice');
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    await tapRowAction(tester, 'Rice', 'Delete Rice', Icons.delete_outline);
    expect(find.text('Delete Rice?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);

    await openNutritionDestination(tester);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.textContaining('195 kcal'), findsOneWidget);
  });

  testWidgets('blocks deleting an item referenced by a dish', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryFoodsSection(tester);
    await openAddFoodOrDish(tester);
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
      expect(find.textContaining('195 kcal'), findsOneWidget);

      await openLibraryFoodsSection(tester);
      await tapRowAction(tester, 'Rice', 'Edit Rice', Icons.edit_outlined);

      await enterLabeledText(tester, 'Name', 'Brown rice');
      await enterLabeledText(tester, 'Calories', '200');
      await tester.tap(find.text('Save food'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Brown rice'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Rice'), findsNothing);

      await openNutritionDestination(tester);
      expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
      expect(find.textContaining('195 kcal'), findsOneWidget);
    },
  );

  testWidgets('editing a dish updates the dish row', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryFoodsSection(tester);
    await openAddFoodOrDish(tester);
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
