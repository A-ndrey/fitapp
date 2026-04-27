import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/core/widgets/action_card.dart';
import 'package:fitapp/ui/core/widgets/empty_state.dart';
import 'package:fitapp/ui/core/widgets/form_shell.dart';
import 'package:fitapp/ui/core/widgets/metric_card.dart';
import 'package:fitapp/ui/core/widgets/section_header.dart';
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

  testWidgets('adaptive page applies compact and medium page padding', (
    tester,
  ) async {
    for (final entry in <({double width, EdgeInsets padding})>[
      (
        width: 390,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
      (
        width: 700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

  testWidgets('adaptive page centers content within max width on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AdaptivePage(children: [Text('Desktop content')])),
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

    expect(constrainedBox.constraints.maxWidth, 1120);
    expect(find.text('Desktop content'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    final food = CatalogItem.food(
      const FoodItem(
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
    final plan = TrainingPlan(
      id: 'upper',
      name: 'Upper',
      description: 'Strength focus',
      exercises: const [
        TrainingExercise(exerciseId: 'pushups', reps: 12, unit: 'reps'),
        TrainingExercise(exerciseId: 'rows', reps: 10, unit: 'reps'),
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
    expect(formatTrainingPlanSummaryLabel(plan), '2 exercises\nStrength focus');
    expect(
      formatTrainingPlanSummaryLabel(
        plan.copyWith(
          description: '',
          exercises: const [
            TrainingExercise(exerciseId: 'pushups', reps: 12, unit: 'reps'),
          ],
        ),
      ),
      '1 exercise',
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
  });

  testWidgets('library cards render labels and invoke action callbacks', (
    tester,
  ) async {
    var edited = <String>[];
    var deleted = <String>[];
    final store = AppStore.empty();
    final food = CatalogItem.food(
      const FoodItem(
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
    final plan = TrainingPlan(
      id: 'upper',
      name: 'Upper body',
      description: 'Strength focus',
      exercises: const [
        TrainingExercise(exerciseId: 'pushups', reps: 12, unit: 'reps'),
      ],
    );
    const exercise = Exercise(
      id: 'pushups',
      name: 'Pushups',
      description: 'Bodyweight push exercise',
      instruction: 'Keep your core tight.',
      muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
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
    expect(find.text('food'), findsOneWidget);
    expect(find.text('150 g serving • 195 kcal per serving'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Upper body'), findsOneWidget);
    expect(find.text('1 exercise\nStrength focus'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Pushups'), findsOneWidget);
    expect(find.text('Bodyweight push exercise'), findsOneWidget);
    expect(find.text('Keep your core tight.'), findsOneWidget);
    expect(find.text('Chest, Triceps'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit Rice bowl'));
    await tester.tap(find.byTooltip('Delete Upper body'));
    await tester.tap(find.byTooltip('Edit Pushups'));
    await tester.pumpAndSettle();

    expect(edited, ['rice', 'pushups']);
    expect(deleted, ['upper']);
  });

  testWidgets('library cards do not overflow in narrow layouts', (
    tester,
  ) async {
    final store = AppStore.empty();
    final food = CatalogItem.food(
      const FoodItem(
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
    final plan = TrainingPlan(
      id: 'very-long-plan',
      name: 'A very long training plan name that should stay bounded',
      description: 'A long description that remains inside the card bounds',
      exercises: const [
        TrainingExercise(exerciseId: 'pushups', reps: 12, unit: 'reps'),
        TrainingExercise(exerciseId: 'rows', reps: 10, unit: 'reps'),
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
}
