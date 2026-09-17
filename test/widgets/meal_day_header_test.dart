import 'package:fitapp/l10n/app_localizations.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/ui/core/theme/app_theme.dart';
import 'package:fitapp/ui/nutrition/meal_day_header.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const totals = NutritionValues(
    calories: 1842.4,
    protein: 96.4,
    fat: 63.2,
    carbs: 218.5,
  );

  Future<void> pumpHeader(
    WidgetTester tester, {
    double width = 800,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: MealDayHeader(
                  date: DateTime(2026, 9, 17),
                  totals: totals,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows only date, integer totals and icons in calories/protein/fat/carbs order',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHeader(tester);

      expect(
        tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
        ['September 17, 2026', '1842', '96', '63', '219'],
      );
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.map((icon) => icon.icon), [
        Icons.local_fire_department_outlined,
        Icons.egg_alt_outlined,
        Icons.water_drop_outlined,
        Icons.grain_outlined,
      ]);
      expect(icons.map((icon) => icon.color), [
        AppTheme.calorieAccent,
        AppTheme.proteinAccent,
        AppTheme.fatAccent,
        AppTheme.carbAccent,
      ]);
      for (final label in [
        'Calories: 1842 kcal',
        'Protein: 96 g',
        'Fat: 63 g',
        'Carbs: 219 g',
      ]) {
        expect(find.byTooltip(label), findsOneWidget);
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      semantics.dispose();
    },
  );

  testWidgets('keeps totals beside date when they fit', (tester) async {
    await pumpHeader(tester);
    final date = tester.getRect(find.text('September 17, 2026'));
    final calories = tester.getRect(find.text('1842'));
    expect(calories.left, greaterThan(date.right));
    expect(calories.center.dy, closeTo(date.center.dy, 1));
  });

  testWidgets('moves the whole summary below date on a narrow screen', (
    tester,
  ) async {
    await pumpHeader(tester, width: 280);
    final date = tester.getRect(find.text('September 17, 2026'));
    final calories = tester.getRect(find.text('1842'));
    expect(calories.top, greaterThan(date.bottom));
    for (final value in ['96', '63', '219']) {
      expect(tester.getRect(find.text(value)).top, calories.top);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports enlarged text without overflow or hiding totals', (
    tester,
  ) async {
    await pumpHeader(tester, width: 280, textScale: 2);
    final header = tester.getRect(find.byType(MealDayHeader));
    for (final value in ['1842', '96', '63', '219']) {
      final bounds = tester.getRect(find.text(value));
      expect(bounds.left, greaterThanOrEqualTo(header.left));
      expect(bounds.right, lessThanOrEqualTo(header.right));
      expect(bounds.bottom, lessThanOrEqualTo(header.bottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows explanatory tooltip on long press', (tester) async {
    await pumpHeader(tester);
    await tester.longPress(find.text('96'));
    await tester.pumpAndSettle();
    expect(find.text('Protein: 96 g'), findsOneWidget);
  });

  testWidgets('shows explanatory tooltip on hover', (tester) async {
    await pumpHeader(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('63')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Fat: 63 g'), findsOneWidget);
    await mouse.removePointer();
  });
}
