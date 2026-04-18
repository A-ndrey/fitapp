import 'catalog_item.dart';
import 'nutrition.dart';

class DishComponent {
  final String itemId;
  final double grams;

  const DishComponent({required this.itemId, required this.grams});
}

class DishItem {
  final String id;
  final String name;
  final String description;
  final double servingSizeGrams;
  final List<DishComponent> components;

  const DishItem({
    required this.id,
    required this.name,
    required this.description,
    required this.servingSizeGrams,
    required this.components,
  });

  NutritionValues nutritionForGrams(
    double grams,
    Map<String, CatalogItem> catalog, [
    Set<String>? visited,
  ]) {
    final activeVisited = visited ?? <String>{};
    if (!activeVisited.add(id)) {
      return NutritionValues.zero;
    }

    if (servingSizeGrams <= 0) {
      activeVisited.remove(id);
      return NutritionValues.zero;
    }

    final factor = grams / servingSizeGrams;
    var total = NutritionValues.zero;
    for (final component in components) {
      final item = catalog[component.itemId];
      if (item == null) {
        continue;
      }
      total =
          total +
          item.nutritionForGrams(
            component.grams * factor,
            catalog,
            activeVisited,
          );
    }

    activeVisited.remove(id);
    return total;
  }

  NutritionValues nutritionPerServing(Map<String, CatalogItem> catalog) {
    return nutritionForGrams(servingSizeGrams, catalog);
  }

  DishItem copyWith({
    String? id,
    String? name,
    String? description,
    double? servingSizeGrams,
    List<DishComponent>? components,
  }) {
    return DishItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      components: components ?? this.components,
    );
  }
}
