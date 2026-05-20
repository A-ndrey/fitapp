import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/screens/workout_screen.dart';
import 'package:fitapp/ui/core/layout/app_breakpoints.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:fitapp/ui/core/widgets/swipe_action_card.dart';
import 'package:fitapp/ui/workout/workout_detail_cards.dart';
import 'package:fitapp/ui/workout/workout_formatters.dart';
import 'package:fitapp/ui/workout/workout_overview_cards.dart';
import 'package:fitapp/ui/workout/workout_session_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestFitHome extends StatefulWidget {
  const TestFitHome({super.key, required this.store});

  final AppStore store;

  @override
  State<TestFitHome> createState() => _TestFitHomeState();
}

class _TestFitHomeState extends State<TestFitHome> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    const destinations = [
      NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
      NavigationDestination(
        icon: Icon(Icons.fitness_center_outlined),
        label: 'Train',
      ),
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        label: 'Nutrition',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Library',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];
    final pages = [
      _tabNavigator(0, const _PlaceholderScreen(title: 'Today')),
      _tabNavigator(
        1,
        WorkoutScreen(store: widget.store, isCurrentTab: _selectedIndex == 1),
      ),
      _tabNavigator(2, const _PlaceholderScreen(title: 'Nutrition')),
      _tabNavigator(3, const _PlaceholderScreen(title: 'Training library')),
      _tabNavigator(4, const _PlaceholderScreen(title: 'Settings')),
    ];

    if (isCompact) {
      return Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          destinations: destinations,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            destinations: destinations
                .map(
                  (destination) => NavigationRailDestination(
                    icon: destination.icon,
                    label: Text(destination.label),
                  ),
                )
                .toList(),
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(child: pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _tabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(builder: (_) => child);
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SizedBox.shrink(),
    );
  }
}

void main() {
  test('workout formatters render compact duration and date labels', () {
    expect(formatWorkoutDuration(Duration.zero), '0 min');
    expect(formatWorkoutDuration(const Duration(minutes: 12)), '12 min');
    expect(
      formatWorkoutDuration(const Duration(hours: 1, minutes: 5)),
      '1 h 5 min',
    );
    expect(
      formatWorkoutDuration(
        const Duration(hours: 1, minutes: 5),
        hourUnit: 'hr-local',
        minuteUnit: 'min-local',
      ),
      '1 hr-local 5 min-local',
    );
    expect(formatWorkoutDate(DateTime(2026, 4, 25)), '2026-04-25');
    expect(
      formatWorkoutTimestamp(DateTime(2026, 4, 25, 9, 5)),
      '2026-04-25 09:05',
    );
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
      weightGrams: 60000,
    );
    final store = AppStore();

    expect(
      formatWorkoutTarget(
        weightedTarget,
        ExerciseMeasurementType.strength,
        store,
      ),
      'Target: 3 sets • 8 reps • 60 kg',
    );

    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    expect(
      formatWorkoutTarget(
        weightedTarget,
        ExerciseMeasurementType.strength,
        store,
      ),
      contains('132.3 lbs'),
    );
    expect(
      formatWorkoutTarget(
        const TrainingExercise(exerciseId: 'running', durationSeconds: 900),
        ExerciseMeasurementType.duration,
        store,
      ),
      'Target: 15 min',
    );
    expect(
      formatWorkoutTarget(
        const TrainingExercise(
          exerciseId: 'rowing',
          durationSeconds: 1200,
          distanceMeters: 5000,
        ),
        ExerciseMeasurementType.cardio,
        store,
      ),
      'Target: 20 min • 5 km',
    );
    expect(
      formatWorkoutTarget(
        const TrainingExercise(
          exerciseId: 'assisted-pullup',
          sets: 3,
          reps: 10,
          assistanceWeightGrams: 25000,
        ),
        ExerciseMeasurementType.assisted,
        store,
      ),
      'Target: 3 sets • 10 reps • 55.1 lbs assistance',
    );
    expect(
      formatWorkoutTarget(
        const TrainingExercise(exerciseId: 'pushups', reps: 12),
        ExerciseMeasurementType.bodyweight,
        store,
      ),
      'Target: 12 reps',
    );
  });

  test('workout formatters render set logs and input numbers', () {
    final store = AppStore();

    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(reps: 8, weightGrams: 62500),
        ExerciseMeasurementType.strength,
        store,
      ),
      '8 reps • 62.5 kg',
    );
    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(durationSeconds: 95),
        ExerciseMeasurementType.duration,
        store,
      ),
      '1 min 35 sec',
    );
    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(durationSeconds: 600, distanceMeters: 1609.344),
        ExerciseMeasurementType.cardio,
        store,
      ),
      '10 min • 1.6 km',
    );

    store.setWorkoutWeightUnit(WorkoutWeightUnit.pounds);

    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(reps: 8, weightGrams: 62500),
        ExerciseMeasurementType.strength,
        store,
      ),
      '8 reps • 137.8 lbs',
    );
    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(reps: 6, assistanceWeightGrams: 20000),
        ExerciseMeasurementType.assisted,
        store,
      ),
      '6 reps • 44.1 lbs assistance',
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
      weightGrams: 60000,
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
        ExerciseMeasurementType.strength,
        store,
        targetPrefix: 'Localized target:',
        setsLabel: 'localized-sets',
        repsLabel: 'localized-reps',
      ),
      'Localized target: 3 localized-sets • 8 localized-reps • 60 kg',
    );
    expect(
      formatWorkoutSetLog(
        const WorkoutSetLog(reps: 8, weightGrams: 62500),
        ExerciseMeasurementType.strength,
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
    if (tester.any(tooltip)) {
      await tester.ensureVisible(tooltip.first);
      await tester.pumpAndSettle();
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

  Future<void> tapVisibleTooltip(
    WidgetTester tester,
    String tooltipLabel,
  ) async {
    final tooltip = find.byTooltip(tooltipLabel);
    await tester.ensureVisible(tooltip.first);
    await tester.pumpAndSettle();
    await tester.tap(tooltip.first);
    await tester.pumpAndSettle();
  }

  const rootDestinationLabels = [
    'Today',
    'Train',
    'Nutrition',
    'Library',
    'Settings',
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
    final tooltip = find.byTooltip('Open $exerciseName');
    await tester.ensureVisible(tooltip);
    await tester.pumpAndSettle();
    await tester.tap(tooltip);
    await tester.pumpAndSettle();
  }

  Future<void> finishWorkoutFromSession(WidgetTester tester) async {
    final finishButton = find.text('Finish workout');
    await tester.ensureVisible(finishButton);
    await tester.pumpAndSettle();
    await tester.tap(finishButton);
    await tester.pumpAndSettle();
  }

  Future<void> revealHistoryRowActions(
    WidgetTester tester,
    String title,
  ) async {
    final tile = find.widgetWithText(ListTile, title).last;
    final card = find
        .ancestor(of: tile, matching: find.byType(SwipeActionCard))
        .last;
    await tester.ensureVisible(card);
    await tester.drag(card, const Offset(-240, 0));
    await tester.pumpAndSettle();
  }

  Future<void> enterWorkoutSet(
    WidgetTester tester, {
    String? reps,
    String? weight,
    String? duration,
    String? distance,
    String? assistanceWeight,
  }) async {
    if (reps != null) {
      await tester.enterText(find.bySemanticsLabel('Reps'), reps);
    }
    if (weight != null) {
      await tester.enterText(
        find.bySemanticsLabel(RegExp(r'^Weight,')),
        weight,
      );
    }
    if (duration != null) {
      await tester.enterText(
        find.bySemanticsLabel(RegExp(r'^Duration,')),
        duration,
      );
    }
    if (distance != null) {
      await tester.enterText(
        find.bySemanticsLabel(RegExp(r'^Distance,')),
        distance,
      );
    }
    if (assistanceWeight != null) {
      await tester.enterText(
        find.bySemanticsLabel(RegExp(r'^Assistance weight,')),
        assistanceWeight,
      );
    }
    await tester.ensureVisible(find.text('Log set'));
    await tester.pumpAndSettle();
  }

  void finishChestWorkoutWithBenchSet(
    AppStore store, {
    required DateTime startedAt,
    required DateTime finishedAt,
    double reps = 8,
    double weightKg = 62.5,
  }) {
    store.startWorkout(trainingPlanId: 'chest-day', startedAt: startedAt);
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: WorkoutSetLog(
        reps: reps,
        weightGrams: (weightKg * 1000).roundToDouble(),
      ),
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
        measurementType: ExerciseMeasurementType.bodyweight,
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'repeat-pushups',
        name: 'Repeat pushups',
        description: 'Same exercise twice',
        exercises: [
          TrainingExercise(exerciseId: 'pushups', reps: 10),
          TrainingExercise(exerciseId: 'pushups', reps: 8),
        ],
      ),
    );
  }

  void createWorkoutTypePlans(AppStore store) {
    store.createExercise(
      const Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Hold a straight plank.',
        instruction: 'Brace and hold.',
        muscleGroups: [MuscleGroup.core],
        measurementType: ExerciseMeasurementType.duration,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'sled-push',
        name: 'Sled push',
        description: 'Push the sled.',
        instruction: 'Drive forward under control.',
        muscleGroups: [MuscleGroup.legs],
        measurementType: ExerciseMeasurementType.weightedDuration,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'run',
        name: 'Run',
        description: 'Steady run.',
        instruction: 'Maintain pace.',
        muscleGroups: [MuscleGroup.cardio],
        measurementType: ExerciseMeasurementType.cardio,
      ),
    );
    store.createExercise(
      const Exercise(
        id: 'assisted-pullup',
        name: 'Assisted pull-up',
        description: 'Band-assisted pull-up.',
        instruction: 'Pull to the bar.',
        muscleGroups: [MuscleGroup.back],
        measurementType: ExerciseMeasurementType.assisted,
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'typed-workout',
        name: 'Typed workout',
        description: 'Mixed measurement types',
        exercises: [
          TrainingExercise(exerciseId: 'plank', sets: 3, durationSeconds: 90),
          TrainingExercise(
            exerciseId: 'sled-push',
            sets: 4,
            weightGrams: 45000,
            durationSeconds: 40,
          ),
          TrainingExercise(
            exerciseId: 'run',
            durationSeconds: 1200,
            distanceMeters: 5000,
          ),
          TrainingExercise(
            exerciseId: 'assisted-pullup',
            sets: 3,
            reps: 8,
            assistanceWeightGrams: 25000,
          ),
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
    await tapVisibleTooltip(tester, 'Delete completed Chest day');

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
              WorkoutSessionHeaderCard(session: session, store: store),
              WorkoutExerciseProgressCard(
                exerciseLabel: result.exerciseName,
                targetLabel: formatWorkoutTarget(
                  result.target,
                  ExerciseMeasurementType.strength,
                  store,
                ),
                setCountLabel: formatWorkoutSetCount(result.setLogs.length),
                tooltip: 'Open Bench press',
                onOpen: () => openedExercise = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active session'), findsOneWidget);
    expect(find.text('Chest day'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Target: 3 sets • 8 reps • 60 kg'), findsOneWidget);
    expect(find.text('Logged sets 0'), findsOneWidget);

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
      setLogs: const [WorkoutSetLog(reps: 8, weightGrams: 62500)],
    );
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final durationController = TextEditingController();
    final distanceController = TextEditingController();
    final assistanceWeightController = TextEditingController();
    var logged = false;
    WorkoutSetLog? filledSet;

    addTearDown(repsController.dispose);
    addTearDown(weightController.dispose);
    addTearDown(durationController.dispose);
    addTearDown(distanceController.dispose);
    addTearDown(assistanceWeightController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              WorkoutActiveExerciseSummaryCard(result: result, store: store),
              WorkoutSetInputCard(
                target: result.target,
                repsController: repsController,
                weightController: weightController,
                durationController: durationController,
                distanceController: distanceController,
                assistanceWeightController: assistanceWeightController,
                measurementType: ExerciseMeasurementType.strength,
                store: store,
                onLogSet: () => logged = true,
              ),
              WorkoutExerciseHistoryCard(
                measurementType: ExerciseMeasurementType.strength,
                currentSession: session,
                currentResult: result,
                history: const [],
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
    expect(find.text('Weight, kg'), findsOneWidget);
    expect(find.text('Time'), findsNothing);
    expect(find.text('Fast set logging'), findsNothing);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('#1 • 8 reps • 62.5 kg'), findsOneWidget);

    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#1 • 8 reps • 62.5 kg'));
    await tester.pumpAndSettle();

    expect(logged, isTrue);
    expect(filledSet?.weightGrams, 62500);
  });

  testWidgets('workout set input card renders target above fields without card', (
    tester,
  ) async {
    final store = AppStore();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final durationController = TextEditingController();
    final distanceController = TextEditingController();
    final assistanceWeightController = TextEditingController();

    addTearDown(repsController.dispose);
    addTearDown(weightController.dispose);
    addTearDown(durationController.dispose);
    addTearDown(distanceController.dispose);
    addTearDown(assistanceWeightController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutSetInputCard(
            target: const TrainingExercise(
              exerciseId: 'bench-press',
              sets: 3,
              reps: 8,
              weightGrams: 60000,
            ),
            repsController: repsController,
            weightController: weightController,
            durationController: durationController,
            distanceController: distanceController,
            assistanceWeightController: assistanceWeightController,
            measurementType: ExerciseMeasurementType.strength,
            store: store,
            onLogSet: () {},
          ),
        ),
      ),
    );

    final targetText = find.text('3 sets • 8 reps • 60 kg');
    final repsField = find.bySemanticsLabel('Reps');

    expect(targetText, findsOneWidget);
    expect(repsField, findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkoutSetInputCard),
        matching: find.byType(Card),
      ),
      findsNothing,
    );
    expect(
      tester.getTopLeft(targetText).dy,
      lessThan(tester.getTopLeft(repsField).dy),
    );
  });

  testWidgets('workout set input card wraps fields at narrow widths', (
    tester,
  ) async {
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final durationController = TextEditingController();
    final distanceController = TextEditingController();
    final assistanceWeightController = TextEditingController();

    addTearDown(repsController.dispose);
    addTearDown(weightController.dispose);
    addTearDown(durationController.dispose);
    addTearDown(distanceController.dispose);
    addTearDown(assistanceWeightController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: WorkoutSetInputCard(
              target: const TrainingExercise(
                exerciseId: 'bench-press',
                sets: 3,
                reps: 8,
                weightGrams: 60000,
              ),
              repsController: repsController,
              weightController: weightController,
              durationController: durationController,
              distanceController: distanceController,
              assistanceWeightController: assistanceWeightController,
              measurementType: ExerciseMeasurementType.strength,
              store: AppStore(),
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

    expect(fieldSizes, everyElement(240));
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout exercise screen expands and collapses long instruction', (
    tester,
  ) async {
    final store = AppStore.empty();
    const instruction =
        'Set your shoulders, plant the feet, lower the bar with control, '
        'pause briefly on the chest, press vertically, and keep the wrists '
        'stacked over the forearms for the full rep.';
    store.createExercise(
      const Exercise(
        id: 'long-bench',
        name: 'Long bench',
        description: 'Short description',
        instruction: instruction,
        muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
        measurementType: ExerciseMeasurementType.strength,
      ),
    );
    store.createTrainingPlan(
      const TrainingPlan(
        id: 'long-bench-plan',
        name: 'Long bench plan',
        description: 'Bench work',
        exercises: [
          TrainingExercise(
            exerciseId: 'long-bench',
            sets: 3,
            reps: 8,
            weightGrams: 60000,
          ),
        ],
      ),
    );
    store.startWorkout(
      trainingPlanId: 'long-bench-plan',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Long bench');

    expect(find.text('Short description'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('Show less'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == instruction &&
            widget.maxLines == 3,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == instruction &&
            widget.maxLines == null,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('Show more'), findsOneWidget);
  });

  testWidgets('workout detail cards render history and completed groups', (
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
              WorkoutExerciseHistoryCard(
                measurementType: ExerciseMeasurementType.bodyweight,
                currentSession: session,
                currentResult: session.results.first,
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

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Repeat pushups • 2026-04-18 09:00'), findsNWidgets(2));
    expect(find.text('Completed workout'), findsOneWidget);
    expect(find.text('Date: 2026-04-18'), findsOneWidget);
    expect(find.text('Duration: 30 min'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
    expect(find.text('Entry 1'), findsOneWidget);
    expect(find.text('Entry 2'), findsOneWidget);
    expect(find.text('#1 • 8 reps'), findsWidgets);
    expect(find.text('#1 • 10 reps'), findsWidgets);

    await tester.tap(find.text('#1 • 8 reps').first);
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
    expect(find.text('Latest'), findsNothing);
    expect(find.text('Chest day'), findsNothing);
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

  testWidgets(
    'shows workout stats and uses a persistent FAB to open the plan picker',
    (tester) async {
      await pumpWorkoutScreen(tester);

      expect(find.text('Training log'), findsOneWidget);
      expect(
        find.text('Start sessions, log sets, and review progress.'),
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
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Start workout'), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'Start workout'),
        findsOneWidget,
      );
      expect(
        find.text('Choose a training plan and begin tracking sets.'),
        findsNothing,
      );

      await openStartWorkoutPicker(tester);

      expect(find.text('Start workout'), findsWidgets);
      expect(find.text('Chest day'), findsOneWidget);
      expect(find.text('Leg day'), findsOneWidget);
    },
  );

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
    expect(find.text('Active session'), findsOneWidget);
    expect(find.text('Exercise queue'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Pushups'), findsOneWidget);
  });

  testWidgets(
    'active session shows a persistent FAB that opens the workout session screen',
    (tester) async {
      final store = AppStore();
      store.startWorkout(
        trainingPlanId: 'chest-day',
        startedAt: DateTime(2026, 4, 19, 10),
      );

      await pumpWorkoutScreen(tester, store: store);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Open active workout'), findsOneWidget);
      expect(
        find.widgetWithText(FloatingActionButton, 'Open active workout'),
        findsOneWidget,
      );
      expect(find.text('Active workout'), findsOneWidget);
      expect(find.text('Workout session'), findsNothing);

      await openActiveWorkout(tester);

      expect(find.text('Workout session'), findsOneWidget);
      expect(find.text('Active session'), findsOneWidget);
      expect(find.text('Exercise queue'), findsOneWidget);
      expect(find.text('Chest day'), findsOneWidget);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.text('Pushups'), findsOneWidget);
    },
  );

  testWidgets('exercise rows open the workout exercise screen', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: TestFitHome(store: store)));
    await tester.pumpAndSettle();
    await openTrainDestination(tester);
    await openActiveWorkout(tester);
    await openExercise(tester, 'Bench press');

    expect(find.text('Workout exercise'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('3 sets • 8 reps • 60 kg'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight, kg'), findsOneWidget);
    expect(find.text('Time'), findsNothing);
    expect(find.text('Log set'), findsOneWidget);
    expect(find.text('Fast set logging'), findsNothing);
  });

  testWidgets('exercise logging fields are typed by measurement', (
    tester,
  ) async {
    final store = AppStore.empty();
    createWorkoutTypePlans(store);
    store.startWorkout(
      trainingPlanId: 'typed-workout',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await pumpWorkoutScreen(tester, store: store);
    await openActiveWorkout(tester);

    expect(find.text('Target: 3 sets • 1 min 30 sec'), findsOneWidget);
    expect(find.text('Target: 4 sets • 45 kg • 40 sec'), findsOneWidget);
    expect(find.text('Logged sets 0'), findsOneWidget);

    await openExercise(tester, 'Plank');
    expect(find.text('Reps'), findsNothing);
    expect(find.text('Weight, kg'), findsNothing);
    expect(find.text('Duration, sec'), findsOneWidget);
    expect(find.text('Distance'), findsNothing);
    expect(find.text('Assistance weight'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openExercise(tester, 'Sled push');
    expect(find.text('Reps'), findsNothing);
    expect(find.text('Weight, kg'), findsOneWidget);
    expect(find.text('Duration, sec'), findsOneWidget);
    expect(find.text('Distance'), findsNothing);
    expect(find.text('Assistance weight'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openExercise(tester, 'Run');
    expect(find.text('20 min • 5 km'), findsOneWidget);
    expect(find.text('Reps'), findsNothing);
    expect(find.text('Weight, kg'), findsNothing);
    expect(find.text('Duration, sec'), findsOneWidget);
    expect(find.text('Distance, km'), findsOneWidget);
    expect(find.text('Assistance weight'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openExercise(tester, 'Assisted pull-up');
    expect(find.text('3 sets • 8 reps • 25 kg assistance'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight, kg'), findsNothing);
    expect(find.text('Duration, sec'), findsNothing);
    expect(find.text('Distance, km'), findsNothing);
    expect(find.text('Assistance weight, kg'), findsOneWidget);
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

    await enterWorkoutSet(tester, reps: '8', weight: '65');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(find.textContaining('8'), findsWidgets);
    expect(find.textContaining('65'), findsWidgets);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    final repsField = fields[0];
    final weightField = fields[1];
    expect(repsField.controller?.text, isEmpty);
    expect(weightField.controller?.text, isEmpty);

    await tester.tap(find.text('#1 • 8 reps • 65 kg'));
    await tester.pumpAndSettle();

    expect(repsField.controller?.text, '8');
    expect(weightField.controller?.text, '65');
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

    await enterWorkoutSet(tester, reps: '8', weight: '65');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    await enterWorkoutSet(tester, reps: '6', weight: '67.5');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(2));
  });

  testWidgets('current session history rows can be deleted', (tester) async {
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

    await enterWorkoutSet(tester, reps: '8', weight: '65');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();
    await enterWorkoutSet(tester, reps: '6', weight: '67.5');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(find.text('#2 • 6 reps • 67.5 kg'), findsOneWidget);
    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(2));

    await revealHistoryRowActions(tester, '#2 • 6 reps • 67.5 kg');
    await tester.tap(find.byKey(const ValueKey('swipe-action-Delete')).last);
    await tester.pumpAndSettle();

    expect(find.text('#2 • 6 reps • 67.5 kg'), findsNothing);
    expect(find.text('#1 • 8 reps • 65 kg'), findsOneWidget);
    expect(store.activeWorkoutSession!.results.first.setLogs, hasLength(1));
    expect(
      store.completedWorkoutSessions.single.results.first.setLogs,
      hasLength(1),
    );
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
    expect(find.text('3 sets • 8 reps • 132.3 lbs'), findsOneWidget);

    await enterWorkoutSet(tester, reps: '8', weight: '137.8');
    await tester.tap(find.text('Log set'));
    await tester.pumpAndSettle();

    expect(
      store.activeWorkoutSession!.results.first.setLogs.single.weightGrams,
      closeTo(62500, 50),
    );

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
    expect(find.text('Training log'), findsOneWidget);
    expect(find.text('Workout stats'), findsOneWidget);
    expect(find.text('Latest: Chest day'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Latest'), findsNothing);
  });

  testWidgets('finishes active session after switching tabs', (tester) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: TestFitHome(store: store)));
    await tester.pumpAndSettle();
    await openTrainDestination(tester);

    expect(find.text('Active workout'), findsOneWidget);

    await openRootDestination(tester, 'Library');

    expect(find.text('Training library'), findsOneWidget);
    expect(find.text('Active workout'), findsNothing);

    await openTrainDestination(tester);
    await openActiveWorkout(tester);

    expect(find.text('Workout session'), findsOneWidget);

    await finishWorkoutFromSession(tester);

    expect(store.activeWorkoutSession, isNull);
    expect(store.completedWorkoutSessions, hasLength(1));
    expect(find.text('Workout session'), findsNothing);
    expect(find.text('Training log'), findsOneWidget);
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

      await tester.pumpWidget(MaterialApp(home: TestFitHome(store: store)));
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

    await tapVisibleTooltip(tester, 'Delete completed Chest day');

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

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Chest day • 2026-04-18 09:00'), findsOneWidget);
    expect(find.text('#1 • 8 reps • 62.5 kg'), findsWidgets);

    await tester.tap(find.text('#1 • 8 reps • 62.5 kg').first);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 560));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '8');
    expect(fields[1].controller?.text, '62.5');
    store.addActiveWorkoutSet(
      resultIndex: 0,
      setLog: const WorkoutSetLog(reps: 8, weightGrams: 62500),
    );
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

    expect(find.text('#1 • 8 reps'), findsOneWidget);
    expect(find.text('#1 • 10 reps'), findsOneWidget);

    final olderPreviousSet = find.text('#1 • 10 reps');
    await tester.ensureVisible(olderPreviousSet);
    await tester.pumpAndSettle();
    await tester.tap(olderPreviousSet);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 560));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller?.text, '10');
    expect(fields, hasLength(1));
  });

  testWidgets(
    'repeated exercise summary reuses the matching previous occurrence only',
    (tester) async {
      final store = AppStore.empty();
      createRepeatPushupsPlan(store);
      finishRepeatPushupsWorkout(store);
      store.startWorkout(
        trainingPlanId: 'repeat-pushups',
        startedAt: DateTime(2026, 4, 19, 10),
      );

      await pumpWorkoutScreen(tester, store: store);
      await openActiveWorkout(tester);
      await tester.tap(find.byTooltip('Open Pushups entry 2'));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('#1 • 8 reps'), findsOneWidget);
      expect(find.text('#1 • 10 reps'), findsOneWidget);
    },
  );

  testWidgets('keeps workout tab visible on session and exercise screens', (
    tester,
  ) async {
    final store = AppStore();
    store.startWorkout(
      trainingPlanId: 'chest-day',
      startedAt: DateTime(2026, 4, 19, 10),
    );

    await tester.pumpWidget(MaterialApp(home: TestFitHome(store: store)));
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

    expect(find.text('Training library'), findsOneWidget);

    await openTrainDestination(tester);

    expect(find.text('Active workout'), findsOneWidget);
    await openActiveWorkout(tester);
    expect(find.text('Bench press'), findsOneWidget);
  });
}
