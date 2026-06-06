import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/core/layout/responsive_layout.dart';
import 'package:fitapp/ui/core/widgets/action_card.dart';
import 'package:fitapp/ui/core/widgets/empty_state.dart';
import 'package:fitapp/ui/core/widgets/form_shell.dart';
import 'package:fitapp/ui/core/widgets/metric_card.dart';
import 'package:fitapp/ui/core/widgets/section_header.dart';
import 'package:fitapp/ui/core/widgets/swipe_action_card.dart';
import 'package:fitapp/ui/library/library_cards.dart';
import 'package:fitapp/ui/library/library_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('core widgets render expected content', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptivePage(
            children: [
              const SectionHeader(title: 'Dashboard', subtitle: 'Today'),
              const MetricCard(
                label: 'Calories',
                value: '620',
                suffix: 'kcal',
                icon: Icons.local_fire_department_outlined,
              ),
              ActionCard(
                title: 'Log meal',
                subtitle: 'Add food quickly',
                icon: Icons.add,
                tooltip: 'Log meal action',
                onTap: () {
                  tapped = true;
                },
              ),
              const AppEmptyState(
                icon: Icons.flag_outlined,
                title: 'No sessions yet',
                message: 'Start a workout to see progress here.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('620'), findsOneWidget);
    expect(find.text('kcal'), findsOneWidget);
    expect(find.text('Log meal'), findsOneWidget);
    expect(find.text('Add food quickly'), findsOneWidget);
    expect(find.byTooltip('Log meal action'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.text('Start a workout to see progress here.'), findsOneWidget);

    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('adaptive page applies fluid responsive page padding', (
    tester,
  ) async {
    for (final entry in <({double width, EdgeInsets padding})>[
      (
        width: 390,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
      (
        width: 700,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      ),
      (
        width: 1440,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      ),
    ]) {
      await tester.binding.setSurfaceSize(Size(entry.width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptivePage(children: [Text('Responsive content')]),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, entry.padding);
      expect(find.text('Responsive content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('responsive page max width preserves medium window space', () {
    expect(responsivePageMaxWidth(390), 390);
    expect(responsivePageMaxWidth(800), 800);
    expect(responsivePageMaxWidth(1280), 1280);
    expect(responsivePageMaxWidth(1281), 1280);
    expect(responsivePageMaxWidth(1440), 1280);
  });

  testWidgets(
    'adaptive page centers content within fluid max width on desktop',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdaptivePage(children: [Text('Desktop content')]),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(Center),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );

      expect(constrainedBox.constraints.maxWidth, 1280);
      expect(find.text('Desktop content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('responsive item width is derived from available space', () {
    expect(
      responsiveItemWidth(maxWidth: 390, maxItemExtent: 260, spacing: 12),
      390,
    );
    expect(
      responsiveItemWidth(maxWidth: 700, maxItemExtent: 260, spacing: 12),
      closeTo(225.333, 0.001),
    );
    expect(
      responsiveItemWidth(maxWidth: 1000, maxItemExtent: 260, spacing: 12),
      241,
    );
  });

  test('responsive item width preserves minimum usable card width', () {
    expect(
      responsiveItemWidth(maxWidth: 320, maxItemExtent: 260, spacing: 12),
      320,
    );
    expect(
      responsiveItemWidth(
        maxWidth: 390,
        maxItemExtent: 360,
        minItemExtent: 300,
        spacing: 12,
      ),
      390,
    );
    expect(
      responsiveItemWidth(
        maxWidth: 700,
        maxItemExtent: 360,
        minItemExtent: 300,
        spacing: 12,
      ),
      344,
    );
  });

  testWidgets('responsive wrap sizes children from parent constraints', (
    tester,
  ) async {
    for (final entry in <({double width, double itemWidth})>[
      (width: 390, itemWidth: 390),
      (width: 700, itemWidth: 225.333),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: entry.width,
                child: const ResponsiveWrap(
                  maxItemExtent: 260,
                  spacing: 12,
                  children: [
                    Placeholder(key: Key('responsive-item-1')),
                    Placeholder(key: Key('responsive-item-2')),
                    Placeholder(key: Key('responsive-item-3')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('responsive-item-1'))).width,
        closeTo(entry.itemWidth, 0.001),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('metric card does not overflow with long value and suffix', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: MetricCard(
                label: 'Calories',
                value: '12345678901234567890',
                suffix: 'kilocalories-consumed-today',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('section header bounds wide trailing content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: SectionHeader(
                title: 'Dashboard',
                subtitle: 'Today',
                trailing: SizedBox(width: 600, child: Text('Very wide action')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('library formatters preserve catalog summary behavior', (
    tester,
  ) async {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep your core tight.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'rows',
        name: 'Rows',
        description: 'Row variation',
        instruction: 'Pull to your torso.',
        muscleGroups: [MuscleGroup.back],
        measurementType: ExerciseMeasurementType.strength,
      ),
    );
    const food = CatalogItem.food(
      FoodItem(
        id: 'rice',
        name: 'Rice',
        description: 'Steamed',
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
    const plan = TrainingPlan(
      id: 'upper',
      name: 'Upper',
      description: 'Strength focus',
      exercises: [
        TrainingExercise(exerciseId: 'pushups', sets: 3, reps: 12),
        TrainingExercise(
          exerciseId: 'rows',
          sets: 4,
          reps: 10,
          weightGrams: 30000,
        ),
      ],
    );

    expect(formatCatalogItemTypeLabel(food), 'food');
    expect(formatCatalogNutritionServingLabel(food, store), '150 g serving');
    expect(
      formatCatalogCaloriesPerServingLabel(food, store),
      '195 kcal per serving',
    );
    expect(
      formatCatalogServingNutritionLabel(food, store),
      '150 g serving • 195 kcal per serving',
    );
    expect(
      formatTrainingPlanSummaryLabel(plan, store: store),
      '2 exercises • 3 sets • 12 reps\nStrength focus',
    );
    expect(
      formatTrainingPlanSummaryLabel(
        plan.copyWith(
          description: '',
          exercises: const [
            TrainingExercise(exerciseId: 'pushups', sets: 3, reps: 12),
          ],
        ),
        store: store,
      ),
      '1 exercise • 3 sets • 12 reps',
    );
    expect(formatExerciseMuscleGroupSummaryLabel(const []), 'Muscles: -');
    expect(
      formatExerciseMuscleGroupSummaryLabel(const [
        MuscleGroup.chest,
        MuscleGroup.triceps,
      ]),
      'Chest, Triceps',
    );
    expect(formatLibraryCountLabel(2, 'exercise'), '2 exercises');
    expect(
      formatTrainingPlanSummaryLabel(
        const TrainingPlan(
          id: 'run-day',
          name: 'Run day',
          description: '',
          exercises: [
            TrainingExercise(
              exerciseId: 'rows',
              sets: 4,
              reps: 10,
              weightGrams: 30000,
            ),
          ],
        ),
        store: store,
      ),
      '1 exercise • 4 sets • 10 reps • 30 kg',
    );
  });

  testWidgets('library cards render labels and invoke action callbacks', (
    tester,
  ) async {
    final edited = <String>[];
    final deleted = <String>[];
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep your core tight.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    const food = CatalogItem.food(
      FoodItem(
        id: 'rice',
        name: 'Rice bowl',
        description: 'Steamed',
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
    const plan = TrainingPlan(
      id: 'upper',
      name: 'Upper body',
      description: 'Strength focus',
      exercises: [TrainingExercise(exerciseId: 'pushups', sets: 3, reps: 12)],
    );
    const exercise = Exercise(
      id: 'pushups',
      name: 'Pushups',
      description: 'Bodyweight push exercise',
      instruction: 'Keep your core tight.',
      muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      measurementType: ExerciseMeasurementType.bodyweight,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              FoodCatalogCard(
                item: food,
                store: store,
                onEdit: () => edited.add(food.id),
                onDelete: () => deleted.add(food.id),
              ),
              TrainingPlanCatalogCard(
                plan: plan,
                store: store,
                onEdit: () => edited.add(plan.id),
                onDelete: () => deleted.add(plan.id),
              ),
              ExerciseCatalogCard(
                exercise: exercise,
                onEdit: () => edited.add(exercise.id),
                onDelete: () => deleted.add(exercise.id),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.widgetWithText(ListTile, 'Rice bowl'), findsOneWidget);
    expect(find.text('Type'), findsWidgets);
    expect(find.text('food'), findsOneWidget);
    expect(find.text('Serving'), findsWidgets);
    expect(find.text('150 g serving'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('195 kcal per serving'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Upper body'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('First target'), findsOneWidget);
    expect(find.text('3 sets • 12 reps'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Strength focus'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Pushups'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Bodyweight push exercise'), findsOneWidget);
    expect(find.text('Instruction'), findsOneWidget);
    expect(find.text('Keep your core tight.'), findsOneWidget);
    expect(find.text('Muscles'), findsOneWidget);
    expect(find.text('Chest, Triceps'), findsOneWidget);

    Future<void> selectCardAction(String title, String actionLabel) async {
      final card = find.ancestor(
        of: find.text(title),
        matching: find.byType(Card),
      );
      final menuButton = find.descendant(
        of: card,
        matching: find.byTooltip('More actions'),
      );
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text(actionLabel).last);
      await tester.pumpAndSettle();
    }

    await selectCardAction('Rice bowl', 'Edit Rice bowl');
    await selectCardAction('Upper body', 'Delete Upper body');
    await selectCardAction('Pushups', 'Edit Pushups');

    expect(edited, ['rice', 'pushups']);
    expect(deleted, ['upper']);
  });

  testWidgets('library cards do not overflow in narrow layouts', (
    tester,
  ) async {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep your core tight.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'rows',
        name: 'Rows',
        description: 'Row variation',
        instruction: 'Pull to your torso.',
        muscleGroups: [MuscleGroup.back],
        measurementType: ExerciseMeasurementType.strength,
      ),
    );
    const food = CatalogItem.food(
      FoodItem(
        id: 'very-long-food',
        name: 'A very long catalog food name that should stay bounded',
        description: 'Dense food',
        servingSizeGrams: 1234,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(
          calories: 9876.5,
          protein: 100,
          fat: 50,
          carbs: 200,
        ),
      ),
    );
    const plan = TrainingPlan(
      id: 'very-long-plan',
      name: 'A very long training plan name that should stay bounded',
      description: 'A long description that remains inside the card bounds',
      exercises: [
        TrainingExercise(exerciseId: 'pushups', sets: 3, reps: 12),
        TrainingExercise(
          exerciseId: 'rows',
          sets: 4,
          reps: 10,
          weightGrams: 30000,
        ),
      ],
    );
    const exercise = Exercise(
      id: 'very-long-exercise',
      name: 'A very long exercise name that should stay bounded',
      description: 'A long movement description that remains bounded',
      instruction: 'A long instruction that remains inside the narrow card.',
      muscleGroups: [
        MuscleGroup.chest,
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
      ],
      measurementType: ExerciseMeasurementType.strength,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: ListView(
                children: [
                  FoodCatalogCard(
                    item: food,
                    store: store,
                    onEdit: () {},
                    onDelete: () {},
                  ),
                  TrainingPlanCatalogCard(
                    plan: plan,
                    store: store,
                    onEdit: () {},
                    onDelete: () {},
                  ),
                  ExerciseCatalogCard(
                    exercise: exercise,
                    onEdit: () {},
                    onDelete: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('library cards reveal swipe actions on compact layouts', (
    tester,
  ) async {
    final store = AppStore.empty();
    const food = CatalogItem.food(
      FoodItem(
        id: 'rice',
        name: 'Rice bowl',
        description: 'Cooked rice',
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
    var edited = false;
    var deleted = false;

    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              FoodCatalogCard(
                item: food,
                store: store,
                onEdit: () => edited = true,
                onDelete: () => deleted = true,
              ),
            ],
          ),
        ),
      ),
    );

    final card = find.ancestor(
      of: find.text('Rice bowl'),
      matching: find.byType(Card),
    );
    await tester.drag(card, const Offset(-240, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('swipe-action-Edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('swipe-action-Delete')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('swipe-action-Edit')));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
    expect(deleted, isFalse);
  });

  testWidgets('form shell primitives render content and actions', (
    tester,
  ) async {
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormShellDialog(
            title: 'Food item',
            subtitle: 'Build reusable nutrition data.',
            primaryActionLabel: 'Save food',
            onPrimaryAction: () => saved = true,
            children: const [
              FormSectionCard(
                title: 'Food basics',
                subtitle: 'Name and serving information.',
                child: Text('Basics body'),
              ),
              InlineErrorBanner(message: 'Enter valid values.'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Food item'), findsOneWidget);
    expect(find.text('Build reusable nutrition data.'), findsOneWidget);
    expect(find.text('Food basics'), findsOneWidget);
    expect(find.text('Name and serving information.'), findsOneWidget);
    expect(find.text('Basics body'), findsOneWidget);
    expect(find.text('Enter valid values.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save food'), findsOneWidget);

    await tester.tap(find.text('Save food'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
  });

  testWidgets('form shell page uses shared page spacing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FormShellPage(
          title: 'Food item',
          primaryActionLabel: 'Save',
          onPrimaryAction: () {},
          children: const [Text('Form body')],
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(
      listView.padding,
      const EdgeInsets.fromLTRB(
        AppPageSpacing.horizontalMin,
        AppPageSpacing.sectionGap,
        AppPageSpacing.horizontalMin,
        AppPageSpacing.sectionGap,
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SafeArea &&
            widget.minimum ==
                const EdgeInsets.fromLTRB(
                  AppPageSpacing.horizontalMin,
                  AppPageSpacing.compactGap,
                  AppPageSpacing.horizontalMin,
                  AppPageSpacing.horizontalMin,
                ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('form shell exposes dialog title as route semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormShellDialog(
            title: 'Training plan',
            primaryActionLabel: 'Save training',
            onPrimaryAction: () {},
            children: const [Text('Plan body')],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(FormShellDialog)),
      matchesSemantics(
        label: 'Training plan',
        scopesRoute: true,
        namesRoute: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('responsive form grid stays bounded across widths', (
    tester,
  ) async {
    for (final width in <double>[390, 900]) {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResponsiveFormGrid(
                children: [
                  TextField(decoration: InputDecoration(labelText: 'Calories')),
                  TextField(decoration: InputDecoration(labelText: 'Protein')),
                  TextField(decoration: InputDecoration(labelText: 'Fat')),
                  TextField(decoration: InputDecoration(labelText: 'Carbs')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Calories'), findsOneWidget);
      expect(find.bySemanticsLabel('Carbs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('swipe action card preserves card surface edge treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeActionCard(
            actions: [
              SwipeCardAction(
                label: 'Delete',
                icon: Icons.delete_outline,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: () {},
              ),
            ],
            child: const Card(child: ListTile(title: Text('Border test'))),
          ),
        ),
      ),
    );

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(SwipeActionCard),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.clipBehavior, Clip.none);

    final card = find.byType(Card);
    expect(
      find.ancestor(of: card, matching: find.byType(ClipRRect)),
      findsNothing,
    );
  });

  testWidgets('swipe action card paints actions behind the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeActionCard(
            actions: [
              SwipeCardAction(
                label: 'Delete',
                icon: Icons.delete_outline,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: () {},
              ),
            ],
            child: const Card(child: ListTile(title: Text('Layer test'))),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Card), const Offset(-120, 0));
    await tester.pumpAndSettle();

    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(SwipeActionCard),
        matching: find.byType(Stack),
      ),
    );

    expect(stack.children.first, isA<Positioned>());
    expect(stack.children.last, isA<ClipRect>());
  });

  testWidgets('swipe action card keeps full-size action content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeActionCard(
            actions: [
              SwipeCardAction(
                label: 'Delete',
                icon: Icons.delete_outline,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: () {},
              ),
            ],
            child: const Card(child: ListTile(title: Text('Sizing test'))),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Card), const Offset(-120, 0));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
    final label = tester.widget<Text>(find.text('Delete'));

    expect(icon.size, isNull);
    expect(label.style?.fontSize, isNull);
  });

  testWidgets('swipe action buttons match item height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeActionCard(
            actions: [
              SwipeCardAction(
                label: 'Delete',
                icon: Icons.delete_outline,
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onPressed: () {},
              ),
            ],
            child: const Card(child: ListTile(title: Text('Height test'))),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Card), const Offset(-120, 0));
    await tester.pumpAndSettle();

    final cardHeight = tester.getSize(find.byType(Card)).height;
    final actionHeight = tester
        .getSize(find.byKey(const ValueKey('swipe-action-Delete')))
        .height;

    expect(actionHeight, cardHeight);
  });
}
