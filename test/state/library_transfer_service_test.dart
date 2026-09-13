import 'dart:convert';

import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/exercise.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/library_transfer.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/models/training_plan.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/library_transfer/library_transfer_service.dart';
import 'package:flutter_test/flutter_test.dart';

const benchPress = Exercise(
  id: 'bench-press',
  name: 'Bench press',
  description: 'Barbell chest press',
  instruction: 'Keep the shoulder blades set.',
  muscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
  measurementType: ExerciseMeasurementType.strength,
);

const chestDay = TrainingPlan(
  id: 'chest-day',
  name: 'Chest day',
  description: 'Pressing work',
  exercises: [
    TrainingExercise(
      exerciseId: 'bench-press',
      sets: 3,
      reps: 8,
      weightGrams: 60000,
    ),
  ],
);

const oats = FoodItem(
  id: 'oats',
  name: 'Oats',
  description: 'Rolled oats',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 370, protein: 13, fat: 7, carbs: 62),
);

void main() {
  group('LibraryTransferService', () {
    test('exports a self-contained plan and imports its missing exercise', () {
      final sourceStore = AppStore()
        ..createExercise(benchPress)
        ..createTrainingPlan(chestDay);
      final sourceService = LibraryTransferService(sourceStore);

      final json = sourceService.exportItem(
        LibraryCategory.trainingPlans,
        chestDay.id,
      );
      final document = jsonDecode(json) as Map<String, dynamic>;
      final references = document['references'] as Map<String, dynamic>;
      expect(document['format'], LibraryTransferService.formatName);
      expect(document['schemaVersion'], LibraryTransferService.schemaVersion);
      expect(document['scope'], 'item');
      expect(references['exercises'], hasLength(1));

      final destinationStore = AppStore();
      final destinationService = LibraryTransferService(destinationStore);
      final preview = destinationService.preview(json);

      expect(preview.createCount, 1);
      expect(preview.entries.single.missingReferences, hasLength(1));
      expect(
        (preview.entries.single.missingReferences.single as Exercise).id,
        benchPress.id,
      );

      final result = destinationService.apply(
        preview,
        selectedKeys: {preview.entries.single.key},
      );

      expect(result.created, 1);
      expect(result.failures, isEmpty);
      expect(
        destinationStore.exerciseById(benchPress.id)?.name,
        benchPress.name,
      );
      expect(
        destinationStore.trainingPlanById(chestDay.id)?.exercises,
        hasLength(1),
      );
    });

    test('existing references are context-only during plan import', () {
      final sourceStore = AppStore()
        ..createExercise(benchPress)
        ..createTrainingPlan(chestDay);
      final json = LibraryTransferService(
        sourceStore,
      ).exportItem(LibraryCategory.trainingPlans, chestDay.id);
      final localExercise = benchPress.copyWith(
        description: 'Keep my local description',
      );
      final destinationStore = AppStore()..createExercise(localExercise);
      final service = LibraryTransferService(destinationStore);
      final preview = service.preview(json);

      service.apply(preview, selectedKeys: {preview.entries.single.key});

      expect(
        destinationStore.exerciseById(benchPress.id)?.description,
        'Keep my local description',
      );
      expect(destinationStore.trainingPlanById(chestDay.id), isNotNull);
    });

    test('reports an invalid missing exercise reference in the preview', () {
      final sourceStore = AppStore()
        ..createExercise(benchPress)
        ..createTrainingPlan(chestDay);
      final source = LibraryTransferService(
        sourceStore,
      ).exportItem(LibraryCategory.trainingPlans, chestDay.id);
      final document = jsonDecode(source) as Map<String, dynamic>;
      final references = document['references'] as Map<String, dynamic>;
      final exercises = references['exercises'] as List<dynamic>;
      (exercises.single as Map<String, dynamic>)['instruction'] = '';

      final preview = LibraryTransferService(
        AppStore(),
      ).preview(jsonEncode(document));

      expect(preview.errorCount, 1);
      expect(preview.entries.single.error, contains('must not be empty'));
    });

    test(
      'single recipe export contains recursive food and recipe references',
      () {
        const sauce = DishItem(
          id: 'sauce',
          name: 'Oat sauce',
          description: 'A base sauce',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'oats', grams: 100)],
        );
        const bowl = DishItem(
          id: 'bowl',
          name: 'Oat bowl',
          description: 'A nested recipe',
          servingSizeGrams: 200,
          components: [DishComponent(itemId: 'sauce', grams: 200)],
        );
        final sourceStore = AppStore()
          ..createFood(oats)
          ..createDish(sauce)
          ..createDish(bowl);
        final json = LibraryTransferService(
          sourceStore,
        ).exportItem(LibraryCategory.recipes, bowl.id);
        final document = jsonDecode(json) as Map<String, dynamic>;
        final references = document['references'] as Map<String, dynamic>;

        expect(references['foods'], hasLength(1));
        expect(references['recipes'], hasLength(1));

        final destinationStore = AppStore();
        final service = LibraryTransferService(destinationStore);
        final preview = service.preview(json);
        final result = service.apply(
          preview,
          selectedKeys: {preview.entries.single.key},
        );

        expect(result.failures, isEmpty);
        expect(destinationStore.itemById('oats'), isNotNull);
        expect(destinationStore.itemById('sauce'), isNotNull);
        expect(destinationStore.itemById('bowl'), isNotNull);
      },
    );

    test('detects cycles introduced by recipe updates', () {
      const base = DishItem(
        id: 'base',
        name: 'Base',
        description: 'Base recipe',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'oats', grams: 100)],
      );
      const bowl = DishItem(
        id: 'bowl',
        name: 'Bowl',
        description: 'Bowl recipe',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'base', grams: 100)],
      );
      final store = AppStore()
        ..createFood(oats)
        ..createDish(base)
        ..createDish(bowl);
      final service = LibraryTransferService(store);
      final document =
          jsonDecode(service.exportCategory(LibraryCategory.recipes))
              as Map<String, dynamic>;
      final items = document['items'] as List<dynamic>;
      final baseJson = items.cast<Map<String, dynamic>>().singleWhere(
        (item) => item['id'] == 'base',
      );
      baseJson['components'] = [
        <String, Object?>{'itemId': 'bowl', 'grams': 100},
      ];

      final preview = service.preview(jsonEncode(document));

      expect(preview.errorCount, 2);
      expect(
        preview.entries.map((entry) => entry.error),
        everyElement(contains('cycle')),
      );
    });

    test('previews invalid batch entries without blocking valid entries', () {
      final sourceStore = AppStore()
        ..createFood(oats)
        ..createFood(
          oats.copyWith(id: 'rice', name: 'Rice', description: 'Cooked rice'),
        );
      final source = LibraryTransferService(
        sourceStore,
      ).exportCategory(LibraryCategory.foods);
      final document = jsonDecode(source) as Map<String, dynamic>;
      final items = document['items'] as List<dynamic>;
      (items.last as Map<String, dynamic>)['servingSizeGrams'] = -1;

      final destinationStore = AppStore();
      final service = LibraryTransferService(destinationStore);
      final preview = service.preview(jsonEncode(document));

      expect(preview.createCount, 1);
      expect(preview.errorCount, 1);
      final validEntry = preview.entries.singleWhere(
        (entry) => entry.canImport,
      );
      final result = service.apply(preview, selectedKeys: {validEntry.key});

      expect(result.created, 1);
      expect(destinationStore.items, hasLength(1));
      expect(destinationStore.itemById('oats'), isNotNull);
      expect(destinationStore.itemById('rice'), isNull);
    });

    test('matching ids preview as updates and can be imported as copies', () {
      final sourceStore = AppStore()..createFood(oats);
      final source = LibraryTransferService(
        sourceStore,
      ).exportCategory(LibraryCategory.foods);
      final destinationStore = AppStore()..createFood(oats);
      final service = LibraryTransferService(destinationStore);
      final preview = service.preview(source);
      final entry = preview.entries.single;

      expect(entry.action, LibraryImportAction.update);
      expect(entry.canImportAsCopy, isTrue);

      final result = service.apply(
        preview,
        selectedKeys: {entry.key},
        copyKeys: {entry.key},
      );

      expect(result.copied, 1);
      expect(destinationStore.items, hasLength(2));
      expect(
        destinationStore.items.map((item) => item.name),
        contains('Oats (copy)'),
      );
    });

    test('coalesces a batch into one store notification', () {
      final sourceStore = AppStore()
        ..createFood(oats)
        ..createFood(
          oats.copyWith(id: 'rice', name: 'Rice', description: 'Cooked rice'),
        );
      final source = LibraryTransferService(
        sourceStore,
      ).exportCategory(LibraryCategory.foods);
      final destinationStore = AppStore();
      final service = LibraryTransferService(destinationStore);
      final preview = service.preview(source);
      var notifications = 0;
      destinationStore.addListener(() => notifications += 1);

      service.apply(
        preview,
        selectedKeys: preview.entries.map((entry) => entry.key).toSet(),
      );

      expect(notifications, 1);
      expect(destinationStore.items, hasLength(2));
    });

    test('rejects unsupported schema versions', () {
      final sourceStore = AppStore()..createFood(oats);
      final source = LibraryTransferService(
        sourceStore,
      ).exportCategory(LibraryCategory.foods);
      final document = jsonDecode(source) as Map<String, dynamic>;
      document['schemaVersion'] = 99;

      expect(
        () => LibraryTransferService(AppStore()).preview(jsonEncode(document)),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
