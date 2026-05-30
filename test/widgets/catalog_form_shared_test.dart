import 'package:fitapp/widgets/catalog_form_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog basics section renders shared fields', (tester) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final servingSizeController = TextEditingController();
    addTearDown(nameController.dispose);
    addTearDown(descriptionController.dispose);
    addTearDown(servingSizeController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogBasicsSection(
            sectionTitle: 'Food basics',
            sectionSubtitle: 'Name this item and define the serving anchor.',
            nameLabel: 'Name',
            descriptionLabel: 'Description',
            servingSizeLabel: 'Serving size grams',
            nameController: nameController,
            descriptionController: descriptionController,
            servingSizeController: servingSizeController,
          ),
        ),
      ),
    );

    expect(find.text('Food basics'), findsOneWidget);
    expect(
      find.text('Name this item and define the serving anchor.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Name'), findsOneWidget);
    expect(find.bySemanticsLabel('Description'), findsOneWidget);
    expect(find.bySemanticsLabel('Serving size grams'), findsOneWidget);
  });

  testWidgets('catalog form shell uses dialog and page variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogFormShell(
            title: 'Food item',
            subtitle: 'Define reusable food data for faster meal logging.',
            primaryActionLabel: 'Save food',
            onPrimaryAction: () {},
            fullScreen: false,
            children: const [SizedBox(height: 40)],
          ),
        ),
      ),
    );

    expect(find.text('Food item'), findsOneWidget);
    expect(find.text('Save food'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogFormShell(
          title: 'Recipe',
          subtitle: 'Combine foods into a reusable recipe.',
          primaryActionLabel: 'Save recipe',
          onPrimaryAction: () {},
          fullScreen: true,
          children: const [SizedBox(height: 40)],
        ),
      ),
    );

    expect(find.text('Recipe'), findsNWidgets(2));
    expect(find.text('Save recipe'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
