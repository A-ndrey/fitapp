import 'package:fitapp/l10n/app_localizations.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/models/workout_session.dart';
import 'package:fitapp/models/workout_statistics.dart';
import 'package:fitapp/screens/workout_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/persisted_app_state.dart';
import 'package:fitapp/ui/workout/workout_overview_cards.dart';
import 'package:fitapp/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact period selector shares the Stats heading row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _store();
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('Stats'));
    final selector = tester.getRect(
      find.byType(SegmentedButton<WorkoutPeriodType>),
    );
    expect(selector.left, greaterThan(title.right));
    expect(selector.top, lessThan(title.bottom));
    expect(selector.bottom, greaterThan(title.top));
    expect(selector.height, lessThanOrEqualTo(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('metric cards stretch equally when the duration wraps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 280,
            child: WorkoutStatsGrid(
              completedCount: 3,
              totalDuration: Duration(hours: 12, minutes: 45),
              setCount: 30,
            ),
          ),
        ),
      ),
    );
    final cards = find.descendant(
      of: find.byType(WorkoutStatsGrid),
      matching: find.byType(Card),
    );
    expect(cards, findsNWidgets(3));
    final heights = List.generate(3, (i) => tester.getSize(cards.at(i)).height);
    expect(heights[1], heights[0]);
    expect(heights[2], heights[0]);
    expect(
      tester.getSize(find.text('12 h 45 min')).height,
      greaterThan(tester.getSize(find.text('3')).height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('counting help and muscle details open only when requested', (
    tester,
  ) async {
    final store = await _store();
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(WorkoutScreen)),
    )!;
    expect(find.text(l10n.workoutBalanceCountingNote), findsNothing);
    expect(find.text('Forearms'), findsNothing);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.text(l10n.workoutBalanceCountingNote), findsOneWidget);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.workoutBalanceCountingNote), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sets by muscle group'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sets by muscle group'));
    await tester.pumpAndSettle();
    expect(find.text('Forearms'), findsOneWidget);
    await tester.ensureVisible(find.text('Sets by muscle group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sets by muscle group'));
    await tester.pumpAndSettle();
    expect(find.text('Forearms'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'period navigation changes metrics and leaves history available',
    (tester) async {
      final store = await _store();
      addTearDown(store.dispose);
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();
      WorkoutStatsGrid metrics() =>
          tester.widget(find.byType(WorkoutStatsGrid));
      expect(metrics().completedCount, 1);
      expect(metrics().setCount, 3);
      expect(metrics().totalDuration, const Duration(minutes: 45));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Next period',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byTooltip('Previous period'));
      await tester.pumpAndSettle();
      expect(metrics().completedCount, 1);
      expect(metrics().setCount, 7);
      expect(find.text('Current period'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Next period',
        ),
      );
      await tester.pumpAndSettle();
      expect(metrics().setCount, 3);

      await tester.tap(find.byTooltip('Previous period'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Current period'));
      await tester.pumpAndSettle();
      expect(metrics().setCount, 3);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(WorkoutScreen));
      expect(
        find.text(
          MaterialLocalizations.of(context).formatMonthYear(DateTime.now()),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SegmentedButton<WorkoutPeriodType>>(
              find.byType(SegmentedButton<WorkoutPeriodType>),
            )
            .selected,
        {WorkoutPeriodType.month},
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('Previous period'));
        await tester.pumpAndSettle();
      }
      expect(metrics().completedCount, 0);
      expect(metrics().setCount, 0);
      expect(find.text('No workouts in this period.'), findsOneWidget);
      expect(find.byKey(const ValueKey('workout-muscle-radar')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Previous week workout'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('This week workout'), findsOneWidget);
      expect(find.text('Previous week workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'radar and group details fit width $width and text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = await _store();
          addTearDown(store.dispose);
          await tester.pumpWidget(
            _app(
              store,
              scale: scale,
              brightness: scale == 2 ? Brightness.dark : Brightness.light,
            ),
          );
          await tester.pumpAndSettle();
          final semantics = tester.ensureSemantics();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('workout-muscle-radar')),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(
            find.bySemanticsLabel(RegExp('Muscle balance.*Chest: 3.*Arms: 3')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Forearms'), findsNothing);
          await tester.scrollUntilVisible(
            find.text('Sets by muscle group'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sets by muscle group'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Forearms'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text('Sets by muscle group'), findsOneWidget);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets(
    'unattributed sets appear separately without inventing muscle load',
    (tester) async {
      final store = await _store(groups: []);
      addTearDown(store.dispose);
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Unknown group'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Unknown group'), findsOneWidget);
      expect(
        find.text('No muscle groups available for the logged sets.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(
  AppStore store, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: WorkoutScreen(store: store),
);

Future<AppStore> _store({
  List<MuscleGroup> groups = const [
    MuscleGroup.chest,
    MuscleGroup.biceps,
    MuscleGroup.forearms,
  ],
}) async {
  final week = WorkoutPeriod.containing(DateTime.now(), WorkoutPeriodType.week);
  WorkoutSession session(String id, String name, DateTime date, int sets) =>
      WorkoutSession(
        id: id,
        trainingPlanId: 'plan',
        trainingPlanName: name,
        startedAt: date,
        finishedAt: date.add(const Duration(minutes: 45)),
        results: [
          WorkoutExerciseResult(
            exerciseId: 'exercise',
            exerciseName: 'Exercise',
            measurementType: ExerciseMeasurementType.bodyweight,
            muscleGroups: groups,
            target: const TrainingExercise(
              exerciseId: 'exercise',
              sets: 10,
              reps: 8,
            ),
            setLogs: List.generate(sets, (_) => const WorkoutSetLog(reps: 8)),
          ),
        ],
      );
  final store = AppStore.empty();
  await store.applyExternalPersistedState(
    PersistedAppState(
      userFoods: [],
      userDishes: [],
      userExercises: [],
      userTrainingPlans: [],
      mealEntries: [],
      preferences: const AppPreferences.defaults(),
      activeWorkoutSession: null,
      completedWorkoutSessions: [
        session('current', 'This week workout', week.start, 3),
        session('previous', 'Previous week workout', week.shift(-1).start, 7),
      ],
      mealEntryCounter: 0,
      workoutSessionCounter: 0,
    ),
  );
  return store;
}
