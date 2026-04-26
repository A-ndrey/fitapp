import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../state/app_store.dart';

String formatNutritionNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String formatNutritionLine(NutritionValues values) {
  return '${formatNutritionNumber(values.calories)} kcal • '
      '${formatNutritionNumber(values.protein)} g protein • '
      '${formatNutritionNumber(values.fat)} g fat • '
      '${formatNutritionNumber(values.carbs)} g carbs';
}

String formatMealQuantity(MealEntry entry, AppStore store) {
  if (entry.mode == MealEntryMode.grams) {
    return store.formatDishWeight(entry.enteredQuantity);
  }
  return '${formatNutritionNumber(entry.enteredQuantity)} servings';
}
