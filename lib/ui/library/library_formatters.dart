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
  AppStore? store,
  String Function(int count)? exerciseCountLabel,
}) {
  final exerciseLabel =
      exerciseCountLabel?.call(plan.exercises.length) ??
      formatLibraryCountLabel(plan.exercises.length, 'exercise');
  final targetPreview = store == null || plan.exercises.isEmpty
      ? null
      : _formatTrainingExercisePreview(plan.exercises.first, store);
  final description = plan.description.trim();
  if (targetPreview == null && description.isEmpty) {
    return exerciseLabel;
  }
  final firstLine = targetPreview == null
      ? exerciseLabel
      : '$exerciseLabel • $targetPreview';
  if (description.isEmpty) {
    return firstLine;
  }
  return '$firstLine\n$description';
}

String? formatTrainingPlanFirstTargetLabel(TrainingPlan plan, AppStore store) {
  if (plan.exercises.isEmpty) {
    return null;
  }
  return _formatTrainingExercisePreview(plan.exercises.first, store);
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

String formatExerciseMeasurementTypeLabel(
  ExerciseMeasurementType measurementType,
) {
  switch (measurementType) {
    case ExerciseMeasurementType.strength:
      return 'Strength';
    case ExerciseMeasurementType.bodyweight:
      return 'Bodyweight';
    case ExerciseMeasurementType.duration:
      return 'Duration';
    case ExerciseMeasurementType.weightedDuration:
      return 'Weighted duration';
    case ExerciseMeasurementType.cardio:
      return 'Cardio';
    case ExerciseMeasurementType.assisted:
      return 'Assisted';
  }
}

List<String> formatTrainingExerciseDetailLines(
  TrainingExercise exercise,
  ExerciseMeasurementType measurementType,
  AppStore store, {
  String setsLabel = 'sets',
  String repsLabel = 'reps',
  String durationUnit = 'sec',
  String assistanceLabel = 'assistance',
}) {
  final details = <String>[];
  switch (measurementType) {
    case ExerciseMeasurementType.strength:
      _addIfPresent(details, _formatCountDetail(exercise.sets, setsLabel));
      _addIfPresent(details, _formatCountDetail(exercise.reps, repsLabel));
      _addIfPresent(details, _formatWeightDetail(exercise.weightGrams, store));
      break;
    case ExerciseMeasurementType.bodyweight:
      _addIfPresent(details, _formatCountDetail(exercise.sets, setsLabel));
      _addIfPresent(details, _formatCountDetail(exercise.reps, repsLabel));
      break;
    case ExerciseMeasurementType.duration:
      _addIfPresent(details, _formatCountDetail(exercise.sets, setsLabel));
      _addIfPresent(
        details,
        _formatDurationDetail(exercise.durationSeconds, durationUnit),
      );
      break;
    case ExerciseMeasurementType.weightedDuration:
      _addIfPresent(details, _formatCountDetail(exercise.sets, setsLabel));
      _addIfPresent(details, _formatWeightDetail(exercise.weightGrams, store));
      _addIfPresent(
        details,
        _formatDurationDetail(exercise.durationSeconds, durationUnit),
      );
      break;
    case ExerciseMeasurementType.cardio:
      _addIfPresent(
        details,
        _formatDurationDetail(exercise.durationSeconds, durationUnit),
      );
      _addIfPresent(
        details,
        _formatDistanceDetail(exercise.distanceMeters, store),
      );
      break;
    case ExerciseMeasurementType.assisted:
      _addIfPresent(details, _formatCountDetail(exercise.sets, setsLabel));
      _addIfPresent(details, _formatCountDetail(exercise.reps, repsLabel));
      _addIfPresent(
        details,
        _formatWeightDetail(
          exercise.assistanceWeightGrams,
          store,
          suffix: assistanceLabel,
        ),
      );
      break;
  }
  return details;
}

String formatLibraryCountLabel(int count, String singular, [String? plural]) {
  final label = count == 1 ? singular : plural ?? '${singular}s';
  return '$count $label';
}

String? _formatCountDetail(double? value, String label) {
  if (value == null) {
    return null;
  }
  return '${_formatCompactNumber(value)} $label';
}

String? _formatWeightDetail(double? grams, AppStore store, {String? suffix}) {
  if (grams == null) {
    return null;
  }
  final weight = store.formatWorkoutWeight(grams / 1000);
  if (suffix == null) {
    return weight;
  }
  return '$weight $suffix';
}

String? _formatDurationDetail(double? seconds, String durationUnit) {
  if (seconds == null) {
    return null;
  }
  return '${_formatCompactNumber(seconds)} $durationUnit';
}

String? _formatDistanceDetail(double? meters, AppStore store) {
  if (meters == null) {
    return null;
  }
  return store.formatDistance(meters / 1000);
}

void _addIfPresent(List<String> details, String? value) {
  if (value != null) {
    details.add(value);
  }
}

String? _formatTrainingExercisePreview(
  TrainingExercise exercise,
  AppStore store,
) {
  final measurementType = store
      .exerciseById(exercise.exerciseId)
      ?.measurementType;
  if (measurementType == null) {
    return null;
  }
  final details = formatTrainingExerciseDetailLines(
    exercise,
    measurementType,
    store,
  );
  if (details.isEmpty) {
    return null;
  }
  return details.join(' • ');
}

String _formatCompactNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
