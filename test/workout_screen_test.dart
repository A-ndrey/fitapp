import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/screens/workout_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/workout/workout_detail_cards.dart';
import 'package:fitapp/ui/workout/workout_formatters.dart';
import 'package:fitapp/ui/workout/workout_overview_cards.dart';
import 'package:fitapp/ui/workout/workout_session_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workout formatters render compact duration and date labels', () {
    expect(formatWorkoutDuration(Duration.zero), '0 min');
    expect(formatWorkoutDuration(const Duration(minutes: 12)), '12 min');
    expect(
      formatWorkoutDuration(const Duration(hours: 1, minutes: 5)),
      '1 h 5 min',
    );
    expect(formatWorkoutDate(DateTime(2026, 4, 25)), '2026-04-25');
  });

  test('workout formatters render numbers and pluralized set counts', () {
    expect(formatWorkoutNumber(8), '8');
    expect(formatWorkoutNumber(8.5), '8.5');
    expect(formatWorkoutSetCount(1), '1 set logged');
    expect(formatWorkoutSetCount(3), '3 sets logged');
  });

  test('workout formatters render target labels', () {
    const weightedTarget = TrainingExercise(
      exerciseId: 'bench-press',
      sets: 3,
      reps: 8,
      weight: 60,
      unit: 'kg',
    );
    final store = AppStore();

    expect(
      formatWorkoutTarget(weightedTarget, store),
      'Target: 3 sets • 8 reps • 60 kg',
    );

    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    expect(formatWorkoutTarget(weightedTarget, store), contains('132.3 lbs'));
    expect(
      formatWorkoutTarget(
        const TrainingExercise(exerciseId: 'running', time: 15, unit: 'min'),
        store,
      ),
      'Target: 15 min',
    );
    expect(
      formatWorkoutTarget(
        const TrainingExercise(exerciseId: 'pushups', unit: 'reps'),
        store,
      ),
      'Target: reps',
    );
  });

  test('workout formatters render set logs and input numbers', () {
    const target = TrainingExercise(
      exerciseId: 'bench-press',
      sets: 3,
      reps: 8,
      weight: 60,
      unit: 'kg',
    );
    final store = AppStore();

    expect(
      formatWorkoutSetLog(
        target,
        const WorkoutSetLog(reps: 8, weight: 62.5),
        store,
      ),
      '8 reps • 62.5 kg',
    );

    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    expect(
      formatWorkoutSetLog(
        target,
        const WorkoutSetLog(reps: 8, weight: 62.5),
        store,
      ),
      '8 reps • 137.8 lbs',
    );
    expect(formatWorkoutInputNumber(null), '');
    expect(formatWorkoutInputNumber(8), '8');
    expect(formatWorkoutInputNumber(62.5), '62.5');
  });

  test('workout formatters accept localized label fragments', () {
    const target = TrainingExercise(
      exerciseId: 'bench-press',
      sets: 3,
      reps: 8,
      weight: 60,
      unit: 'kg',
    );
    final store = AppStore();

    expect(
      formatWorkoutSetCount(
        2,
        setCountLoggedLabel: (count) => '$count localized-sets-logged',
      ),
      '2 localized-sets-logged',
    );
    expect(
      formatWorkoutTarget(
        target,
        store,
        targetPrefix: 'Localized target:',
        setsLabel: 'localized-sets',
        repsLabel: 'localized-reps',
      ),
      'Localized target: 3 localized-sets • 8 localized-reps • 60 kg',
    );
    expect(
      formatWorkoutSetLog(
        target,
        const WorkoutSetLog(reps: 8, weight: 62.5),
        store,
        repsLabel: 'localized-reps',
      ),
      '8 localized-reps • 62.5 kg',
    );
  });

  Future<void> pumpWorkoutScreen(WidgetTester tester, {AppStore? store}) async {
    await tester.pumpWidget(
      MaterialApp(home: WorkoutScreen(store: store ?? AppStore())),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openStartWorkoutPicker(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Start workout'));
    await tester.pumpAndSettle();
  }

  Future<void> openActiveWorkout(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open active workout'));
    await tester.pumpAndSettle();
  }

  Future<void> openCompletedWorkout(
    WidgetTester tester,
    String workoutName,
  ) async {
    final tooltip = find.byTooltip('Open completed $workoutName');
    if (!tester.any(tooltip)) {
      await tester.scrollUntilVisible(
        tooltip,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
    }
    if (tester.any(tooltip)) {
      await tester.tap(tooltip.first);
      await tester.pumpAndSettle();
      return;
    }

    final historyTile = find.ancestor(
      of: find.text(workoutName),
      matching: find.byType(ListTile),
    );
    if (tester.any(historyTile)) {
      await tester.ensureVisible(historyTile.first);
      await tester.pumpAndSettle();
      await tester.tap(historyTile.first);
      await tester.pumpAndSettle();
      return;
    }

    final title = find.text(workoutName).first;
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
  }

  const rootDestinationLabels = [
    'Today',
    'Train',
    'Nutrition',
    'Library',
    'More',
  ];

  Future<void> openRootDestination(
    WidgetTester tester,
    String destination,
  ) async {
    if (tester.any(find.byType(NavigationBar))) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(destination),
            )
            .last,
      );
      await tester.pumpAndSettle();
      return;
    }

    final index = rootDestinationLabels.indexOf(destination);
    if (index == -1) {
      throw ArgumentError.value(
        destination,
        'destination',
        'Unknown root destination',
      );
    }
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    rail.onDestinationSelected?.call(index);
    await tester.pumpAndSettle();
  }

  Future<void> openTrainDestination(WidgetTester tester) async {
    await openRootDestination(tester, 'Train');
  }

  Future<void> openExercise(WidgetTester tester, String exerciseName) async {
    await tester.tap(find.byTooltip('Open $exerciseName'));
    await tester.pumpAndSettle();
  }

  Future<void> finishWorkoutFromSession(WidgetTester tester) async {
    final finishButton = find.text('Finish workout');
    await tester.ensureVisible(finishButton);
    await tester.pumpAndSettle();
    await tester.tap(finishButton);
    await tester.pumpAndSettle();
  }

  Future<void> enterWorkoutSet(
    WidgetTester tester, {
    required String reps,
    required String weight,
    required String time,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Reps'), reps);
    await tester.enterText(find.bySemanticsLabel('Weight'), weight);
    await tester.enterText(find.bySemanticsLabel('Time'), time);
    await tester.pumpAndSettle();
  }

  void finishChestWorkoutWithBenchSet(
    AppStore store, {
    required DateTime startedAt,
    required DateTime finishedAt,
    double reps = 8,
    double weight = 62.5,
  }) {
    store.startWorkout(trainingPlanId: 'chest-day', startedAt: startedAt);
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: WorkoutSetLog(reps: reps, weight: weight),
    );
    store.finishActiveWorkout(finishedAt: finishedAt);
  }

  void createRepeatPushupsPlan(AppStore store) {
    store.createExercise(
      const Exercise(
        id: 'pushups',
        name: 'Pushups',
        description: 'Bodyweight push exercise',
        instruction: 'Keep a straight line from shoulders to heels.',
        muscleGroups: [MuscleGroup.chest],
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'repeat-pushups',
        name: 'Repeat pushups',
        description: 'Same exercise twice',
        exercises: [
          TrainingExercise(exerciseId: 'pushups', reps: 10, unit: 'reps'),
          TrainingExercise(exerciseId: 'pushups', reps: 8, unit: 'reps'),
        ],
      ),
    );
  }

  void finishRepeatPushupsWorkout(AppStore store) {
    store.startWorkout(
      trainingPlanId: 'repeat-pushups',
      startedAt: DateTime(2026, 4, 18, 9),
    );
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 10),
    );
    store.addActiveWorkoutSet(
      resultIndex: 1,
      setLog: const WorkoutSetLog(reps: 8),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 18, 9, 30));
  }

  testWidgets('workout overview cards render active and history content', (
    tester,
  ) async {
    final store = AppStore();
    final active = store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );
    store.finishActiveWorkout(finishedAt: DateTime(2026, 4, 19, 10, 45));
    final completed = store.completedWorkoutSessions.single;
    final secondStore = AppStore();
    final secondActive = secondStore.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 20, 10),
    );

    var openedActive = false;
    var openedHistory = false;
    var deletedHistory = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ActiveWorkoutCard(
                session: secondActive.copyWith(startedAt: active.startedAt),
                onOpen: () => openedActive = true,
              ),
              WorkoutHistoryCard(
                session: completed,
                onOpen: () => openedHistory = true,
                onDelete: () => deletedHistory = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active workout'), findsOneWidget);
    expect(find.text('Chest day'), findsWidgets);
    expect(
      find.ancestor(
        of: find.byTooltip('Delete completed Chest day'),
        matching: find.byTooltip('Open completed Chest day'),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Open active workout'));
    await tester.pumpAndSettle();
    await openCompletedWorkout(tester, 'Chest day');
    await tester.tap(find.byTooltip('Delete completed Chest day'));
    await tester.pumpAndSettle();

    expect(openedActive, isTrue);
    expect(openedHistory, isTrue);
    expect(deletedHistory, isTrue);
  });

  testWidgets('workout session cards render header and exercise progress', (
    tester,
  ) async {
    final store = AppStore();
    final session = store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 25, 10),
    );
    final result = session.results.first;

    var openedExercise = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WorkoutSessionHeaderCard(session: session),
              WorkoutExerciseProgressCard(
                exerciseLabel: result.exerciseName,
                targetLabel: formatWorkoutTarget(result.target, store),
                setCountLabel: formatWorkoutSetCount(result.setLogs.length),
                tooltip: 'Open Bench press',
                onOpen: () => openedExercise = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Session cockpit'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Target: 3 sets • 8 reps • 60 kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Bench press'));
    await tester.pumpAndSettle();

    expect(openedExercise, isTrue);
  });

  testWidgets('workout detail cards render active exercise and log callbacks', (
    tester,
  ) async {
    final store = AppStore();
    final session = store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 25, 10),
    );
    final result = session.results.first.copyWith(
      setLogs: const [WorkoutSetLog(reps: 8, weight: 62.5)],
    );
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final timeController = TextEditingController();
    var logged = false;
    WorkoutSetLog? filledSet;

    addTearDown(repsController.dispose);
    addTearDown(weightController.dispose);
    addTearDown(timeController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WorkoutActiveExerciseSummaryCard(result: result, store: store),
              WorkoutSetInputCard(
                repsController: repsController,
                weightController: weightController,
                timeController: timeController,
                target: result.target,
                onLogSet: () => logged = true,
              ),
              WorkoutLoggedSetsCard(
                target: result.target,
                setLogs: result.setLogs,
                store: store,
                onFillSet: (setLog) => filledSet = setLog,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Target: 3 sets • 8 reps • 60 kg'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Logged sets'), findsOneWidget);
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('8 reps • 62.5 kg'), findsOneWidget);

    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Use Set 1'));
    await tester.pumpAndSettle();

    expect(logged, isTrue);
    expect(filledSet?.weight, 62.5);
  });

  testWidgets('workout set input card wraps fields at narrow widths', (
    tester,
  ) async {
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final timeController = TextEditingController();

    addTearDown(repsController.dispose);
    addTearDown(weightController.dispose);
    addTearDown(timeController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: WorkoutSetInputCard(
              repsController: repsController,
              weightController: weightController,
              timeController: timeController,
              target: const TrainingExercise(
                exerciseId: 'bench-press',
                weight: 60,
                unit: 'kg',
              ),
              onLogSet: () {},
            ),
          ),
        ),
      ),
    );

    final fieldSizes = tester
        .renderObjectList<RenderBox>(find.byType(TextField))
        .map((box) => box.size.width)
        .toList();

    expect(fieldSizes, everyElement(200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout detail cards render previous and completed groups', (
    tester,
  ) async {
    final store = AppStore.empty();
    createRepeatPushupsPlan(store);
    finishRepeatPushupsWorkout(store);
    final session = store.completedWorkoutSessions.single;
    final history = store.completedWorkoutHistoryForExercise('pushups');
    WorkoutSetLog? filledSet;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WorkoutPreviousResultsCard(
                history: history,
                store: store,
                onFillSet: (setLog) => filledSet = setLog,
              ),
              WorkoutCompletedSummaryCard(session: session),
              WorkoutCompletedExerciseResultGroupCard(
                exerciseName: 'Pushups',
                results: session.results,
                store: store,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Previous results'), findsOneWidget);
    expect(find.text('Repeat pushups • 2026-04-18 • 30 min'), findsOneWidget);
    expect(find.text('Completed workout'), findsOneWidget);
    expect(find.text('Date: 2026-04-18'), findsOneWidget);
    expect(find.text('Duration: 30 min'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.text('Entry 2'), findsOneWidget);

    await tester.tap(
      find.byTooltip('Use previous Entry 2 Set 1 from Repeat pushups'),
    );
    await tester.pumpAndSettle();

    expect(filledSet?.reps, 8);
  });

  testWidgets('workout exercise progress card handles narrow long targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: WorkoutExerciseProgressCard(
              exerciseLabel: 'Single-leg Romanian deadlift',
              targetLabel:
                  'Target: 4 sets • 12 reps • 123456789.5 kg tempo controlled',
              setCountLabel: '0 sets logged',
              tooltip: 'Open Single-leg Romanian deadlift',
              onOpen: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Single-leg Romanian deadlift'), findsOneWidget);
    expect(
      find.text('Target: 4 sets • 12 reps • 123456789.5 kg tempo controlled'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout overview stats grid renders optional latest content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: WorkoutStatsGrid(
              completedCount: 2,
              totalDuration: Duration(hours: 1, minutes: 15),
              latestSessionName: 'Chest day',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('sessions'), findsOneWidget);
    expect(find.text('Total time'), findsOneWidget);
    expect(find.text('1 h 15 min'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: WorkoutStatsGrid(
              completedCount: 0,
              totalDuration: Duration.zero,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('sessions'), findsOneWidget);
    expect(find.text('Total time'), findsOneWidget);
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('Latest'), findsNothing);
    expect(find.text('Chest day'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows workout stats and opens the plan picker', (tester) async {
    await pumpWorkoutScreen(tester);

    expect(find.text('Training cockpit'), findsOneWidget);
    expect(
      find.text('Start, resume, and review workout sessions.'),
      findsOneWidget,
    );
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('No completed sessions yet.'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Total time'), findsOneWidget);
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('No completed workouts yet'), findsOneWidget);
    expect(
      find.text('Start a training plan to build your workout history.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Start workout'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);

    await openStartWorkoutPicker(tester);

    expect(find.text('Start workout'), findsWidgets);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Leg day'), findsOneWidget);
  });

  testWidgets('opens workout session immediately after starting a workout', (
    tester,
  ) async {
    final store = AppStore();
    await pumpWorkoutScreen(tester, store: store);

    await openStartWorkoutPicker(tester);
    await tester.tap(find.text('Chest day'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession?.trainingPlanName, 'Chest day');
    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Session cockpit'), findsOneWidget);
    expect(find.text('Exercise queue'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });

  testWidgets('active session card opens the workout session screen', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);

    expect(find.text('Active workout'), findsOneWidget);
    expect(find.text('Workout session'), findsNothing);

    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Session cockpit'), findsOneWidget);
    expect(find.text('Exercise queue'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });

  testWidgets('exercise rows open the workout exercise screen', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();
    await openTrainDestination(tester);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    expect(find.text('Workout exercise'), findsWidgets);
    expect(find.text('Log sets and reuse recent performance.'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Log set'), findsOneWidget);
  });

  testWidgets('logging a set clears fields and shows the logged set', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    await enterWorkoutSet(tester, reps: '8', weight: '65', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.textContaining('8'), findsWidgets);
    expect(find.textContaining('65'), findsWidgets);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    final repsField = fields[0];
    final weightField = fields[1];
    final timeField = fields[2];

    expect(repsField.controller?.text, isEmpty);
    expect(weightField.controller?.text, isEmpty);
    expect(timeField.controller?.text, isEmpty);

    await tester.tap(find.byTooltip('Use Set 1'));
    await tester.pumpAndSettle();

    expect(repsField.controller?.text, '8');
    expect(weightField.controller?.text, '65');
    expect(timeField.controller?.text, isEmpty);
  });

  testWidgets('multiple set logs accumulate', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    await enterWorkoutSet(tester, reps: '8', weight: '65', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    await enterWorkoutSet(tester, reps: '6', weight: '67.5', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(2));
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Set 2'), findsOneWidget);
  });

  testWidgets('workout displays render pounds when weight unit is pounds', (
    tester,
  ) async {
    final store = AppStore();
    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);

    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);

    await openExercise(tester, 'Bench press');
    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);

    await enterWorkoutSet(tester, reps: '8', weight: '62.5', time: '');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(find.text('8 reps • 137.8 lbs'), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[1].controller?.text, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await finishWorkoutFromSession(tester);

    await openCompletedWorkout(tester, 'Chest day');

    expect(find.text('Target: 3 sets • 8 reps • 132.3 lbs'), findsOneWidget);
    expect(find.text('8 reps • 137.8 lbs'), findsOneWidget);
  });

  testWidgets('finishing from session screen returns to workout overview', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);

    await finishWorkoutFromSession(tester);

    expect(store.activeWorkoutSession, isNull);
    expect(find.text('Workout session'), findsNothing);
    expect(find.text('Active workout'), findsNothing);
    expect(find.text('Training cockpit'), findsOneWidget);
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Latest: Chest day'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
  });

  testWidgets('finishes active session after switching tabs', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();
    await openTrainDestination(tester);

    expect(find.text('Active workout'), findsOneWidget);

    await openRootDestination(tester, 'Library');

    expect(find.text('Training plans'), findsOneWidget);
    expect(find.text('Active workout'), findsNothing);

    await openTrainDestination(tester);
    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);

    await finishWorkoutFromSession(tester);

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions, hasLength(1));
    expect(find.text('Workout session'), findsNothing);
    expect(find.text('Training cockpit'), findsOneWidget);
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Latest: Chest day'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    'history card opens completed workout details under workout tab',
    (tester) async {
      final store = AppStore();
      finishChestWorkoutWithBenchSet(
        store,
        startedAt: DateTime(2026, 4, 18, 9),
        finishedAt: DateTime(2026, 4, 18, 9, 45),
      );

      await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
      await tester.pumpAndSettle();
      await openTrainDestination(tester);

      await openCompletedWorkout(tester, 'Chest day');

      expect(find.byType(AdaptivePage), findsOneWidget);
      expect(find.text('Completed workout'), findsWidgets);
      expect(find.text('Chest day'), findsOneWidget);
      expect(find.text('Date: 2026-04-18'), findsOneWidget);
      expect(find.text('Duration: 45 min'), findsOneWidget);
      expect(find.textContaining('Started:'), findsNothing);
      expect(find.textContaining('Finished:'), findsNothing);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('8 reps • 62.5 kg'), findsOneWidget);
      expect(find.text('Train'), findsWidgets);
      expect(find.text('Library'), findsWidgets);
    },
  );

  testWidgets('workout history shows started date and can delete records', (
    tester,
  ) async {
    final store = AppStore();
    finishChestWorkoutWithBenchSet(
      store,
      startedAt: DateTime(2026, 4, 18, 9),
      finishedAt: DateTime(2026, 4, 18, 9, 45),
    );

    await pumpWorkoutScreen(tester, store: store);

    expect(find.text('2026-04-18 • 45 min'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete completed Chest day'));
    await tester.pumpAndSettle();

    expect(find.text('Delete workout?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(store.completedWorkoutSessions, isEmpty);
    expect(find.text('No completed workouts yet'), findsOneWidget);
    expect(find.text('2026-04-18 • 45 min'), findsNothing);
  });

  testWidgets('completed workout details group repeated exercises', (
    tester,
  ) async {
    final store = AppStore.empty();
    createRepeatPushupsPlan(store);
    finishRepeatPushupsWorkout(store);

    await pumpWorkoutScreen(tester, store: store);

    await openCompletedWorkout(tester, 'Repeat pushups');

    expect(find.text('Completed workout'), findsWidgets);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.text('Entry 2'), findsOneWidget);
    expect(find.text('10 reps'), findsWidgets);
    expect(find.text('8 reps'), findsWidgets);
  });

  testWidgets('previous exercise results refill active set form', (
    tester,
  ) async {
    final store = AppStore();
    finishChestWorkoutWithBenchSet(
      store,
      startedAt: DateTime(2026, 4, 18, 9),
      finishedAt: DateTime(2026, 4, 18, 9, 45),
    );
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -560));
    await tester.pumpAndSettle();

    expect(find.text('Previous results'), findsOneWidget);
    expect(find.text('Chest day • 2026-04-18 • 45 min'), findsOneWidget);
    expect(find.text('8 reps • 62.5 kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Use previous Set 1 from Chest day'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 560));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '8');
    expect(fields[1].controller?.text, '62.5');
    expect(fields[2].controller?.text, isEmpty);

    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs,
      hasLength(1),
    );
  });

  testWidgets('previous repeated exercise results use distinct refill rows', (
    tester,
  ) async {
    final store = AppStore.empty();
    createRepeatPushupsPlan(store);
    finishRepeatPushupsWorkout(store);
    store.startWorkout(
      trainingPlanId: 'repeat-pushups',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    expect(find.text('Pushups (1)'), findsOneWidget);
    expect(find.text('Pushups (2)'), findsOneWidget);
    expect(find.byTooltip('Open Pushups entry 1'), findsOneWidget);
    expect(find.byTooltip('Open Pushups entry 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Pushups entry 1'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -560));
    await tester.pumpAndSettle();

    expect(find.text('Entry 1 • Set 1'), findsOneWidget);
    expect(find.text('Entry 2 • Set 1'), findsOneWidget);

    final secondPreviousSet = find.byTooltip(
      'Use previous Entry 2 Set 1 from Repeat pushups',
    );
    await tester.ensureVisible(secondPreviousSet);
    await tester.pumpAndSettle();
    await tester.tap(secondPreviousSet);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 560));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '8');
    expect(fields[1].controller?.text, isEmpty);
    expect(fields[2].controller?.text, isEmpty);
  });

  testWidgets('keeps workout tab visible on session and exercise screens', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: FitHome(store: store)));
    await tester.pumpAndSettle();
    await openTrainDestination(tester);

    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);
    expect(find.text('Train'), findsWidgets);
    expect(find.text('Nutrition'), findsWidgets);
    expect(find.text('Library'), findsWidgets);

    await openExercise(tester, 'Bench press');

    expect(find.text('Workout exercise'), findsWidgets);
    expect(find.text('Train'), findsWidgets);
    expect(find.text('Library'), findsWidgets);

    await openRootDestination(tester, 'Library');

    expect(find.text('Training plans'), findsOneWidget);

    await openTrainDestination(tester);

    expect(find.text('Workout exercise'), findsWidgets);
    expect(find.text('Bench press'), findsOneWidget);
  });
}
