import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/screens/more_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, AppStore store) async {
    await tester.pumpWidget(MaterialApp(home: MoreScreen(store: store)));
    await tester.pumpAndSettle();
  }

  testWidgets('more screen uses redesigned settings surface', (tester) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(
      find.text('Tune units, appearance, and sync preferences.'),
      findsOneWidget,
    );
    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
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
}
