import 'nutrition.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double servingSizeGrams;
  final NutritionBasis basis;
  final NutritionValues nutrition;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.servingSizeGrams,
    required this.basis,
    required this.nutrition,
  });

  NutritionValues get nutritionPerServing {
    if (basis == NutritionBasis.per100g) {
      return nutrition.scale(servingSizeGrams / 100.0);
    }
    return nutrition;
  }

  NutritionValues nutritionForGrams(double grams) {
    if (servingSizeGrams <= 0) {
      return NutritionValues.zero;
    }
    if (basis == NutritionBasis.per100g) {
      return nutrition.scale(grams / 100.0);
    }
    return nutrition.scale(grams / servingSizeGrams);
  }

  NutritionValues nutritionForServings(double servings) {
    return nutritionPerServing.scale(servings);
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? servingSizeGrams,
    NutritionBasis? basis,
    NutritionValues? nutrition,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      basis: basis ?? this.basis,
      nutrition: nutrition ?? this.nutrition,
    );
  }
}
