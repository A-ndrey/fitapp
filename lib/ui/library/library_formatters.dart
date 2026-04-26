import '../../models/catalog_item.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../state/app_store.dart';

String formatCatalogItemTypeLabel(CatalogItem item) {
  return item.isFood ? 'food' : 'dish';
}

String formatCatalogNutritionServingLabel(CatalogItem item, AppStore store) {
  return '${store.formatDishWeight(item.servingSizeGrams)} serving';
}

String formatCatalogCaloriesPerServingLabel(CatalogItem item, AppStore store) {
  final nutrition = item.nutritionPerServing(store.catalog);
  return '${_formatCompactNumber(nutrition.calories)} kcal per serving';
}

String formatCatalogServingNutritionLabel(CatalogItem item, AppStore store) {
  return '${formatCatalogNutritionServingLabel(item, store)} • '
      '${formatCatalogCaloriesPerServingLabel(item, store)}';
}

String formatTrainingPlanSummaryLabel(TrainingPlan plan) {
  final exerciseLabel = formatLibraryCountLabel(
    plan.exercises.length,
    'exercise',
  );
  final description = plan.description.trim();
  if (description.isEmpty) {
    return exerciseLabel;
  }
  return '$exerciseLabel\n$description';
}

String formatExerciseMuscleGroupSummaryLabel(List<MuscleGroup> muscleGroups) {
  if (muscleGroups.isEmpty) {
    return 'Muscles: -';
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
