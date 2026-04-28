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

    expect(l10n.todayReadyState, 'Ready state');
    expect(l10n.todayDailyFuelTitle, 'Daily fuel');
    expect(l10n.todayQuickActionsTitle, 'Quick actions');
    expect(l10n.mealTitle, 'Meal');
    expect(l10n.mealAddItemAction, 'Add meal item');
    expect(l10n.mealCreateItem('Tomato'), 'Create "Tomato"');
    expect(l10n.moreSyncTitle, 'Sync');
    expect(l10n.settingsAppearanceTitle, 'Appearance');
  });
}
