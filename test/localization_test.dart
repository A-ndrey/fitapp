import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/l10n/app_localizations.dart';

void main() {
  testWidgets('FitApp exposes generated localization configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final appContext = tester.element(find.byType(FitHome));

    expect(app.localizationsDelegates, isNotNull);
    expect(app.supportedLocales, contains(const Locale('en')));
    expect(app.onGenerateTitle, isNotNull);
    expect(app.onGenerateTitle!(appContext), 'FitApp');
  });

  testWidgets('root destination labels stay visible after localization setup', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('core redesigned surfaces expose localized strings', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(FitHome)))!;

    expect(l10n.todayReadyState, 'Ready to train');
    expect(l10n.todayDailyFuelTitle, "Today's macros");
    expect(l10n.todayQuickActionsTitle, 'Quick actions');
    expect(l10n.mealTitle, 'Nutrition');
    expect(l10n.mealAddItemAction, 'Log food');
    expect(l10n.mealCreateItem('Tomato'), 'Create "Tomato"');
    expect(l10n.moreSyncTitle, 'Sync');
    expect(l10n.settingsAppearanceTitle, 'Appearance');
  });

  testWidgets('workout and library surfaces expose localized strings', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(FitHome)))!;

    expect(l10n.workoutTitle, 'Workout');
    expect(l10n.workoutTrainingCockpitTitle, 'Training log');
    expect(l10n.workoutExerciseTitle, 'Workout exercise');
    expect(l10n.workoutHistoryTitle, 'Workout history');
    expect(l10n.workoutDeleteDialogTitle, 'Delete workout?');
    expect(l10n.workoutTargetPrefix, 'Target:');
    expect(l10n.workoutHourUnit, 'h');
    expect(l10n.workoutMinuteUnit, 'min');
    expect(l10n.workoutSetsLabel, 'sets');
    expect(l10n.workoutRepsLabel, 'reps');
    expect(l10n.workoutSetCountLogged(2), '2 sets logged');
    expect(
      l10n.librarySubtitle,
      'Manage plans, exercises, foods, and recipes.',
    );
    expect(l10n.libraryFoodsSection, 'Foods');
    expect(l10n.libraryEditItem('Rice'), 'Edit Rice');
  });

  testWidgets('form and editor surfaces expose localized strings', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(FitHome)))!;

    expect(l10n.formCancelAction, 'Cancel');
    expect(l10n.workoutRepsFieldLabel, 'Reps');
    expect(l10n.workoutLogSetAction, 'Log set');
    expect(l10n.trainingPlanDialogTitle, 'Training plan');
    expect(l10n.trainingSetsSummaryLabel, 'sets');
    expect(l10n.exerciseProfileSectionTitle, 'Exercise profile');
    expect(l10n.foodFormTitle, 'Food item');
    expect(l10n.dishFormTitle, 'Recipe');
    expect(l10n.dishComponentGramsFieldLabel, 'Ingredient grams');
  });
}
