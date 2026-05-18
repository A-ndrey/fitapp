import 'package:fitapp/screens/trainings_screen.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/core/widgets/empty_state.dart';
import 'package:fitapp/ui/core/widgets/swipe_action_card.dart';
import 'package:fitapp/ui/library/library_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {AppStore? store}) async {
    await tester.pumpWidget(
      MaterialApp(home: TrainingsScreen(store: store ?? AppStore())),
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

  Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: scrollable ?? find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openExercisesView(WidgetTester tester) async {
    await tester.tap(find.text('Exercises').first);
    await tester.pumpAndSettle();
  }

  Future<void> openExerciseForm(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Add exercise'));
    await tester.pumpAndSettle();
  }

  Future<void> openPlanView(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 5000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans').first);
    await tester.pumpAndSettle();
  }

  Finder muscleGroupChip(String label) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is FilterChip &&
          widget.label is Text &&
          (widget.label as Text).data == label,
      description: 'FilterChip("$label")',
    );
  }

  Future<void> fillExerciseForm(
    WidgetTester tester, {
    required String name,
    required String description,
    required String instruction,
    required String muscleGroups,
    String? measurementType,
  }) async {
    await enterLabeledText(tester, 'Exercise name', name);
    await enterLabeledText(tester, 'Exercise description', description);
    await enterLabeledText(tester, 'Exercise instruction', instruction);
    if (measurementType != null) {
      final field = find.byKey(
        const ValueKey('exercise-measurement-type-field'),
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(measurementType).last);
      await tester.pumpAndSettle();
    }
    for (final group in muscleGroups.split(',')) {
      final label = group.trim();
      if (label.isEmpty) {
        continue;
      }
      final chip = muscleGroupChip(label);
      await tester.ensureVisible(chip);
      if (!tester.widget<FilterChip>(chip).selected) {
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
    }
  }

  Future<void> openCatalogActions(WidgetTester tester, String title) async {
    final card = find.ancestor(
      of: find.text(title),
      matching: find.byType(Card),
    );
    final menuButton = find.descendant(
      of: card,
      matching: find.byTooltip('More actions'),
    );
    await tester.ensureVisible(menuButton);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();
  }

  Future<void> revealRowActions(WidgetTester tester, String title) async {
    final tile = find.widgetWithText(ListTile, title).last;
    final card = find
        .ancestor(
      of: tile,
      matching: find.byType(SwipeActionCard),
    )
        .last;
    await tester.ensureVisible(card);
    await tester.drag(card, const Offset(-240, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('lists sample training plans and exposes row actions', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.byType(TrainingPlanCatalogCard), findsNWidgets(2));
    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Leg day'), findsOneWidget);
    expect(find.byTooltip('Add training plan'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsNWidgets(2));
  });

  testWidgets('creates a training plan from predefined exercises', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Training name', 'Push day');
    await enterLabeledText(
      tester,
      'Training description',
      'Bodyweight and pressing work',
    );

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Pushups'), findsWidgets);
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();

    await enterLabeledText(tester, 'Working sets', '4');
    await enterLabeledText(tester, 'Target reps', '12');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('4 sets'), findsOneWidget);

    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('keeps invalid training plan form open and can edit/delete', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Training name'), findsOneWidget);

    await enterLabeledText(tester, 'Training name', 'Push day');
    await enterLabeledText(tester, 'Training description', 'Upper body');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Working sets', '3');
    await enterLabeledText(tester, 'Target reps', '10');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);

    await openCatalogActions(tester, 'Push day');
    await tester.tap(find.text('Edit Push day').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Training name', 'Push day updated');
    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    expect(find.text('Push day updated'), findsOneWidget);

    await openCatalogActions(tester, 'Push day updated');
    await tester.tap(find.text('Delete Push day updated').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Push day updated'), findsNothing);
  });

  testWidgets('switches to exercises view and exposes exercise actions', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);

    expect(
      find.byWidgetPredicate((widget) => widget is SegmentedButton),
      findsOneWidget,
    );
    expect(find.byType(ExerciseCatalogCard), findsWidgets);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.byTooltip('Add exercise'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsWidgets);
  });

  testWidgets('shows shared empty states for empty training catalog', (
    tester,
  ) async {
    await pumpScreen(tester, store: AppStore.empty());

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No training plans yet'), findsOneWidget);

    await openExercisesView(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No exercises yet'), findsOneWidget);
  });

  testWidgets('exercise form uses predefined muscle group choices', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await scrollUntilVisible(tester, find.text('Select muscle groups'));

    expect(find.bySemanticsLabel('Muscle groups'), findsNothing);
    expect(find.byType(FilterChip), findsWidgets);
    expect(muscleGroupChip('Cardio'), findsOneWidget);
    expect(muscleGroupChip('Legs'), findsOneWidget);
    expect(muscleGroupChip('Core'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('exercise-measurement-type-field')),
      findsOneWidget,
    );
  });

  testWidgets('exercise form requires a measurement type selection', (
    tester,
  ) async {
    await pumpScreen(tester, store: AppStore.empty());

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom burpee',
      description: 'Full-body conditioning',
      instruction: 'Drop, jump back, return, and stand tall.',
      muscleGroups: 'Full body, Cardio',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter a name, description, instruction, muscle groups, and measurement type.',
      ),
      findsOneWidget,
    );
    expect(find.text('Add exercise'), findsWidgets);
  });

  testWidgets('selected muscle group chips use readable foreground color', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await scrollUntilVisible(tester, find.text('Select muscle groups'));

    final coreChip = muscleGroupChip('Core');
    await scrollUntilVisible(tester, coreChip);
    await tester.tap(coreChip);
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(coreChip);
    final context = tester.element(coreChip);
    final colorScheme = Theme.of(context).colorScheme;

    expect(chip.selected, isTrue);
    expect(chip.selectedColor, colorScheme.primaryContainer);
    expect(chip.checkmarkColor, colorScheme.onPrimaryContainer);
    expect(chip.labelStyle?.color, colorScheme.onPrimaryContainer);
  });

  testWidgets('exercise and training forms use polished sections', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await scrollUntilVisible(tester, find.text('Select muscle groups'));

    expect(find.text('Exercise profile'), findsOneWidget);
    expect(find.byType(FilterChip), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await openPlanView(tester);
    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();

    expect(find.text('Training basics'), findsOneWidget);
    expect(find.text('Exercise sequence'), findsOneWidget);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();

    expect(find.text('Set targets'), findsOneWidget);
  });

  testWidgets('bodyweight plan entry hides load and duration fields', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pushups').last);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Working sets'), findsOneWidget);
    expect(find.bySemanticsLabel('Target reps'), findsOneWidget);
    expect(find.bySemanticsLabel('Target load'), findsNothing);
    expect(find.bySemanticsLabel('Target duration'), findsNothing);
    expect(find.bySemanticsLabel('Target distance'), findsNothing);
  });

  testWidgets('cardio plan entry shows duration and distance only', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await scrollUntilVisible(
      tester,
      find.text('Running'),
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Working sets'), findsNothing);
    expect(find.bySemanticsLabel('Target reps'), findsNothing);
    expect(find.bySemanticsLabel('Target load'), findsNothing);
    expect(find.bySemanticsLabel('Target duration'), findsOneWidget);
    expect(find.bySemanticsLabel('Target distance'), findsOneWidget);
  });

  testWidgets('plan entry normalizes weight and distance inputs', (
    tester,
  ) async {
    final store = AppStore.empty();
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);
    store.setDistanceUnit(DistanceUnit.miles);
    store.createExercise(
      const Exercise(
        id: 'weighted-plank',
        name: 'Weighted plank',
        description: 'Weighted core hold',
        instruction: 'Brace and hold steady.',
        muscleGroups: [MuscleGroup.core],
        measurementType: ExerciseMeasurementType.weightedDuration,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'custom-run',
        name: 'Custom run',
        description: 'Steady cardio run',
        instruction: 'Keep a steady pace.',
        muscleGroups: [MuscleGroup.cardio],
        measurementType: ExerciseMeasurementType.cardio,
      ),
    );
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Training name', 'Normalization day');

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weighted plank').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Working sets', '3');
    await enterLabeledText(tester, 'Target load', '10');
    await enterLabeledText(tester, 'Target duration', '45');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom run').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Target duration', '600');
    await enterLabeledText(tester, 'Target distance', '3');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    final plan = store.trainingPlans.singleWhere(
      (plan) => plan.id == 'normalization-day',
    );
    expect(plan.exercises.first.weightGrams, closeTo(4535.9237, 0.01));
    expect(plan.exercises.first.durationSeconds, 45);
    expect(plan.exercises.last.distanceMeters, closeTo(4828.032, 0.01));
    expect(plan.exercises.last.durationSeconds, 600);
  });

  testWidgets('cardio plan entry accepts duration-only and distance-only', (
    tester,
  ) async {
    final store = AppStore.empty();
    store.setDistanceUnit(DistanceUnit.miles);
    store.createExercise(
      const Exercise(
        id: 'custom-run',
        name: 'Custom run',
        description: 'Steady cardio run',
        instruction: 'Keep a steady pace.',
        muscleGroups: [MuscleGroup.cardio],
        measurementType: ExerciseMeasurementType.cardio,
      ),
    );
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Training name', 'Cardio options');

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom run').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Target duration', '900');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom run').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Target distance', '2');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save training'));
    await tester.pumpAndSettle();

    final plan = store.trainingPlans.singleWhere(
      (plan) => plan.id == 'cardio-options',
    );
    expect(plan.exercises.first.durationSeconds, 900);
    expect(plan.exercises.first.distanceMeters, isNull);
    expect(plan.exercises.last.durationSeconds, isNull);
    expect(plan.exercises.last.distanceMeters, closeTo(3218.688, 0.01));
  });

  testWidgets('plan entry rejects non-positive and fractional targets', (
    tester,
  ) async {
    final store = AppStore.empty();
    store.createExercise(
      const Exercise(
        id: 'custom-pushups',
        name: 'Custom pushups',
        description: 'User-defined horizontal press',
        instruction: 'Press away from the floor.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    await pumpScreen(tester, store: store);

    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom pushups').last);
    await tester.pumpAndSettle();
    await enterLabeledText(tester, 'Working sets', '0.5');
    await enterLabeledText(tester, 'Target reps', '0');
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Enter valid sets and reps.'), findsOneWidget);
    expect(find.text('Set targets'), findsOneWidget);
  });

  testWidgets('creates a custom exercise and shows it in the plan picker', (
    tester,
  ) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom burpee',
      description: 'Full-body conditioning',
      instruction: 'Drop, jump back, return, and stand tall.',
      muscleGroups: 'Full body, Cardio',
      measurementType: 'Cardio',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.text('Custom burpee'));
    expect(find.text('Custom burpee'), findsOneWidget);
    expect(find.text('Full body, Cardio'), findsOneWidget);

    await openPlanView(tester);
    await tester.tap(find.byTooltip('Add training plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(
      tester,
      find.text('Custom burpee'),
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Custom burpee'), findsOneWidget);
  });

  testWidgets('keeps exercise form open when name cannot create an id', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: '---',
      description: 'Invalid generated id',
      instruction: 'This should stay open.',
      muscleGroups: 'Core',
      measurementType: 'Duration',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Add exercise'), findsWidgets);
    expect(find.text('Enter a valid exercise name.'), findsOneWidget);
  });

  testWidgets('edits a custom exercise', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom plank',
      description: 'Static core hold',
      instruction: 'Brace and hold a straight line.',
      muscleGroups: 'Core',
      measurementType: 'Duration',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.text('Custom plank'));
    await openCatalogActions(tester, 'Custom plank');
    await tester.tap(find.text('Edit Custom plank').last);
    await tester.pumpAndSettle();
    await fillExerciseForm(
      tester,
      name: 'Custom plank',
      description: 'Updated core hold',
      instruction: 'Keep ribs down and hips level.',
      muscleGroups: 'Core, Glutes',
      measurementType: 'Duration',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Updated core hold'), findsOneWidget);
    expect(find.text('Core, Glutes'), findsOneWidget);
  });

  testWidgets('deletes an unused custom exercise', (tester) async {
    final store = AppStore();
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await openExerciseForm(tester);
    await fillExerciseForm(
      tester,
      name: 'Custom bridge',
      description: 'Posterior chain work',
      instruction: 'Drive hips up and squeeze glutes.',
      muscleGroups: 'Glutes, Hamstrings',
      measurementType: 'Bodyweight',
    );
    await tester.tap(find.text('Save exercise'));
    await tester.pumpAndSettle();

    await scrollUntilVisible(tester, find.text('Custom bridge'));
    await openCatalogActions(tester, 'Custom bridge');
    await tester.tap(find.text('Delete Custom bridge').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Custom bridge'), findsNothing);
  });

  testWidgets('blocks deleting a custom exercise used by a plan', (
    tester,
  ) async {
    final store = AppStore();
    store.createExercise(
      const Exercise(
        id: 'custom-pushups',
        name: 'Custom pushups',
        description: 'User-defined horizontal press',
        instruction: 'Press away from the floor.',
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'custom-push-day',
        name: 'Custom push day',
        description: 'Uses a custom exercise',
        exercises: [
          TrainingExercise(exerciseId: 'custom-pushups', sets: 3, reps: 12),
        ],
      ),
    );
    await pumpScreen(tester, store: store);

    await openExercisesView(tester);
    await scrollUntilVisible(tester, find.text('Custom pushups'));
    await openCatalogActions(tester, 'Custom pushups');
    await tester.tap(find.text('Delete Custom pushups').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Exercise is used by a training plan.'), findsOneWidget);
    expect(find.text('Custom pushups'), findsOneWidget);
  });

  testWidgets(
    'plan editor exercise rows reveal swipe actions on compact layouts',
    (tester) async {
      final store = AppStore();
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpScreen(tester, store: store);

      await tester.tap(find.byTooltip('Add training plan'));
      await tester.pumpAndSettle();
      await enterLabeledText(tester, 'Training name', 'Push day');
      await enterLabeledText(tester, 'Training description', 'Upper body');
      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pushups').last);
      await tester.pumpAndSettle();
      await enterLabeledText(tester, 'Working sets', '3');
      await enterLabeledText(tester, 'Target reps', '10');
      await tester.tap(find.text('Save exercise'));
      await tester.pumpAndSettle();

      await revealRowActions(tester, 'Pushups');

      expect(find.byKey(const ValueKey('swipe-action-Edit')), findsOneWidget);
      expect(find.byKey(const ValueKey('swipe-action-Remove')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('swipe-action-Remove')));
      await tester.pumpAndSettle();

      expect(find.text('3 sets'), findsNothing);
    },
  );

  testWidgets(
    'exercise measurement type is locked after workout history exists',
    (tester) async {
      final store = AppStore.empty();
      store.createExercise(
        const Exercise(
          id: 'custom-pushups',
          name: 'Custom pushups',
          description: 'User-defined horizontal press',
          instruction: 'Press away from the floor.',
          muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
          measurementType: ExerciseMeasurementType.bodyweight,
        ),
      );
      store.createTrainingPlan(
        const TrainingPlan(
          id: 'custom-push-day',
          name: 'Custom push day',
          description: 'Uses a custom exercise',
          exercises: [
            TrainingExercise(exerciseId: 'custom-pushups', sets: 3, reps: 12),
          ],
        ),
      );
      store.startWorkout(trainingPlanId: 'custom-push-day');
      store.finishActiveWorkout();

      await pumpScreen(tester, store: store);

      await openExercisesView(tester);
      await scrollUntilVisible(tester, find.text('Custom pushups'));
      await openCatalogActions(tester, 'Custom pushups');
      await tester.tap(find.text('Edit Custom pushups').last);
      await tester.pumpAndSettle();

      final field = tester
          .widget<DropdownButtonFormField<ExerciseMeasurementType>>(
            find.byType(DropdownButtonFormField<ExerciseMeasurementType>),
          );

      expect(field.onChanged, isNull);
      expect(
        find.text(
          'Measurement type can no longer change because workout history exists.',
        ),
        findsOneWidget,
      );
    },
  );
}
