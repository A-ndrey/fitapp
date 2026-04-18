import 'dish_item.dart';
import 'food_item.dart';
import 'nutrition.dart';

enum CatalogItemType {
  food,
  dish,
}

class CatalogItem {
  final CatalogItemType type;
  final FoodItem? _food;
  final DishItem? _dish;

  const CatalogItem.food(FoodItem food)
      : type = CatalogItemType.food,
        _food = food,
        _dish = null;

  const CatalogItem.dish(DishItem dish)
      : type = CatalogItemType.dish,
        _food = null,
        _dish = dish;

  FoodItem? get food => _food;

  DishItem? get dish => _dish;

  String get id => isFood ? _food!.id : _dish!.id;

  String get name => isFood ? _food!.name : _dish!.name;

  String get description => isFood ? _food!.description : _dish!.description;

  double get servingSizeGrams =>
      isFood ? _food!.servingSizeGrams : _dish!.servingSizeGrams;

  bool get isFood => type == CatalogItemType.food;

  bool get isDish => type == CatalogItemType.dish;

  NutritionValues nutritionForGrams(
    double grams,
    Map<String, CatalogItem> catalog, [
    Set<String>? visited,
  ]) {
    if (isFood) {
      return _food!.nutritionForGrams(grams);
    }
    return _dish!.nutritionForGrams(grams, catalog, visited);
  }

  NutritionValues nutritionPerServing(Map<String, CatalogItem> catalog) {
    if (isFood) {
      return _food!.nutritionPerServing;
    }
    return _dish!.nutritionPerServing(catalog);
  }
}
