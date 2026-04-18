import 'catalog_item.dart';
import 'nutrition.dart';

enum MealEntryMode { grams, servings }

class MealEntry {
  final String id;
  final String sourceItemId;
  final String itemName;
  final CatalogItemType itemType;
  final double servingSizeGrams;
  final double consumedGrams;
  final MealEntryMode mode;
  final double enteredQuantity;
  final NutritionValues nutrition;

  const MealEntry({
    required this.id,
    required this.sourceItemId,
    required this.itemName,
    required this.itemType,
    required this.servingSizeGrams,
    required this.consumedGrams,
    required this.mode,
    required this.enteredQuantity,
    required this.nutrition,
  });

  factory MealEntry.fromItem({
    required String id,
    required CatalogItem item,
    required double consumedGrams,
    required MealEntryMode mode,
    required double enteredQuantity,
    required Map<String, CatalogItem> catalog,
  }) {
    return MealEntry(
      id: id,
      sourceItemId: item.id,
      itemName: item.name,
      itemType: item.type,
      servingSizeGrams: item.servingSizeGrams,
      consumedGrams: consumedGrams,
      mode: mode,
      enteredQuantity: enteredQuantity,
      nutrition: item.nutritionForGrams(consumedGrams, catalog),
    );
  }
}
