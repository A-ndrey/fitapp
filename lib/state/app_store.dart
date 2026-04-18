import 'package:flutter/foundation.dart';

import '../models/catalog_item.dart';
import '../models/dish_item.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/nutrition.dart';

class AppStore extends ChangeNotifier {
  AppStore() {
    _bootstrapSampleFoods();
  }

  AppStore.empty() : super();

  final Map<String, CatalogItem> _catalog = <String, CatalogItem>{};
  final List<MealEntry> _mealEntries = <MealEntry>[];
  int _mealEntryCounter = 0;

  void _bootstrapSampleFoods() {
    createFood(
      const FoodItem(
        id: 'carrot',
        name: 'Carrot',
        description: 'Raw carrot',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 41, protein: 0.9, fat: 0.2, carbs: 10),
      ),
    );
    createFood(
      const FoodItem(
        id: 'onion',
        name: 'Onion',
        description: 'Raw onion',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 40, protein: 1.1, fat: 0.1, carbs: 9.3),
      ),
    );
    createFood(
      const FoodItem(
        id: 'chicken-breast',
        name: 'Chicken breast',
        description: 'Cooked skinless chicken breast',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 165, protein: 31, fat: 3.6, carbs: 0),
      ),
    );
    createFood(
      const FoodItem(
        id: 'rice',
        name: 'Rice',
        description: 'Cooked white rice',
        servingSizeGrams: 150,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
      ),
    );
    createFood(
      const FoodItem(
        id: 'olive-oil',
        name: 'Olive oil',
        description: 'Extra virgin olive oil',
        servingSizeGrams: 10,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(calories: 90, protein: 0, fat: 10, carbs: 0),
      ),
    );
  }

  Map<String, CatalogItem> get catalog => Map.unmodifiable(_catalog);

  List<CatalogItem> get items => List.unmodifiable(_catalog.values);

  List<MealEntry> get mealEntries => List.unmodifiable(_mealEntries);

  NutritionValues get dailyTotals {
    var total = NutritionValues.zero;
    for (final entry in _mealEntries) {
      total = total + entry.nutrition;
    }
    return total;
  }

  CatalogItem? itemById(String id) => _catalog[id];

  List<CatalogItem> searchItems(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(normalizedQuery) ||
              item.description.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  void createFood(FoodItem food) {
    _validateFood(food);
    if (_catalog.containsKey(food.id)) {
      throw ArgumentError('Duplicate item id: ${food.id}');
    }
    _catalog[food.id] = CatalogItem.food(food);
    notifyListeners();
  }

  void updateFood(FoodItem food) {
    _validateFood(food);
    if (!_catalog.containsKey(food.id)) {
      throw ArgumentError('Missing item id: ${food.id}');
    }
    _catalog[food.id] = CatalogItem.food(food);
    notifyListeners();
  }

  void createDish(DishItem dish) {
    _validateDish(dish);
    if (_catalog.containsKey(dish.id)) {
      throw ArgumentError('Duplicate item id: ${dish.id}');
    }
    _catalog[dish.id] = CatalogItem.dish(_freezeDish(dish));
    notifyListeners();
  }

  void updateDish(DishItem dish) {
    _validateDish(dish);
    if (!_catalog.containsKey(dish.id)) {
      throw ArgumentError('Missing item id: ${dish.id}');
    }
    _catalog[dish.id] = CatalogItem.dish(_freezeDish(dish));
    notifyListeners();
  }

  void deleteItem(String id) {
    if (!_catalog.containsKey(id)) {
      throw ArgumentError('Missing item id: $id');
    }
    if (_isReferencedByAnyDish(id)) {
      throw StateError('Item is used by a dish.');
    }
    _catalog.remove(id);
    notifyListeners();
  }

  MealEntry addMealByGrams({required String itemId, required double grams}) {
    if (!grams.isFinite || grams <= 0) {
      throw ArgumentError.value(grams, 'grams', 'Must be greater than zero.');
    }
    final item = _catalog[itemId];
    if (item == null) {
      throw ArgumentError('Missing item id: $itemId');
    }
    final entry = MealEntry.fromItem(
      id: _nextMealEntryId(),
      item: item,
      consumedGrams: grams,
      mode: MealEntryMode.grams,
      enteredQuantity: grams,
      catalog: _catalog,
    );
    _mealEntries.add(entry);
    notifyListeners();
    return entry;
  }

  MealEntry addMealByServings({required String itemId, required double servings}) {
    if (!servings.isFinite || servings <= 0) {
      throw ArgumentError.value(servings, 'servings', 'Must be greater than zero.');
    }
    final item = _catalog[itemId];
    if (item == null) {
      throw ArgumentError('Missing item id: $itemId');
    }
    final grams = item.servingSizeGrams * servings;
    final entry = MealEntry.fromItem(
      id: _nextMealEntryId(),
      item: item,
      consumedGrams: grams,
      mode: MealEntryMode.servings,
      enteredQuantity: servings,
      catalog: _catalog,
    );
    _mealEntries.add(entry);
    notifyListeners();
    return entry;
  }

  void removeMealEntry(String id) {
    final before = _mealEntries.length;
    _mealEntries.removeWhere((entry) => entry.id == id);
    if (_mealEntries.length != before) {
      notifyListeners();
    }
  }

  String createIdFromName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    final buffer = StringBuffer();
    var lastWasHyphen = false;
    for (final codeUnit in normalized.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final isAlphaNumeric = (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNumeric) {
        buffer.write(char);
        lastWasHyphen = false;
      } else if (!lastWasHyphen) {
        buffer.write('-');
        lastWasHyphen = true;
      }
    }
    return buffer.toString().replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _validateFood(FoodItem food) {
    if (food.id.trim().isEmpty) {
      throw ArgumentError('Food id must not be empty.');
    }
    if (food.name.trim().isEmpty) {
      throw ArgumentError('Food name must not be empty.');
    }
    if (!food.servingSizeGrams.isFinite || food.servingSizeGrams <= 0) {
      throw ArgumentError('Serving size must be greater than zero.');
    }
    _validateNutrition(food.nutrition);
  }

  void _validateDish(DishItem dish) {
    if (dish.id.trim().isEmpty) {
      throw ArgumentError('Dish id must not be empty.');
    }
    if (dish.name.trim().isEmpty) {
      throw ArgumentError('Dish name must not be empty.');
    }
    if (!dish.servingSizeGrams.isFinite || dish.servingSizeGrams <= 0) {
      throw ArgumentError('Serving size must be greater than zero.');
    }
    if (dish.components.isEmpty) {
      throw ArgumentError('Dish must have at least one component.');
    }
    for (final component in dish.components) {
      if (!component.grams.isFinite || component.grams <= 0) {
        throw ArgumentError('Dish component grams must be greater than zero.');
      }
      if (component.itemId != dish.id && !_catalog.containsKey(component.itemId)) {
        throw ArgumentError('Missing item id: ${component.itemId}');
      }
    }

    final prospectiveCatalog = Map<String, CatalogItem>.from(_catalog);
    prospectiveCatalog[dish.id] = CatalogItem.dish(dish);
    _validateNoDishCycle(dish.id, prospectiveCatalog);
  }

  void _validateNutrition(NutritionValues nutrition) {
    if (!nutrition.calories.isFinite ||
        !nutrition.protein.isFinite ||
        !nutrition.fat.isFinite ||
        !nutrition.carbs.isFinite ||
        nutrition.calories < 0 ||
        nutrition.protein < 0 ||
        nutrition.fat < 0 ||
        nutrition.carbs < 0) {
      throw ArgumentError('Nutrition values must be non-negative.');
    }
  }

  bool _isReferencedByAnyDish(String targetId) {
    for (final item in _catalog.values) {
      if (!item.isDish) {
        continue;
      }
      if (_dishReferencesTarget(item.dish!, targetId, <String>{})) {
        return true;
      }
    }
    return false;
  }

  bool _dishReferencesTarget(
    DishItem dish,
    String targetId,
    Set<String> visited,
  ) {
    if (!visited.add(dish.id)) {
      return false;
    }
    for (final component in dish.components) {
      if (component.itemId == targetId) {
        return true;
      }
      final next = _catalog[component.itemId];
      if (next != null && next.isDish) {
        if (_dishReferencesTarget(next.dish!, targetId, visited)) {
          return true;
        }
      }
    }
    return false;
  }

  void _validateNoDishCycle(
    String rootId,
    Map<String, CatalogItem> catalog, [
    Set<String>? visiting,
    Set<String>? visited,
  ]) {
    final activeVisiting = visiting ?? <String>{};
    final activeVisited = visited ?? <String>{};
    if (activeVisiting.contains(rootId)) {
      throw ArgumentError('Dish cycle detected.');
    }
    if (activeVisited.contains(rootId)) {
      return;
    }
    final item = catalog[rootId];
    if (item == null || !item.isDish) {
      activeVisited.add(rootId);
      return;
    }
    activeVisiting.add(rootId);
    for (final component in item.dish!.components) {
      final next = catalog[component.itemId];
      if (next == null) {
        continue;
      }
      if (next.isDish) {
        _validateNoDishCycle(component.itemId, catalog, activeVisiting, activeVisited);
      }
      if (component.itemId == rootId) {
        throw ArgumentError('Dish cycle detected.');
      }
    }
    activeVisiting.remove(rootId);
    activeVisited.add(rootId);
  }

  String _nextMealEntryId() {
    _mealEntryCounter += 1;
    return 'meal-entry-${_mealEntryCounter.toString()}';
  }

  DishItem _freezeDish(DishItem dish) {
    return DishItem(
      id: dish.id,
      name: dish.name,
      description: dish.description,
      servingSizeGrams: dish.servingSizeGrams,
      components: List<DishComponent>.unmodifiable(
        List<DishComponent>.of(dish.components),
      ),
    );
  }
}
