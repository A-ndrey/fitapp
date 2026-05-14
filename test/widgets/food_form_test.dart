import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/widgets/food_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FoodForm(store: AppStore.empty())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('touched food numeric field rejects letters', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.bySemanticsLabel('Serving size grams'), 'abc');
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.ancestor(
        of: find.bySemanticsLabel('Serving size grams'),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, isEmpty);
  });
}
