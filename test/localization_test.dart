import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';

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
}
