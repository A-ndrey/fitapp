import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';

void main() {
  testWidgets('shows Meal and Food tabs with sample content', (tester) async {
    await tester.pumpWidget(const FitApp());

    expect(find.text('Meal'), findsWidgets);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Daily totals'), findsOneWidget);
    expect(find.text('Chicken breast'), findsNothing);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Food set'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('food'), findsWidgets);
  });

  testWidgets('daily totals update after logging sample food by grams', (
    tester,
  ) async {
    await tester.pumpWidget(const FitApp());

    await tester.tap(find.byTooltip('Add meal item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicken breast').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.bySemanticsLabel('Grams'), '200');
    await tester.tap(find.text('Add to meal'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.textContaining('330'), findsWidgets);
    expect(find.textContaining('62'), findsWidgets);
  });
}
