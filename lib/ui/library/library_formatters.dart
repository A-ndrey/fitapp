import '../../models/catalog_item.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../state/app_store.dart';

String formatCatalogItemTypeLabel(
  CatalogItem item, {
  String foodLabel = 'food',
  String dishLabel = 'recipe',
}) {
  return item.isFood ? foodLabel : dishLabel;
}

String formatCatalogNutritionServingLabel(
  CatalogItem item,
  AppStore store, {
  String servingLabel = 'serving',
}) {
  return '${store.formatDishWeight(item.servingSizeGrams)} $servingLabel';
}

String formatCatalogCaloriesPerServingLabel(
  CatalogItem item,
  AppStore store, {
  String Function(String calories)? caloriesPerServing,
}) {
  final nutrition = item.nutritionPerServing(store.catalog);
  final calories = _formatCompactNumber(nutrition.calories);
  return caloriesPerServing?.call(calories) ?? '$calories kcal per serving';
}

String formatCatalogServingNutritionLabel(
  CatalogItem item,
  AppStore store, {
  String servingLabel = 'serving',
  String Function(String calories)? caloriesPerServing,
}) {
  return '${formatCatalogNutritionServingLabel(item, store, servingLabel: servingLabel)} • '
      '${formatCatalogCaloriesPerServingLabel(item, store, caloriesPerServing: caloriesPerServing)}';
}

String formatTrainingPlanSummaryLabel(
  TrainingPlan plan, {
  String Function(int count)? exerciseCountLabel,
}) {
  final exerciseLabel =
      exerciseCountLabel?.call(plan.exercises.length) ??
      formatLibraryCountLabel(plan.exercises.length, 'exercise');
  final description = plan.description.trim();
  if (description.isEmpty) {
    return exerciseLabel;
  }
  return '$exerciseLabel\n$description';
}

String formatExerciseMuscleGroupSummaryLabel(
  List<MuscleGroup> muscleGroups, {
  String emptyLabel = 'Muscles: -',
}) {
  if (muscleGroups.isEmpty) {
    return emptyLabel;
  }
  return muscleGroups.map((group) => group.label).join(', ');
}

String formatLibraryCountLabel(int count, String singular, [String? plural]) {
  final label = count == 1 ? singular : plural ?? '${singular}s';
  return '$count $label';
}

String _formatCompactNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
