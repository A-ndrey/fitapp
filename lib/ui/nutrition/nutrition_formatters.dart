import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../state/app_store.dart';

String formatNutritionNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String formatNutritionLine(
  NutritionValues values, {
  String kilocalorieLabel = 'kcal',
  String gramLabel = 'g',
  String proteinLabel = 'protein',
  String fatLabel = 'fat',
  String carbsLabel = 'carbs',
}) {
  return '${formatNutritionNumber(values.calories)} $kilocalorieLabel • '
      '${formatNutritionNumber(values.protein)} $gramLabel $proteinLabel • '
      '${formatNutritionNumber(values.fat)} $gramLabel $fatLabel • '
      '${formatNutritionNumber(values.carbs)} $gramLabel $carbsLabel';
}

String formatMealQuantity(
  MealEntry entry,
  AppStore store, {
  String servingsLabel = 'servings',
}) {
  if (entry.mode == MealEntryMode.grams) {
    return store.formatDishWeight(entry.enteredQuantity);
  }
  return '${formatNutritionNumber(entry.enteredQuantity)} $servingsLabel';
}
