import 'dart:convert';

import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/library_transfer.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/screens/library_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/library_transfer/library_transfer_controller.dart';
import 'package:fitapp/state/library_transfer/library_transfer_service.dart';
import 'package:fitapp/ui/library/library_transfer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const exercise = Exercise(
  id: 'squat',
  name: 'Squat',
  description: 'Barbell squat',
  instruction: 'Brace and stand through mid-foot.',
  muscleGroups: [MuscleGroup.quads, MuscleGroup.glutes],
  measurementType: ExerciseMeasurementType.strength,
);

const plan = TrainingPlan(
  id: 'leg-day',
  name: 'Leg day',
  description: 'Squat work',
  exercises: [
    TrainingExercise(exerciseId: 'squat', sets: 4, reps: 6, weightGrams: 80000),
  ],
);

void main() {
  testWidgets('preview applies selected valid items', (tester) async {
    final sourceStore = AppStore()
      ..createExercise(exercise)
      ..createTrainingPlan(plan);
    final source = LibraryTransferService(
      sourceStore,
    ).exportItem(LibraryCategory.trainingPlans, plan.id);
    final destinationStore = AppStore();
    final service = LibraryTransferService(destinationStore);
    final controller = LibraryTransferController(service: service);
    final preview = service.preview(source);

    await tester.pumpWidget(
      MaterialApp(
        home: LibraryImportPreviewPage(
          controller: controller,
          preview: preview,
        ),
      ),
    );

    expect(find.text('1 new'), findsOneWidget);
    expect(find.text('0 errors'), findsOneWidget);
    expect(find.text('Leg day'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-import-apply')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-import-apply')));
    await tester.pumpAndSettle();

    expect(destinationStore.trainingPlanById(plan.id), isNotNull);
    expect(destinationStore.exerciseById(exercise.id), isNotNull);
    controller.dispose();
  });

  testWidgets('update preview offers import as copy on a compact window', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sourceStore = AppStore()..createExercise(exercise);
    final source = LibraryTransferService(
      sourceStore,
    ).exportItem(LibraryCategory.exercises, exercise.id);
    final destinationStore = AppStore()..createExercise(exercise);
    final service = LibraryTransferService(destinationStore);
    final controller = LibraryTransferController(service: service);

    await tester.pumpWidget(
      MaterialApp(
        home: LibraryImportPreviewPage(
          controller: controller,
          preview: service.preview(source),
        ),
      ),
    );

    expect(find.text('1 updates'), findsOneWidget);
    expect(find.text('Import as copy'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('invalid entries are shown and not selected', (tester) async {
    final document = <String, Object?>{
      'format': LibraryTransferService.formatName,
      'schemaVersion': LibraryTransferService.schemaVersion,
      'category': LibraryCategory.exercises.name,
      'scope': LibraryTransferScope.category.name,
      'items': [
        <String, Object?>{
          'id': 'bad',
          'name': 'Bad exercise',
          'description': '',
          'instruction': '',
          'muscleGroups': <String>[],
          'measurementType': 'strength',
        },
      ],
      'references': <String, Object?>{},
    };
    final store = AppStore();
    final service = LibraryTransferService(store);
    final controller = LibraryTransferController(service: service);

    await tester.pumpWidget(
      MaterialApp(
        home: LibraryImportPreviewPage(
          controller: controller,
          preview: service.preview(jsonEncode(document)),
        ),
      ),
    );

    expect(find.text('1 errors'), findsOneWidget);
    expect(find.textContaining('Cannot import'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('library-import-apply')),
    );
    expect(button.onPressed, isNull);
    controller.dispose();
  });

  testWidgets('library category exposes import and export actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore()
      ..createExercise(exercise)
      ..createTrainingPlan(plan);

    await tester.pumpWidget(MaterialApp(home: LibraryScreen(store: store)));
    await tester.tap(find.text('Plans'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Import JSON'), findsOneWidget);
    expect(find.byTooltip('Export all as JSON'), findsOneWidget);

    final card = find.ancestor(
      of: find.text('Leg day'),
      matching: find.byType(Card),
    );
    final menu = find.descendant(
      of: card,
      matching: find.byTooltip('More actions'),
    );
    await tester.tap(menu);
    await tester.pumpAndSettle();

    expect(find.text('Export as JSON'), findsOneWidget);
  });
}
