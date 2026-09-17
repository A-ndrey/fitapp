import 'dart:convert';

import '../../models/catalog_item.dart';
import '../../models/dish_item.dart';
import '../../models/exercise.dart';
import '../../models/food_item.dart';
import '../../models/library_transfer.dart';
import '../../models/nutrition.dart';
import '../../models/training_plan.dart';
import '../app_store.dart';

/// Encodes, validates, previews, and applies FitApp library transfer files.
class LibraryTransferService {
  LibraryTransferService(this._store);

  static const formatName = 'fitapp.library';
  static const schemaVersion = 1;

  final AppStore _store;

  String exportCategory(LibraryCategory category) {
    return _encodeDocument(
      category: category,
      scope: LibraryTransferScope.category,
      values: _valuesForCategory(category),
    );
  }

  String exportItem(LibraryCategory category, String id) {
    final value = _valueById(category, id);
    if (value == null) {
      throw ArgumentError('Missing ${category.name} item id: $id');
    }
    return _encodeDocument(
      category: category,
      scope: LibraryTransferScope.item,
      values: [value],
    );
  }

  LibraryImportPreview preview(String source) {
    final decoded = jsonDecode(source);
    final root = _asMap(decoded, 'transfer document');
    if (_readString(root, 'format') != formatName) {
      throw const FormatException('This is not a FitApp library file.');
    }
    final version = _readInt(root, 'schemaVersion');
    if (version != schemaVersion) {
      throw FormatException(
        'Unsupported schema version $version. Expected $schemaVersion.',
      );
    }

    final category = _readEnum(
      _readString(root, 'category'),
      LibraryCategory.values,
      'category',
    );
    final scope = _readEnum(
      _readString(root, 'scope'),
      LibraryTransferScope.values,
      'scope',
    );
    final rawItems = _readList(root, 'items');
    final references = _decodeReferences(root['references']);
    final parsed = <_ParsedEntry>[];

    for (var index = 0; index < rawItems.length; index += 1) {
      try {
        final value = _decodeValue(category, rawItems[index]);
        parsed.add(_ParsedEntry(index: index, value: value));
      } on FormatException catch (error) {
        parsed.add(
          _ParsedEntry(
            index: index,
            error: error.message.toString(),
            fallbackName: _fallbackName(rawItems[index], index),
          ),
        );
      }
    }

    final duplicateIds = <String>{};
    final idCounts = <String, int>{};
    for (final entry in parsed) {
      final id = _idOf(entry.value);
      if (id != null) {
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
    }
    duplicateIds.addAll(
      idCounts.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key),
    );

    final packageValues = <String, Object>{};
    for (final entry in parsed) {
      final value = entry.value;
      if (value != null) {
        packageValues[_idOf(value)!] = value;
      }
    }
    final entries = parsed
        .map((entry) {
          final value = entry.value;
          if (value == null) {
            return LibraryImportEntry(
              key: '$indexPrefix${entry.index}',
              category: category,
              id: '',
              name: entry.fallbackName ?? 'Item ${entry.index + 1}',
              value: null,
              action: LibraryImportAction.error,
              missingReferences: const [],
              error: entry.error,
            );
          }

          final id = _idOf(value)!;
          final name = _nameOf(value)!;
          String? error;
          if (duplicateIds.contains(id)) {
            error = 'Duplicate id "$id" in this file.';
          } else {
            error = _validateValue(
              category,
              value,
              references: references,
              packageValues: packageValues,
            );
          }
          final existing = _valueById(category, id);
          final action = error != null
              ? LibraryImportAction.error
              : existing == null
              ? LibraryImportAction.create
              : LibraryImportAction.update;
          final missingReferences = error == null
              ? _missingReferences(
                  category,
                  value,
                  references: references,
                  packageValues: packageValues,
                )
              : const <Object>[];
          return LibraryImportEntry(
            key: '${category.name}:$id:${entry.index}',
            category: category,
            id: id,
            name: name,
            value: value,
            action: action,
            missingReferences: List.unmodifiable(missingReferences),
            error: error,
          );
        })
        .toList(growable: false);

    return LibraryImportPreview(
      category: category,
      scope: scope,
      entries: List.unmodifiable(entries),
    );
  }

  LibraryImportResult apply(
    LibraryImportPreview preview, {
    required Set<String> selectedKeys,
    Set<String> copyKeys = const {},
  }) {
    var created = 0;
    var updated = 0;
    var copied = 0;
    final failures = <String, String>{};
    final selected = preview.entries
        .where((entry) => selectedKeys.contains(entry.key) && entry.canImport)
        .toList(growable: false);

    _store.runPersistedMutationBatch(() {
      for (final entry in _sortForImport(selected)) {
        final createdReferences = <Object>[];
        try {
          for (final reference in _sortReferences(entry.missingReferences)) {
            if (_existingValue(reference) != null) {
              continue;
            }
            _createValue(reference);
            createdReferences.add(reference);
          }

          if (copyKeys.contains(entry.key)) {
            _createValue(_copyValue(entry.value!));
            copied += 1;
          } else if (entry.action == LibraryImportAction.update) {
            _updateValue(entry.value!);
            updated += 1;
          } else {
            _createValue(entry.value!);
            created += 1;
          }
        } on Object catch (error) {
          for (final reference in createdReferences.reversed) {
            try {
              _deleteValue(reference);
            } on Object {
              // A reference used by another successful entry is retained.
            }
          }
          failures[entry.key] = _messageFor(error);
        }
      }
    });

    return LibraryImportResult(
      created: created,
      updated: updated,
      copied: copied,
      failures: Map.unmodifiable(failures),
    );
  }

  static const indexPrefix = 'invalid:';

  String _encodeDocument({
    required LibraryCategory category,
    required LibraryTransferScope scope,
    required List<Object> values,
  }) {
    final references = _referencesFor(category, values);
    final document = <String, Object?>{
      'format': formatName,
      'schemaVersion': schemaVersion,
      'category': category.name,
      'scope': scope.name,
      'items': values.map(_encodeValue).toList(growable: false),
      'references': <String, Object?>{
        if (references.foods.isNotEmpty)
          LibraryCategory.foods.name: references.foods.values
              .map(_encodeFood)
              .toList(growable: false),
        if (references.recipes.isNotEmpty)
          LibraryCategory.recipes.name: references.recipes.values
              .map(_encodeDish)
              .toList(growable: false),
        if (references.exercises.isNotEmpty)
          LibraryCategory.exercises.name: references.exercises.values
              .map(_encodeExercise)
              .toList(growable: false),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  List<Object> _valuesForCategory(LibraryCategory category) {
    return switch (category) {
      LibraryCategory.foods =>
        _store.items
            .where((item) => item.isFood)
            .map<Object>((item) => item.food!)
            .toList(growable: false),
      LibraryCategory.recipes =>
        _store.items
            .where((item) => item.isDish)
            .map<Object>((item) => item.dish!)
            .toList(growable: false),
      LibraryCategory.exercises => List<Object>.of(_store.exercises),
      LibraryCategory.trainingPlans => List<Object>.of(_store.trainingPlans),
    };
  }

  Object? _valueById(LibraryCategory category, String id) {
    return switch (category) {
      LibraryCategory.foods => _store.itemById(id)?.food,
      LibraryCategory.recipes => _store.itemById(id)?.dish,
      LibraryCategory.exercises => _store.exerciseById(id),
      LibraryCategory.trainingPlans => _store.trainingPlanById(id),
    };
  }

  _References _referencesFor(LibraryCategory category, List<Object> values) {
    if (category == LibraryCategory.trainingPlans) {
      final exercises = <String, Exercise>{};
      for (final plan in values.cast<TrainingPlan>()) {
        for (final target in plan.exercises) {
          final exercise = _store.exerciseById(target.exerciseId);
          if (exercise != null) {
            exercises[exercise.id] = exercise;
          }
        }
      }
      return _References(exercises: exercises);
    }
    if (category != LibraryCategory.recipes) {
      return const _References();
    }

    final selectedIds = values.cast<DishItem>().map((dish) => dish.id).toSet();
    final foods = <String, FoodItem>{};
    final recipes = <String, DishItem>{};
    final visited = <String>{};

    void collect(DishItem dish) {
      if (!visited.add(dish.id)) {
        return;
      }
      for (final component in dish.components) {
        final item = _store.itemById(component.itemId);
        if (item == null) {
          continue;
        }
        if (item.isFood) {
          foods[item.id] = item.food!;
        } else {
          final nested = item.dish!;
          if (!selectedIds.contains(nested.id)) {
            recipes[nested.id] = nested;
          }
          collect(nested);
        }
      }
    }

    for (final dish in values.cast<DishItem>()) {
      collect(dish);
    }
    return _References(foods: foods, recipes: recipes);
  }

  Map<String, Object?> _encodeValue(Object value) {
    return switch (value) {
      final FoodItem food => _encodeFood(food),
      final DishItem dish => _encodeDish(dish),
      final Exercise exercise => _encodeExercise(exercise),
      final TrainingPlan plan => _encodePlan(plan),
      _ => throw ArgumentError(
        'Unsupported library value ${value.runtimeType}.',
      ),
    };
  }

  Map<String, Object?> _encodeFood(FoodItem food) => <String, Object?>{
    'id': food.id,
    'name': food.name,
    'description': food.description,
    'servingSizeGrams': food.servingSizeGrams,
    'basis': food.basis.name,
    'nutrition': <String, Object?>{
      'calories': food.nutrition.calories,
      'protein': food.nutrition.protein,
      'fat': food.nutrition.fat,
      'carbs': food.nutrition.carbs,
    },
  };

  Map<String, Object?> _encodeDish(DishItem dish) => <String, Object?>{
    'id': dish.id,
    'name': dish.name,
    'description': dish.description,
    'servingSizeGrams': dish.servingSizeGrams,
    'components': dish.components
        .map(
          (component) => <String, Object?>{
            'itemId': component.itemId,
            'grams': component.grams,
          },
        )
        .toList(growable: false),
  };

  Map<String, Object?> _encodeExercise(Exercise exercise) => <String, Object?>{
    'id': exercise.id,
    'name': exercise.name,
    'description': exercise.description,
    'instruction': exercise.instruction,
    'muscleGroups': exercise.muscleGroups
        .map((group) => group.name)
        .toList(growable: false),
    'measurementType': exercise.measurementType.name,
  };

  Map<String, Object?> _encodePlan(TrainingPlan plan) => <String, Object?>{
    'id': plan.id,
    'name': plan.name,
    'description': plan.description,
    'exercises': plan.exercises
        .map(
          (exercise) => <String, Object?>{
            'exerciseId': exercise.exerciseId,
            'sets': exercise.sets,
            'reps': exercise.reps,
            'weightGrams': exercise.weightGrams,
            'durationSeconds': exercise.durationSeconds,
            'distanceMeters': exercise.distanceMeters,
            'assistanceWeightGrams': exercise.assistanceWeightGrams,
          },
        )
        .toList(growable: false),
  };

  _References _decodeReferences(Object? encoded) {
    if (encoded == null) {
      return const _References();
    }
    final root = _asMap(encoded, 'references');
    final foods = <String, FoodItem>{};
    final recipes = <String, DishItem>{};
    final exercises = <String, Exercise>{};
    for (final raw in _readOptionalList(root, LibraryCategory.foods.name)) {
      try {
        final food = _decodeFood(raw);
        foods[food.id] = food;
      } on FormatException {
        // A dependent item reports this as an unavailable reference.
      }
    }
    for (final raw in _readOptionalList(root, LibraryCategory.recipes.name)) {
      try {
        final recipe = _decodeDish(raw);
        recipes[recipe.id] = recipe;
      } on FormatException {
        // A dependent item reports this as an unavailable reference.
      }
    }
    for (final raw in _readOptionalList(root, LibraryCategory.exercises.name)) {
      try {
        final exercise = _decodeExercise(raw);
        exercises[exercise.id] = exercise;
      } on FormatException {
        // A dependent item reports this as an unavailable reference.
      }
    }
    return _References(foods: foods, recipes: recipes, exercises: exercises);
  }

  Object _decodeValue(LibraryCategory category, Object? encoded) {
    return switch (category) {
      LibraryCategory.foods => _decodeFood(encoded),
      LibraryCategory.recipes => _decodeDish(encoded),
      LibraryCategory.exercises => _decodeExercise(encoded),
      LibraryCategory.trainingPlans => _decodePlan(encoded),
    };
  }

  FoodItem _decodeFood(Object? encoded) {
    final map = _asMap(encoded, 'food');
    final nutrition = _asMap(map['nutrition'], 'food.nutrition');
    return FoodItem(
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      description: _readString(map, 'description'),
      servingSizeGrams: _readDouble(map, 'servingSizeGrams'),
      basis: _readEnum(
        _readString(map, 'basis'),
        NutritionBasis.values,
        'food.basis',
      ),
      nutrition: NutritionValues(
        calories: _readDouble(nutrition, 'calories'),
        protein: _readDouble(nutrition, 'protein'),
        fat: _readDouble(nutrition, 'fat'),
        carbs: _readDouble(nutrition, 'carbs'),
      ),
    );
  }

  DishItem _decodeDish(Object? encoded) {
    final map = _asMap(encoded, 'recipe');
    return DishItem(
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      description: _readString(map, 'description'),
      servingSizeGrams: _readDouble(map, 'servingSizeGrams'),
      components: _readList(map, 'components')
          .map((raw) {
            final component = _asMap(raw, 'recipe component');
            return DishComponent(
              itemId: _readString(component, 'itemId'),
              grams: _readDouble(component, 'grams'),
            );
          })
          .toList(growable: false),
    );
  }

  Exercise _decodeExercise(Object? encoded) {
    final map = _asMap(encoded, 'exercise');
    return Exercise(
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      description: _readString(map, 'description'),
      instruction: _readString(map, 'instruction'),
      muscleGroups: _readList(map, 'muscleGroups')
          .map(
            (raw) => _readEnum(
              _asString(raw, 'exercise.muscleGroups'),
              MuscleGroup.values,
              'exercise.muscleGroups',
            ),
          )
          .toList(growable: false),
      measurementType: _readEnum(
        _readString(map, 'measurementType'),
        ExerciseMeasurementType.values,
        'exercise.measurementType',
      ),
    );
  }

  TrainingPlan _decodePlan(Object? encoded) {
    final map = _asMap(encoded, 'training plan');
    return TrainingPlan(
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      description: _readString(map, 'description'),
      exercises: _readList(map, 'exercises')
          .map((raw) {
            final exercise = _asMap(raw, 'training exercise');
            return TrainingExercise(
              exerciseId: _readString(exercise, 'exerciseId'),
              sets: _readNullableDouble(exercise, 'sets'),
              reps: _readNullableDouble(exercise, 'reps'),
              weightGrams: _readNullableDouble(exercise, 'weightGrams'),
              durationSeconds: _readNullableDouble(exercise, 'durationSeconds'),
              distanceMeters: _readNullableDouble(exercise, 'distanceMeters'),
              assistanceWeightGrams: _readNullableDouble(
                exercise,
                'assistanceWeightGrams',
              ),
            );
          })
          .toList(growable: false),
    );
  }

  String? _validateValue(
    LibraryCategory category,
    Object value, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final id = _idOf(value)!;
    final name = _nameOf(value)!;
    if (id.trim().isEmpty) {
      return 'The id must not be empty.';
    }
    if (name.trim().isEmpty) {
      return 'The name must not be empty.';
    }
    final existing = _existingValue(value);
    if (existing != null && existing.runtimeType != value.runtimeType) {
      return 'The id "$id" belongs to a different item type.';
    }
    final duplicateName = _duplicateName(value, packageValues);
    if (duplicateName != null) {
      return 'The name "$name" is already used by "$duplicateName".';
    }

    return switch ((category, value)) {
      (LibraryCategory.foods, final FoodItem food) => _validateFood(food),
      (LibraryCategory.recipes, final DishItem dish) => _validateDish(
        dish,
        references: references,
        packageValues: packageValues,
      ),
      (LibraryCategory.exercises, final Exercise exercise) => _validateExercise(
        exercise,
      ),
      (LibraryCategory.trainingPlans, final TrainingPlan plan) => _validatePlan(
        plan,
        references: references,
        packageValues: packageValues,
      ),
      _ => 'The item type does not match ${category.name}.',
    };
  }

  String? _validateFood(FoodItem food) {
    if (!food.servingSizeGrams.isFinite || food.servingSizeGrams <= 0) {
      return 'Serving size must be greater than zero.';
    }
    final values = [
      food.nutrition.calories,
      food.nutrition.protein,
      food.nutrition.fat,
      food.nutrition.carbs,
    ];
    if (values.any((value) => !value.isFinite || value < 0)) {
      return 'Nutrition values must be finite and non-negative.';
    }
    return null;
  }

  String? _validateExercise(Exercise exercise) {
    if (exercise.description.trim().isEmpty) {
      return 'Exercise description must not be empty.';
    }
    if (exercise.instruction.trim().isEmpty) {
      return 'Exercise instruction must not be empty.';
    }
    if (exercise.muscleGroups.isEmpty) {
      return 'Exercise must have at least one muscle group.';
    }
    final current = _store.exerciseById(exercise.id);
    if (current != null &&
        current.measurementType != exercise.measurementType) {
      final usedByPlan = _store.trainingPlans.any(
        (plan) =>
            plan.exercises.any((target) => target.exerciseId == exercise.id),
      );
      final usedByActive =
          _store.activeWorkoutSession?.results.any(
            (result) => result.exerciseId == exercise.id,
          ) ??
          false;
      if (usedByPlan || usedByActive) {
        return 'Measurement type cannot change while the exercise is in use.';
      }
    }
    return null;
  }

  String? _validatePlan(
    TrainingPlan plan, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    if (plan.exercises.isEmpty) {
      return 'Training plan must contain at least one exercise.';
    }
    for (final target in plan.exercises) {
      final exercise = _resolveExercise(
        target.exerciseId,
        references: references,
        packageValues: packageValues,
      );
      if (exercise == null) {
        return 'Missing exercise reference "${target.exerciseId}".';
      }
      if (_store.exerciseById(target.exerciseId) == null) {
        final referenceError = _validateReference(exercise, packageValues);
        if (referenceError != null) {
          return '${exercise.name}: $referenceError';
        }
      }
      final error = _validateTrainingExercise(target, exercise.measurementType);
      if (error != null) {
        return '${exercise.name}: $error';
      }
    }
    return null;
  }

  String? _validateTrainingExercise(
    TrainingExercise target,
    ExerciseMeasurementType type,
  ) {
    final values = <String, double?>{
      'sets': target.sets,
      'reps': target.reps,
      'weightGrams': target.weightGrams,
      'durationSeconds': target.durationSeconds,
      'distanceMeters': target.distanceMeters,
      'assistanceWeightGrams': target.assistanceWeightGrams,
    };
    for (final entry in values.entries) {
      final value = entry.value;
      if (value != null && (!value.isFinite || value < 0)) {
        return '${entry.key} must be finite and non-negative.';
      }
    }
    final disallowed = switch (type) {
      ExerciseMeasurementType.strength => [
        'durationSeconds',
        'distanceMeters',
        'assistanceWeightGrams',
      ],
      ExerciseMeasurementType.bodyweight => [
        'weightGrams',
        'durationSeconds',
        'distanceMeters',
        'assistanceWeightGrams',
      ],
      ExerciseMeasurementType.duration => [
        'reps',
        'weightGrams',
        'distanceMeters',
        'assistanceWeightGrams',
      ],
      ExerciseMeasurementType.weightedDuration => [
        'reps',
        'distanceMeters',
        'assistanceWeightGrams',
      ],
      ExerciseMeasurementType.cardio => [
        'reps',
        'weightGrams',
        'assistanceWeightGrams',
      ],
      ExerciseMeasurementType.assisted => [
        'weightGrams',
        'durationSeconds',
        'distanceMeters',
      ],
    };
    for (final field in disallowed) {
      if (values[field] != null) {
        return '$field is not allowed for ${type.name} exercises.';
      }
    }
    return null;
  }

  String? _validateDish(
    DishItem dish, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final shapeError = _validateDishShape(dish);
    if (shapeError != null) {
      return shapeError;
    }
    final dependencyError = _validateDishDependencies(
      dish,
      references: references,
      packageValues: packageValues,
      visited: <String>{},
    );
    if (dependencyError != null) {
      return dependencyError;
    }
    if (_hasDishCycle(
      dish.id,
      references: references,
      packageValues: packageValues,
    )) {
      return 'Recipe dependency cycle detected.';
    }
    return null;
  }

  String? _validateDishShape(DishItem dish) {
    if (!dish.servingSizeGrams.isFinite || dish.servingSizeGrams <= 0) {
      return 'Serving size must be greater than zero.';
    }
    if (dish.components.isEmpty) {
      return 'Recipe must contain at least one component.';
    }
    if (dish.components.any(
      (component) => !component.grams.isFinite || component.grams <= 0,
    )) {
      return 'Component grams must be greater than zero.';
    }
    return null;
  }

  String? _validateDishDependencies(
    DishItem dish, {
    required _References references,
    required Map<String, Object> packageValues,
    required Set<String> visited,
  }) {
    if (!visited.add(dish.id)) {
      return null;
    }
    for (final component in dish.components) {
      final resolved = _resolveCatalogItem(
        component.itemId,
        references: references,
        packageValues: packageValues,
      );
      if (resolved == null) {
        return 'Missing food or recipe reference "${component.itemId}".';
      }
      if (_store.itemById(component.itemId) != null) {
        continue;
      }
      final referenceError = _validateReference(resolved, packageValues);
      if (referenceError != null) {
        return '${_nameOf(resolved)}: $referenceError';
      }
      if (resolved is DishItem) {
        final nestedError = _validateDishDependencies(
          resolved,
          references: references,
          packageValues: packageValues,
          visited: visited,
        );
        if (nestedError != null) {
          return nestedError;
        }
      }
    }
    return null;
  }

  String? _validateReference(Object value, Map<String, Object> packageValues) {
    final id = _idOf(value);
    final name = _nameOf(value);
    if (id == null || id.trim().isEmpty) {
      return 'Reference id must not be empty.';
    }
    if (name == null || name.trim().isEmpty) {
      return 'Reference name must not be empty.';
    }
    final duplicateName = _duplicateName(value, packageValues);
    if (duplicateName != null) {
      return 'The name "$name" is already used by "$duplicateName".';
    }
    return switch (value) {
      final FoodItem food => _validateFood(food),
      final DishItem dish => _validateDishShape(dish),
      final Exercise exercise => _validateExercise(exercise),
      _ => 'Unsupported reference type ${value.runtimeType}.',
    };
  }

  String? _duplicateName(Object value, Map<String, Object> packageValues) {
    final id = _idOf(value)!;
    final normalized = _normalizeName(_nameOf(value)!);
    final candidates = value is FoodItem || value is DishItem
        ? <Object>[
            ..._store.items.map(
              (item) => item.isFood ? item.food! : item.dish!,
            ),
            ...packageValues.values.where(
              (entry) => entry is FoodItem || entry is DishItem,
            ),
          ]
        : value is Exercise
        ? <Object>[
            ..._store.exercises,
            ...packageValues.values.whereType<Exercise>(),
          ]
        : <Object>[
            ..._store.trainingPlans,
            ...packageValues.values.whereType<TrainingPlan>(),
          ];
    for (final candidate in candidates) {
      if (_idOf(candidate) == id) {
        continue;
      }
      if (_normalizeName(_nameOf(candidate)!) == normalized) {
        return _nameOf(candidate);
      }
    }
    return null;
  }

  List<Object> _missingReferences(
    LibraryCategory category,
    Object value, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final missing = <String, Object>{};
    if (category == LibraryCategory.trainingPlans) {
      for (final target in (value as TrainingPlan).exercises) {
        if (_store.exerciseById(target.exerciseId) == null &&
            packageValues[target.exerciseId] == null) {
          final reference = references.exercises[target.exerciseId];
          if (reference != null) {
            missing[target.exerciseId] = reference;
          }
        }
      }
    } else if (category == LibraryCategory.recipes) {
      void collect(DishItem dish) {
        for (final component in dish.components) {
          if (_store.itemById(component.itemId) != null ||
              missing.containsKey(component.itemId)) {
            continue;
          }
          final reference =
              packageValues[component.itemId] ??
              references.catalogValue(component.itemId);
          if (reference == null) {
            continue;
          }
          missing[component.itemId] = reference;
          if (reference is DishItem) {
            collect(reference);
          }
        }
      }

      collect(value as DishItem);
    }
    return missing.values.toList(growable: false);
  }

  Exercise? _resolveExercise(
    String id, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final packaged = packageValues[id];
    return _store.exerciseById(id) ??
        (packaged is Exercise ? packaged : null) ??
        references.exercises[id];
  }

  Object? _resolveCatalogItem(
    String id, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final packaged = packageValues[id];
    if (packaged is FoodItem || packaged is DishItem) {
      return packaged;
    }
    final current = _store.itemById(id);
    if (current != null) {
      return current.isFood ? current.food : current.dish;
    }
    return references.catalogValue(id);
  }

  bool _hasDishCycle(
    String rootId, {
    required _References references,
    required Map<String, Object> packageValues,
  }) {
    final visiting = <String>{};
    final visited = <String>{};

    bool visit(String id) {
      if (visiting.contains(id)) {
        return true;
      }
      if (!visited.add(id)) {
        return false;
      }
      final resolved = _resolveCatalogItem(
        id,
        references: references,
        packageValues: packageValues,
      );
      if (resolved is! DishItem) {
        return false;
      }
      visiting.add(id);
      for (final component in resolved.components) {
        if (visit(component.itemId)) {
          return true;
        }
      }
      visiting.remove(id);
      return false;
    }

    return visit(rootId);
  }

  List<LibraryImportEntry> _sortForImport(List<LibraryImportEntry> entries) {
    if (entries.every((entry) => entry.value is! DishItem)) {
      return entries;
    }
    final byId = <String, LibraryImportEntry>{
      for (final entry in entries) entry.id: entry,
    };
    final sorted = <LibraryImportEntry>[];
    final visited = <String>{};

    void visit(LibraryImportEntry entry) {
      if (!visited.add(entry.id)) {
        return;
      }
      final value = entry.value;
      if (value is DishItem) {
        for (final component in value.components) {
          final dependency = byId[component.itemId];
          if (dependency != null) {
            visit(dependency);
          }
        }
      }
      sorted.add(entry);
    }

    for (final entry in entries) {
      visit(entry);
    }
    return sorted;
  }

  List<Object> _sortReferences(List<Object> references) {
    final byId = <String, Object>{
      for (final value in references) _idOf(value)!: value,
    };
    final sorted = <Object>[];
    final visited = <String>{};

    void visit(Object value) {
      final id = _idOf(value)!;
      if (!visited.add(id)) {
        return;
      }
      if (value is DishItem) {
        for (final component in value.components) {
          final dependency = byId[component.itemId];
          if (dependency != null) {
            visit(dependency);
          }
        }
      }
      sorted.add(value);
    }

    for (final value in references) {
      visit(value);
    }
    return sorted;
  }

  Object _copyValue(Object value) {
    final id = _store.createId();
    final name = _availableCopyName(value);
    return switch (value) {
      final FoodItem food => food.copyWith(id: id, name: name),
      final DishItem dish => dish.copyWith(id: id, name: name),
      final Exercise exercise => exercise.copyWith(id: id, name: name),
      final TrainingPlan plan => plan.copyWith(id: id, name: name),
      _ => throw ArgumentError(
        'Unsupported library value ${value.runtimeType}.',
      ),
    };
  }

  String _availableCopyName(Object value) {
    final base = '${_nameOf(value)} (copy)';
    var candidate = base;
    var index = 2;
    bool isUsed(String name) {
      final normalized = _normalizeName(name);
      final values = value is FoodItem || value is DishItem
          ? _store.items.map((item) => item.name)
          : value is Exercise
          ? _store.exercises.map((item) => item.name)
          : _store.trainingPlans.map((item) => item.name);
      return values.any((existing) => _normalizeName(existing) == normalized);
    }

    while (isUsed(candidate)) {
      candidate = '$base $index';
      index += 1;
    }
    return candidate;
  }

  Object? _existingValue(Object value) {
    return switch (value) {
      final FoodItem food => switch (_store.itemById(food.id)) {
        final CatalogItem item when item.isFood => item.food,
        final CatalogItem item => item.dish,
        null => null,
      },
      final DishItem dish => switch (_store.itemById(dish.id)) {
        final CatalogItem item when item.isDish => item.dish,
        final CatalogItem item => item.food,
        null => null,
      },
      final Exercise exercise => _store.exerciseById(exercise.id),
      final TrainingPlan plan => _store.trainingPlanById(plan.id),
      _ => null,
    };
  }

  void _createValue(Object value) {
    switch (value) {
      case final FoodItem food:
        _store.createFood(food);
      case final DishItem dish:
        _store.createDish(dish);
      case final Exercise exercise:
        _store.createExercise(exercise);
      case final TrainingPlan plan:
        _store.createTrainingPlan(plan);
      default:
        throw ArgumentError('Unsupported library value ${value.runtimeType}.');
    }
  }

  void _updateValue(Object value) {
    switch (value) {
      case final FoodItem food:
        _store.updateFood(food);
      case final DishItem dish:
        _store.updateDish(dish);
      case final Exercise exercise:
        _store.updateExercise(exercise);
      case final TrainingPlan plan:
        _store.updateTrainingPlan(plan);
      default:
        throw ArgumentError('Unsupported library value ${value.runtimeType}.');
    }
  }

  void _deleteValue(Object value) {
    switch (value) {
      case final FoodItem food:
        _store.deleteItem(food.id);
      case final DishItem dish:
        _store.deleteItem(dish.id);
      case final Exercise exercise:
        _store.deleteExercise(exercise.id);
      case final TrainingPlan plan:
        _store.deleteTrainingPlan(plan.id);
    }
  }

  String _messageFor(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? error.toString();
    }
    if (error is StateError) {
      return error.message;
    }
    return error.toString();
  }

  String _fallbackName(Object? value, int index) {
    if (value is Map && value['name'] is String) {
      return value['name'] as String;
    }
    return 'Item ${index + 1}';
  }

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String? _idOf(Object? value) => switch (value) {
    final FoodItem item => item.id,
    final DishItem item => item.id,
    final Exercise item => item.id,
    final TrainingPlan item => item.id,
    _ => null,
  };

  String? _nameOf(Object? value) => switch (value) {
    final FoodItem item => item.name,
    final DishItem item => item.name,
    final Exercise item => item.name,
    final TrainingPlan item => item.name,
    _ => null,
  };

  Map<String, Object?> _asMap(Object? value, String name) {
    if (value is! Map) {
      throw FormatException('Expected $name to be a JSON object.');
    }
    return value.map((key, value) {
      if (key is! String) {
        throw FormatException('Expected $name keys to be strings.');
      }
      return MapEntry(key, value);
    });
  }

  List<Object?> _readList(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! List) {
      throw FormatException('Expected "$key" to be a JSON array.');
    }
    return value;
  }

  List<Object?> _readOptionalList(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) {
      return const [];
    }
    return _readList(map, key);
  }

  String _readString(Map<String, Object?> map, String key) =>
      _asString(map[key], key);

  String _asString(Object? value, String name) {
    if (value is! String) {
      throw FormatException('Expected "$name" to be a string.');
    }
    return value;
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('Expected "$key" to be an integer.');
    }
    return value;
  }

  double _readDouble(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! num) {
      throw FormatException('Expected "$key" to be a number.');
    }
    return value.toDouble();
  }

  double? _readNullableDouble(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) {
      return null;
    }
    if (value is! num) {
      throw FormatException('Expected "$key" to be a number or null.');
    }
    return value.toDouble();
  }

  T _readEnum<T extends Enum>(String name, List<T> values, String field) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw FormatException('Unknown $field value "$name".');
  }
}

class _ParsedEntry {
  const _ParsedEntry({
    required this.index,
    this.value,
    this.error,
    this.fallbackName,
  });

  final int index;
  final Object? value;
  final String? error;
  final String? fallbackName;
}

class _References {
  const _References({
    this.foods = const {},
    this.recipes = const {},
    this.exercises = const {},
  });

  final Map<String, FoodItem> foods;
  final Map<String, DishItem> recipes;
  final Map<String, Exercise> exercises;

  Object? catalogValue(String id) => foods[id] ?? recipes[id];
}
