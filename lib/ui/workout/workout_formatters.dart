import '../../models/app_preferences.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../state/app_store.dart';

enum WorkoutLogField { reps, weight, duration, distance, assistanceWeight }

String formatWorkoutDuration(
  Duration duration, {
  String hourUnit = 'h',
  String minuteUnit = 'min',
  String secondUnit = 'sec',
}) {
  if (duration.inHours > 0) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0
        ? '$hours $hourUnit'
        : '$hours $hourUnit $minutes $minuteUnit';
  }
  if (duration.inMinutes > 0) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return seconds == 0
        ? '$minutes $minuteUnit'
        : '$minutes $minuteUnit $seconds $secondUnit';
  }
  if (duration.inSeconds > 0) {
    return '${duration.inSeconds} $secondUnit';
  }
  return '0 $minuteUnit';
}

String formatWorkoutDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatWorkoutNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String formatWorkoutSetCount(
  int count, {
  String Function(int count)? setCountLoggedLabel,
}) {
  if (setCountLoggedLabel != null) {
    return setCountLoggedLabel(count);
  }
  if (count == 1) {
    return '1 set logged';
  }
  return '$count sets logged';
}

String formatWorkoutTarget(
  TrainingExercise target,
  ExerciseMeasurementType measurementType,
  AppStore store, {
  String targetPrefix = 'Target:',
  String setsLabel = 'sets',
  String repsLabel = 'reps',
  String assistanceLabel = 'assistance',
}) {
  final parts = _formatTrainingExerciseParts(
    target,
    measurementType,
    store,
    setsLabel: setsLabel,
    repsLabel: repsLabel,
    assistanceLabel: assistanceLabel,
  );
  return '$targetPrefix ${parts.join(' • ')}';
}

String formatWorkoutSetLog(
  WorkoutSetLog setLog,
  ExerciseMeasurementType measurementType,
  AppStore store, {
  String repsLabel = 'reps',
  String assistanceLabel = 'assistance',
}) {
  return _formatWorkoutSetLogParts(
    setLog,
    measurementType,
    store,
    repsLabel: repsLabel,
    assistanceLabel: assistanceLabel,
  ).join(' • ');
}

String formatWorkoutInputNumber(double? value) {
  if (value == null) {
    return '';
  }
  return formatWorkoutNumber(value);
}

String formatWorkoutInputValue(
  WorkoutLogField field,
  double? normalizedValue,
  AppStore store,
) {
  if (normalizedValue == null) {
    return '';
  }
  switch (field) {
    case WorkoutLogField.reps:
    case WorkoutLogField.duration:
      return formatWorkoutNumber(normalizedValue);
    case WorkoutLogField.weight:
    case WorkoutLogField.assistanceWeight:
      return formatWorkoutNumber(_kilogramsFromGrams(normalizedValue, store));
    case WorkoutLogField.distance:
      return formatWorkoutNumber(_distanceFromMeters(normalizedValue, store));
  }
}

double? parseWorkoutInputValue(
  String text,
  WorkoutLogField field,
  AppStore store,
) {
  final normalized = text.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final value = double.tryParse(normalized);
  if (value == null) {
    return double.nan;
  }
  switch (field) {
    case WorkoutLogField.reps:
    case WorkoutLogField.duration:
      return value;
    case WorkoutLogField.weight:
    case WorkoutLogField.assistanceWeight:
      return _gramsFromKilograms(value, store);
    case WorkoutLogField.distance:
      return _metersFromDistance(value, store);
  }
}

List<WorkoutLogField> workoutFieldsForMeasurementType(
  ExerciseMeasurementType measurementType,
) {
  switch (measurementType) {
    case ExerciseMeasurementType.strength:
      return const [WorkoutLogField.reps, WorkoutLogField.weight];
    case ExerciseMeasurementType.bodyweight:
      return const [WorkoutLogField.reps];
    case ExerciseMeasurementType.duration:
      return const [WorkoutLogField.duration];
    case ExerciseMeasurementType.weightedDuration:
      return const [WorkoutLogField.weight, WorkoutLogField.duration];
    case ExerciseMeasurementType.cardio:
      return const [WorkoutLogField.duration, WorkoutLogField.distance];
    case ExerciseMeasurementType.assisted:
      return const [WorkoutLogField.reps, WorkoutLogField.assistanceWeight];
  }
}

String preferredWorkoutFieldUnit(WorkoutLogField field, AppStore store) {
  switch (field) {
    case WorkoutLogField.reps:
      return '';
    case WorkoutLogField.weight:
    case WorkoutLogField.assistanceWeight:
      return store.workoutWeightUnit == WorkoutWeightUnit.pounds ? 'lbs' : 'kg';
    case WorkoutLogField.duration:
      return 'sec';
    case WorkoutLogField.distance:
      return store.distanceUnit == DistanceUnit.miles ? 'miles' : 'km';
  }
}

List<String> _formatTrainingExerciseParts(
  TrainingExercise target,
  ExerciseMeasurementType measurementType,
  AppStore store, {
  required String setsLabel,
  required String repsLabel,
  required String assistanceLabel,
}) {
  final parts = <String>[];
  switch (measurementType) {
    case ExerciseMeasurementType.strength:
      _addSetCount(parts, target.sets, setsLabel);
      _addReps(parts, target.reps, repsLabel);
      _addWeight(parts, target.weightGrams, store);
      break;
    case ExerciseMeasurementType.bodyweight:
      _addSetCount(parts, target.sets, setsLabel);
      _addReps(parts, target.reps, repsLabel);
      break;
    case ExerciseMeasurementType.duration:
      _addSetCount(parts, target.sets, setsLabel);
      _addDuration(parts, target.durationSeconds);
      break;
    case ExerciseMeasurementType.weightedDuration:
      _addSetCount(parts, target.sets, setsLabel);
      _addWeight(parts, target.weightGrams, store);
      _addDuration(parts, target.durationSeconds);
      break;
    case ExerciseMeasurementType.cardio:
      _addDuration(parts, target.durationSeconds);
      _addDistance(parts, target.distanceMeters, store);
      break;
    case ExerciseMeasurementType.assisted:
      _addSetCount(parts, target.sets, setsLabel);
      _addReps(parts, target.reps, repsLabel);
      _addWeight(
        parts,
        target.assistanceWeightGrams,
        store,
        suffix: assistanceLabel,
      );
      break;
  }
  return parts;
}

List<String> _formatWorkoutSetLogParts(
  WorkoutSetLog setLog,
  ExerciseMeasurementType measurementType,
  AppStore store, {
  required String repsLabel,
  required String assistanceLabel,
}) {
  final parts = <String>[];
  switch (measurementType) {
    case ExerciseMeasurementType.strength:
      _addReps(parts, setLog.reps, repsLabel);
      _addWeight(parts, setLog.weightGrams, store);
      break;
    case ExerciseMeasurementType.bodyweight:
      _addReps(parts, setLog.reps, repsLabel);
      break;
    case ExerciseMeasurementType.duration:
      _addDuration(parts, setLog.durationSeconds);
      break;
    case ExerciseMeasurementType.weightedDuration:
      _addWeight(parts, setLog.weightGrams, store);
      _addDuration(parts, setLog.durationSeconds);
      break;
    case ExerciseMeasurementType.cardio:
      _addDuration(parts, setLog.durationSeconds);
      _addDistance(parts, setLog.distanceMeters, store);
      break;
    case ExerciseMeasurementType.assisted:
      _addReps(parts, setLog.reps, repsLabel);
      _addWeight(
        parts,
        setLog.assistanceWeightGrams,
        store,
        suffix: assistanceLabel,
      );
      break;
  }
  return parts;
}

void _addSetCount(List<String> parts, double? sets, String setsLabel) {
  if (sets == null) {
    return;
  }
  parts.add('${formatWorkoutNumber(sets)} $setsLabel');
}

void _addReps(List<String> parts, double? reps, String repsLabel) {
  if (reps == null) {
    return;
  }
  parts.add('${formatWorkoutNumber(reps)} $repsLabel');
}

void _addWeight(
  List<String> parts,
  double? grams,
  AppStore store, {
  String? suffix,
}) {
  if (grams == null) {
    return;
  }
  final weight = store.formatWorkoutWeight(grams / 1000);
  parts.add(suffix == null ? weight : '$weight $suffix');
}

void _addDuration(List<String> parts, double? durationSeconds) {
  if (durationSeconds == null) {
    return;
  }
  parts.add(formatWorkoutDuration(Duration(seconds: durationSeconds.round())));
}

void _addDistance(List<String> parts, double? distanceMeters, AppStore store) {
  if (distanceMeters == null) {
    return;
  }
  parts.add(store.formatDistance(distanceMeters / 1000));
}

double _kilogramsFromGrams(double grams, AppStore store) {
  final kilograms = grams / 1000;
  if (store.workoutWeightUnit == WorkoutWeightUnit.kilograms) {
    return kilograms;
  }
  return kilograms * 2.2046226218;
}

double _gramsFromKilograms(double value, AppStore store) {
  if (store.workoutWeightUnit == WorkoutWeightUnit.kilograms) {
    return value * 1000;
  }
  return (value / 2.2046226218) * 1000;
}

double _distanceFromMeters(double meters, AppStore store) {
  final kilometers = meters / 1000;
  if (store.distanceUnit == DistanceUnit.kilometers) {
    return kilometers;
  }
  return kilometers / 1.609344;
}

double _metersFromDistance(double value, AppStore store) {
  if (store.distanceUnit == DistanceUnit.kilometers) {
    return value * 1000;
  }
  return value * 1.609344 * 1000;
}
