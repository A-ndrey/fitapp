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
import 'package:fitapp/ui/core/widgets/action_card.dart';
import 'package:fitapp/ui/core/widgets/metric_card.dart';
import 'package:fitapp/ui/library/library_cards.dart';
import 'package:fitapp/ui/library/library_formatters.dart';
import 'package:fitapp/ui/core/widgets/section_header.dart';
import 'package:fitapp/ui/nutrition/nutrition_cards.dart';
import 'package:fitapp/ui/nutrition/nutrition_formatters.dart';
import 'package:fitapp/widgets/dish_form.dart';
import 'package:fitapp/widgets/food_form.dart';

Future<void> scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

const rootDestinationLabels = [
  'Today',
  'Train',
  'Nutrition',
  'Library',
  'Settings',
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
  if (tester.any(find.byType(NavigationBar)) ||
      tester.any(find.byType(NavigationRail))) {
    await tapRootDestination(tester, 'Library');
    await tester.pumpAndSettle();
  }
  while (!tester.any(find.widgetWithText(ActionCard, 'Food library')) &&
      tester.any(find.byIcon(Icons.arrow_back))) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }
  if (tester.any(find.widgetWithText(ActionCard, 'Food library'))) {
    await tester.tap(find.widgetWithText(ActionCard, 'Food library'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Foods'));
  await tester.pumpAndSettle();
}

Future<void> openLibraryRecipesSection(WidgetTester tester) async {
  if (tester.any(find.byType(NavigationBar)) ||
      tester.any(find.byType(NavigationRail))) {
    await tapRootDestination(tester, 'Library');
    await tester.pumpAndSettle();
  }
  while (!tester.any(find.widgetWithText(ActionCard, 'Food library')) &&
      tester.any(find.byIcon(Icons.arrow_back))) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }
  if (tester.any(find.widgetWithText(ActionCard, 'Food library'))) {
    await tester.tap(find.widgetWithText(ActionCard, 'Food library'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Recipes'));
  await tester.pumpAndSettle();
}

Future<void> openLibraryTrainingPlansSection(WidgetTester tester) async {
  if (tester.any(find.byType(NavigationBar)) ||
      tester.any(find.byType(NavigationRail))) {
    await tapRootDestination(tester, 'Library');
    await tester.pumpAndSettle();
  }
  while (!tester.any(find.widgetWithText(ActionCard, 'Training library')) &&
      tester.any(find.byIcon(Icons.arrow_back))) {
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  }
  if (tester.any(find.widgetWithText(ActionCard, 'Training library'))) {
    await tester.tap(find.widgetWithText(ActionCard, 'Training library'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Plans'));
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
  await tapRootDestination(tester, 'Settings');
  await tester.pumpAndSettle();
}

Future<void> openAddFood(WidgetTester tester) async {
  final tooltip = find.byTooltip('Add food');
  if (tester.any(tooltip)) {
    await tester.tap(tooltip);
  } else {
    await tester.tap(find.widgetWithText(FilledButton, 'Add food'));
  }
  await tester.pumpAndSettle();
}

Future<void> openAddRecipe(WidgetTester tester) async {
  final tooltip = find.byTooltip('Add recipe');
  if (tester.any(tooltip)) {
    await tester.tap(tooltip);
  } else {
    await tester.tap(find.widgetWithText(FilledButton, 'Add recipe'));
  }
  await tester.pumpAndSettle();
}

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
      expect(find.textContaining('18'), findsWidgets);
      expect(find.textContaining('0.9'), findsWidgets);
      expect(find.textContaining('0.2'), findsWidgets);
      expect(find.textContaining('3.9'), findsWidgets);
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
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

    expect(find.text('Recipe basics'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('No ingredients yet'), findsOneWidget);
    expect(find.text('Add foods to calculate this recipe.'), findsOneWidget);
    expect(find.text('Add ingredient'), findsOneWidget);

    final nameBottom = tester.getBottomLeft(
      find.bySemanticsLabel('Recipe name'),
    );
    final descriptionTop = tester.getTopLeft(
      find.bySemanticsLabel('Recipe description'),
    );
    expect(descriptionTop.dy - nameBottom.dy, greaterThanOrEqualTo(12));

    final sectionCard = tester.widget<Card>(
      find.ancestor(
        of: find.text('Recipe basics'),
        matching: find.byType(Card),
      ),
    );
    expect(
      sectionCard.color,
      Theme.of(
        tester.element(find.byType(DishForm)),
      ).colorScheme.surfaceContainerLow,
    );
  });

  testWidgets('uses FitApp performance logbook theme', (tester) async {
    await tester.pumpWidget(const FitApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.colorScheme.surface, const Color(0xFFF9F9F9));
    expect(app.theme?.colorScheme.primaryContainer, const Color(0xFFCCFF00));
    expect(app.theme?.colorScheme.surfaceContainerLow, const Color(0xFFF3F3F3));
    expect(app.theme?.colorScheme.onSurface, const Color(0xFF1A1C1C));
    expect(
      app.theme?.outlinedButtonTheme.style?.backgroundColor?.resolve({}),
      Colors.white,
    );

    expect(app.darkTheme?.colorScheme.primary, Colors.white);
    expect(app.darkTheme?.colorScheme.secondary, const Color(0xFFC8C6C5));
    expect(app.darkTheme?.colorScheme.surface, const Color(0xFF121414));
    expect(
      app.darkTheme?.colorScheme.surfaceContainer,
      const Color(0xFF1E2020),
    );
    expect(
      app.darkTheme?.colorScheme.surfaceContainerHigh,
      const Color(0xFF282A2B),
    );
    expect(app.darkTheme?.colorScheme.onSurface, const Color(0xFFE2E2E2));
    expect(
      app.darkTheme?.colorScheme.onSurfaceVariant,
      const Color(0xFFC4C9AC),
    );
    expect(app.darkTheme?.scaffoldBackgroundColor, const Color(0xFF121414));
    expect(
      app.darkTheme?.navigationBarTheme.indicatorColor,
      app.darkTheme?.colorScheme.primaryContainer,
    );
    expect(app.darkTheme?.inputDecorationTheme.filled, isTrue);
    expect(
      app.darkTheme?.cardTheme.color,
      app.darkTheme?.colorScheme.surfaceContainerLow,
    );
    expect(
      app.darkTheme?.outlinedButtonTheme.style?.backgroundColor?.resolve({}),
      Colors.transparent,
    );
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
  });

  testWidgets(
    'MetricCard uses identical typography across light and dark themes',
    (tester) async {
      Future<TextStyle?> pumpMetric(ThemeData theme) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Center(
                child: MetricCard(
                  label: 'Completed',
                  value: '12',
                  suffix: 'sessions',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widget<Text>(find.text('12')).style;
      }

      final lightStyle = await pumpMetric(AppTheme.light());
      final darkStyle = await pumpMetric(AppTheme.dark());

      expect(darkStyle?.fontFamily, lightStyle?.fontFamily);
      expect(darkStyle?.fontSize, lightStyle?.fontSize);
      expect(darkStyle?.fontWeight, lightStyle?.fontWeight);
      expect(darkStyle?.height, lightStyle?.height);
      expect(darkStyle?.letterSpacing, lightStyle?.letterSpacing);
    },
  );

  testWidgets(
    'shared non-color theme primitives stay identical across themes',
    (tester) async {
      expect(
        AppTheme.standardSurfaceRadius(Brightness.light),
        AppTheme.standardSurfaceRadius(Brightness.dark),
      );
      expect(
        AppTheme.ambientShadow(Brightness.dark),
        AppTheme.ambientShadow(Brightness.light),
      );

      Future<EdgeInsetsGeometry?> pumpAdaptivePage(ThemeData theme) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: AdaptivePage(
                children: [SizedBox(height: 24, child: Text('Content'))],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widget<ListView>(find.byType(ListView)).padding;
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lightPadding = await pumpAdaptivePage(AppTheme.light());
      final darkPadding = await pumpAdaptivePage(AppTheme.dark());

      expect(darkPadding, lightPadding);
    },
  );

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
    expect(find.text('Daily progress'), findsWidgets);
    expect(find.text('NEXT WORKOUT'), findsOneWidget);
    expect(find.text('PERFORMANCE INSIGHT'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    await tester.ensureVisible(find.text('Start workout'));
    await tester.pump();

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
    expect(find.text('Active workout'), findsWidgets);
    expect(find.text('Chest day'), findsWidgets);
    expect(find.text('Total volume'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open train tab'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Open train tab'));
    await tester.pump();
    await tester.tap(find.text('Open train tab'));
    await tester.pump();
    expect(trainTapCount, 1);
  });

  testWidgets('Today dashboard stays stable across widths', (tester) async {
    for (final entry in <Size>[const Size(390, 844), const Size(700, 900)]) {
      await pumpAtSurfaceSize(
        tester,
        entry,
        MaterialApp(
          home: TodayScreen(
            store: AppStore(),
            onOpenTrain: () {},
            onOpenNutrition: () {},
            onOpenLibrary: () {},
          ),
        ),
      );

      expect(find.text('Daily progress'), findsWidgets);
      expect(find.text('NEXT WORKOUT'), findsOneWidget);
      expect(find.text('PERFORMANCE INSIGHT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('LibraryScreen switches between training and food libraries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LibraryScreen(store: AppStore())),
    );

    expect(find.text('Library'), findsNWidgets(2));
    expect(
      find.text('Manage plans, exercises, foods, and recipes.'),
      findsOneWidget,
    );
    expect(find.byType(SectionHeader), findsOneWidget);
    expect(find.text('Training library'), findsOneWidget);
    expect(find.text('Food library'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Trainings'), findsNothing);
    expect(find.text('Training plans'), findsNothing);
    expect(find.text('Chest day'), findsNothing);

    await tester.tap(find.text('Food library'));
    await tester.pumpAndSettle();

    expect(find.text('Food library'), findsWidgets);
    expect(find.text('Foods'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    await scrollToText(tester, 'Chicken breast');
    expect(find.text('Chicken breast'), findsOneWidget);
  });

  test('library formatters accept localized labels', () {
    final store = AppStore();
    final food = store.itemById('rice')!;
    final plan = store.trainingPlans.first;
    final exercise = store.exercises.first;

    expect(
      formatCatalogItemTypeLabel(food, foodLabel: 'localized-food'),
      'localized-food',
    );
    expect(
      formatCatalogNutritionServingLabel(
        food,
        store,
        servingLabel: 'localized-serving',
      ),
      '150 g localized-serving',
    );
    expect(
      formatCatalogCaloriesPerServingLabel(
        food,
        store,
        caloriesPerServing: (calories) => '$calories localized-kcal',
      ),
      '195 localized-kcal',
    );
    expect(
      formatTrainingPlanSummaryLabel(
        plan,
        exerciseCountLabel: (count) => '$count localized-exercises',
      ),
      contains('localized-exercises'),
    );
    expect(
      formatExerciseMuscleGroupSummaryLabel(
        exercise.muscleGroups,
        emptyLabel: 'localized-empty',
      ),
      isNot('localized-empty'),
    );
    expect(
      formatExerciseMuscleGroupSummaryLabel(
        const [],
        emptyLabel: 'localized-empty',
      ),
      'localized-empty',
    );
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

      expect(find.text('Daily progress'), findsWidgets);
      expect(find.text('NEXT WORKOUT'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAtSurfaceSize(
        tester,
        size,
        MaterialApp(home: MealScreen(store: AppStore())),
      );

      expect(find.text('Nutrition log'), findsOneWidget);
      expect(find.text('Macro targets'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAtSurfaceSize(
        tester,
        size,
        MaterialApp(home: LibraryScreen(store: AppStore())),
      );

      expect(find.text('Library'), findsNWidgets(2));
      expect(find.text('Training library'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await openLibraryFoodsSection(tester);
      await scrollToText(tester, 'Chicken breast');
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  Future<void> tapAddMealFab(WidgetTester tester) async {
    final action = tester.any(find.byType(FloatingActionButton))
        ? find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.byTooltip('Log food'),
          )
        : find.widgetWithText(FilledButton, 'Log food');
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> tapLogFoodDialogAction(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet).last,
        matching: find.widgetWithText(FilledButton, 'Log food'),
      ),
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

  Future<void> tapRowAction(
    WidgetTester tester,
    String itemName,
    String tooltip,
    IconData icon,
  ) async {
    icon;
    final row = find.ancestor(
      of: find.text(itemName).last,
      matching: find.byType(Card),
    );
    await tester.ensureVisible(row);
    await tester.tap(
      find.descendant(of: row, matching: find.byTooltip('More actions')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(tooltip));
    await tester.pumpAndSettle();
  }

  Future<void> logRice150g(WidgetTester tester) async {
    await openNutritionDestination(tester);
    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Grams'), '150');
    await tapLogFoodDialogAction(tester);
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
    await openLibraryRecipesSection(tester);
    await openAddRecipe(tester);

    await enterLabeledText(tester, 'Recipe name', 'Simple salad');
    await enterLabeledText(tester, 'Recipe description', 'Carrot');
    await enterLabeledText(tester, 'Recipe serving size grams', '100');
    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Ingredient grams', '100');
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows Today, Train, Nutrition, Library and Settings destinations',
    (tester) async {
      await tester.pumpWidget(const FitApp());

      expect(find.text('Today'), findsWidgets);
      expect(find.text('Train'), findsWidgets);
      expect(find.text('Nutrition'), findsWidgets);
      expect(find.text('Library'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Daily progress'), findsWidgets);
      expect(find.text('Chicken breast'), findsNothing);

      await openLibraryDestination(tester);

      expect(find.text('Training library'), findsOneWidget);
      expect(find.text('Food library'), findsOneWidget);

      await openLibraryTrainingPlansSection(tester);

      expect(find.text('Training plans'), findsWidgets);
      expect(find.text('Chest day'), findsOneWidget);

      await openNutritionDestination(tester);

      expect(find.text('Macro targets'), findsOneWidget);

      await openLibraryFoodsSection(tester);

      expect(find.text('Foods'), findsWidgets);
      await scrollToText(tester, 'Chicken breast');
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(find.text('food'), findsWidgets);
    },
  );

  testWidgets('Nutrition shell shows cockpit header and add action', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await openNutritionDestination(tester);

    expect(find.text('Nutrition'), findsWidgets);
    expect(find.text('Nutrition log'), findsOneWidget);
    expect(find.text('Macro targets'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log food'), findsOneWidget);
    expect(find.byTooltip('Log food'), findsOneWidget);
  });

  testWidgets('Nutrition uses one primary add action per responsive mode', (
    tester,
  ) async {
    await pumpAtSurfaceSize(
      tester,
      const Size(390, 844),
      MaterialApp(home: MealScreen(store: AppStore())),
    );

    expect(find.widgetWithText(FilledButton, 'Log food'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Log food'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAtSurfaceSize(
      tester,
      const Size(1024, 768),
      MaterialApp(home: MealScreen(store: AppStore())),
    );

    expect(find.widgetWithText(FilledButton, 'Log food'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Log food'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Settings tab and opens settings screen', (tester) async {
    await tester.pumpWidget(const FitApp());

    expect(find.text('Settings'), findsWidgets);

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

  testWidgets(
    'FitApp can render with a hydrated store supplied from async bootstrap',
    (tester) async {
      final store = AppStore.empty();

      await tester.pumpWidget(FitApp(store: store));

      expect(find.text('Today'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    },
  );

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
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(find.byType(TextField).first, 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicken breast').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Grams'), '200');
    await tapLogFoodDialogAction(tester);

    expect(store.mealEntries, hasLength(1));
    expect(store.dailyTotals.calories, 330);
    expect(store.dailyTotals.protein, 62);
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
        matching: find.text('Log food'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search saved foods and recipes, or create a new food from your query.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Search foods and recipes'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
    expect(find.text('food'), findsOneWidget);
  });

  testWidgets('creates a food from the Food tab', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryFoodsSection(tester);
    await openAddFood(tester);

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
    expect(find.text('Food library'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.textContaining('5.3 oz serving'), findsWidgets);
    expect(find.textContaining('41 kcal per serving'), findsWidgets);
    expect(find.byTooltip('Add food or recipe'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsWidgets);
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
    expect(find.text('Food library'), findsOneWidget);
    expect(find.text('No foods or recipes yet'), findsOneWidget);
    expect(
      find.text('Use Add food or recipe to build your reusable catalog.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Add food or recipe'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('creates a dish from existing foods', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryRecipesSection(tester);
    await openAddRecipe(tester);

    await enterLabeledText(tester, 'Recipe name', 'Simple salad');
    await enterLabeledText(tester, 'Recipe description', 'Carrot and onion');
    await enterLabeledText(tester, 'Recipe serving size grams', '150');
    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Ingredient grams', '100');
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Simple salad');
    expect(find.text('Simple salad'), findsOneWidget);
    expect(find.text('recipe'), findsWidgets);
    expect(find.textContaining('150 g serving'), findsWidgets);
  });

  testWidgets(
    'recipe form calculates serving size from ingredients when empty',
    (tester) async {
      await tester.pumpWidget(const FitApp());

      await openLibraryRecipesSection(tester);
      await openAddRecipe(tester);

      await enterLabeledText(tester, 'Recipe name', 'Auto serving salad');
      await enterLabeledText(tester, 'Recipe description', 'Carrot only');
      await tester.tap(find.text('Add ingredient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carrot').last);
      await tester.pumpAndSettle();
      await enterLabeledText(tester, 'Ingredient grams', '125');
      await tester.tap(find.text('Save ingredient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save recipe'));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Auto serving salad');
      expect(find.text('Auto serving salad'), findsOneWidget);
      expect(find.textContaining('125 g serving'), findsWidgets);
    },
  );

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

    expect(store.mealEntries, hasLength(1));
    expect(store.mealEntries.single.enteredQuantity, 150);
  });

  testWidgets('training plan target labels render pounds in plan editor', (
    tester,
  ) async {
    final store = AppStore();
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    await tester.pumpWidget(FitApp(store: store));
    await openLibraryTrainingPlansSection(tester);

    final chestDayCard = find.ancestor(
      of: find.text('Chest day'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: chestDayCard,
        matching: find.byTooltip('More actions'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Chest day'));
    await tester.pumpAndSettle();

    expect(find.text('132.3 lbs weight'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Weight'), findsNothing);
  });

  testWidgets('creates a missing item from Meal search and logs it', (
    tester,
  ) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Tomato',
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Log food'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Search saved foods and recipes, or create a new food from your query.',
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
    await tapLogFoodDialogAction(tester);

    expect(store.items.any((item) => item.name == 'Tomato'), isTrue);
    expect(store.mealEntries, hasLength(1));
    expect(find.textContaining('18'), findsWidgets);
  });

  testWidgets('logs renamed food created from Meal search', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'tom',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create "tom"'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Name', 'Tomato');
    await fillTomatoNutrition(tester);
    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    expect(store.items.any((item) => item.name == 'Tomato'), isTrue);
    expect(find.widgetWithText(TextField, 'Grams'), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Grams'), '100');
    await tapLogFoodDialogAction(tester);

    expect(store.mealEntries.single.itemName, 'Tomato');
    expect(find.textContaining('18'), findsWidgets);
  });

  testWidgets('does not offer create action for exact Meal search match', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();

    expect(find.text('Create "Rice"'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Rice'), findsOneWidget);
  });

  testWidgets('rejects invalid meal amounts without adding or closing', (
    tester,
  ) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    expect(
      find.text("Choose how much you ate, then add it to today's meal log."),
      findsOneWidget,
    );
    expect(find.text('Grams'), findsWidgets);
    expect(find.text('Servings'), findsOneWidget);

    for (final value in ['abc', '0', '-1', 'NaN', 'Infinity']) {
      await tester.enterText(find.bySemanticsLabel('Grams'), value);
      await tapLogFoodDialogAction(tester);

      expect(tester.takeException(), isNull);
      expect(store.mealEntries, isEmpty);
      expect(find.textContaining('195 kcal'), findsNothing);
    }
  });

  testWidgets('logs an existing meal item by grams', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));

    await logRice150g(tester);

    expect(store.mealEntries, hasLength(1));
    expect(store.mealEntries.single.enteredQuantity, 150);
    expect(find.textContaining('195 kcal'), findsOneWidget);
  });

  testWidgets('removes a logged meal entry from Nutrition screen', (
    tester,
  ) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));

    await logRice150g(tester);

    expect(store.mealEntries, hasLength(1));
    expect(find.textContaining('195 kcal'), findsOneWidget);

    store.removeMealEntry(store.mealEntries.single.id);
    await tester.pumpAndSettle();

    expect(store.mealEntries, isEmpty);
    expect(find.textContaining('195 kcal'), findsNothing);
  });

  testWidgets('logs an existing meal item by servings', (tester) async {
    final store = AppStore();
    await tester.pumpWidget(FitApp(store: store));
    await openNutritionDestination(tester);

    await tapAddMealFab(tester);
    await tester.enterText(
      find.bySemanticsLabel('Search foods and recipes'),
      'Rice',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rice').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Servings'));
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Servings'), '2');
    await tapLogFoodDialogAction(tester);

    expect(store.mealEntries, hasLength(1));
    expect(store.mealEntries.single.enteredQuantity, 2);
    expect(find.textContaining('390 kcal'), findsOneWidget);
  });

  testWidgets('deleting a logged item keeps meal snapshot', (tester) async {
    final store = AppStore();
    store.createFood(
      const FoodItem(
        id: 'custom-rice',
        name: 'Custom rice',
        description: 'User-defined rice',
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
    await tester.pumpWidget(FitApp(store: store));

    store.addMealByGrams(itemId: 'custom-rice', grams: 150);
    await tester.pumpAndSettle();
    expect(store.mealEntries, hasLength(1));
    expect(find.textContaining('195 kcal'), findsOneWidget);

    await openLibraryFoodsSection(tester);
    await scrollToText(tester, 'Custom rice');
    expect(find.text('Custom rice'), findsWidgets);
    await tapRowAction(
      tester,
      'Custom rice',
      'Delete Custom rice',
      Icons.delete_outline,
    );
    expect(find.text('Delete Custom rice?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(store.itemById('custom-rice'), isNull);

    await openNutritionDestination(tester);
    expect(store.mealEntries, hasLength(1));
    expect(find.textContaining('195 kcal'), findsOneWidget);
  });

  testWidgets('blocks deleting an item referenced by a dish', (tester) async {
    final store = AppStore();
    store.createFood(
      const FoodItem(
        id: 'custom-carrot',
        name: 'Custom carrot',
        description: 'User-defined carrot',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(
          calories: 41,
          protein: 0.9,
          fat: 0.2,
          carbs: 10,
        ),
      ),
    );
    store.createDish(
      const DishItem(
        id: 'custom-salad',
        name: 'Custom salad',
        description: 'Uses a custom carrot ingredient',
        servingSizeGrams: 100,
        components: [
          DishComponent(itemId: 'custom-carrot', grams: 100),
        ],
      ),
    );
    await tester.pumpWidget(FitApp(store: store));

    await openLibraryFoodsSection(tester);
    await scrollToText(tester, 'Custom carrot');
    await tapRowAction(
      tester,
      'Custom carrot',
      'Delete Custom carrot',
      Icons.delete_outline,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Custom carrot'), findsOneWidget);
    expect(find.textContaining('used by a recipe'), findsOneWidget);
  });

  testWidgets(
    'editing a food updates catalog but not existing meal snapshots',
    (tester) async {
      final store = AppStore();
      store.createFood(
        const FoodItem(
          id: 'custom-rice',
          name: 'Custom rice',
          description: 'User-defined rice',
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
      await tester.pumpWidget(FitApp(store: store));

      store.addMealByGrams(itemId: 'custom-rice', grams: 150);
      await tester.pumpAndSettle();
      expect(store.mealEntries, hasLength(1));
      expect(find.textContaining('195 kcal'), findsOneWidget);

      store.updateFood(
        const FoodItem(
          id: 'custom-rice',
          name: 'Updated rice',
          description: 'Updated user-defined rice',
          servingSizeGrams: 150,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: 200,
            protein: 2.7,
            fat: 0.3,
            carbs: 28,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(store.itemById('custom-rice')?.name, 'Updated rice');

      await openNutritionDestination(tester);
      expect(store.mealEntries.single.itemName, 'Custom rice');
      expect(find.textContaining('195 kcal'), findsOneWidget);
    },
  );

  testWidgets('editing a dish updates the dish row', (tester) async {
    await tester.pumpWidget(const FitApp());

    await openLibraryRecipesSection(tester);
    await openAddRecipe(tester);

    await enterLabeledText(tester, 'Recipe name', 'Simple salad');
    await enterLabeledText(tester, 'Recipe description', 'Carrot and onion');
    await enterLabeledText(tester, 'Recipe serving size grams', '150');
    await tester.tap(find.text('Add ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrot').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Ingredient grams', '100');
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Simple salad');
    await tapRowAction(
      tester,
      'Simple salad',
      'Edit Simple salad',
      Icons.edit_outlined,
    );
    await enterLabeledText(tester, 'Recipe name', 'Carrot salad');
    await tester.tap(find.text('Save recipe'));
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
    await tester.tap(find.byTooltip('Edit Carrot ingredient'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Ingredient grams', '50');
    await tester.tap(find.text('Save ingredient'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Recipe name', 'Half carrot salad');
    await tester.tap(find.text('Save recipe'));
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

    await tester.tap(find.byTooltip('Edit Carrot ingredient'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '33.33'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save ingredient'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save recipe'));
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
