import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/screens/more_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AppStore store, {
    Size? size,
  }) async {
    if (size != null) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await tester.pumpWidget(MaterialApp(home: MoreScreen(store: store)));
    await tester.pumpAndSettle();
  }

  testWidgets('settings screen uses redesigned settings surface', (
    tester,
  ) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text('Tune units, appearance, and training-log preferences.'),
      findsOneWidget,
    );
    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('more screen preference chips update store', (tester) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();

    expect(store.preferences.workoutWeightUnit, WorkoutWeightUnit.pounds);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('more screen stacks preference cards below medium layout', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(390, 844));

    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));
    final cardWidth = tester
        .getSize(
          find.ancestor(
            of: find.text('Workout weight'),
            matching: find.byType(Card),
          ),
        )
        .width;

    expect(dishTopLeft.dy, greaterThan(workoutTopLeft.dy));
    expect((dishTopLeft.dx - workoutTopLeft.dx).abs(), lessThan(1));
    expect(cardWidth, greaterThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('more screen places preference cards in two columns when wide', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(900, 900));

    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));

    expect((dishTopLeft.dy - workoutTopLeft.dy).abs(), lessThan(1));
    expect(dishTopLeft.dx, greaterThan(workoutTopLeft.dx));
    expect(tester.takeException(), isNull);
  });
}
