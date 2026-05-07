import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../state/app_store.dart';

String formatWorkoutDuration(
  Duration duration, {
  String hourUnit = 'h',
  String minuteUnit = 'min',
}) {
  if (duration.inHours > 0) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return minutes == 0
        ? '$hours $hourUnit'
        : '$hours $hourUnit $minutes $minuteUnit';
  }
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes} $minuteUnit';
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
  AppStore store, {
  String targetPrefix = 'Target:',
  String setsLabel = 'sets',
  String repsLabel = 'reps',
}) {
  final parts = <String>[];
  if (target.sets != null) {
    parts.add('${formatWorkoutNumber(target.sets!)} $setsLabel');
  }
  if (target.reps != null) {
    parts.add('${formatWorkoutNumber(target.reps!)} $repsLabel');
  }
  if (target.weight != null) {
    parts.add(_formatWorkoutWeight(target.weight!, target.unit, store));
  } else if (target.time != null) {
    parts.add('${formatWorkoutNumber(target.time!)} ${target.unit}');
  } else if (parts.isEmpty) {
    parts.add(target.unit);
  }
  return '$targetPrefix ${parts.join(' • ')}';
}

String formatWorkoutSetLog(
  TrainingExercise target,
  WorkoutSetLog setLog,
  AppStore store, {
  String repsLabel = 'reps',
}) {
  final parts = <String>[];
  if (setLog.reps != null) {
    parts.add('${formatWorkoutNumber(setLog.reps!)} $repsLabel');
  }
  if (setLog.weight != null) {
    parts.add(_formatWorkoutWeight(setLog.weight!, target.unit, store));
  }
  if (setLog.time != null) {
    parts.add('${formatWorkoutNumber(setLog.time!)} ${target.unit}');
  }
  return parts.join(' • ');
}

String formatWorkoutInputNumber(double? value) {
  if (value == null) {
    return '';
  }
  return formatWorkoutNumber(value);
}

String _formatWorkoutWeight(double value, String unit, AppStore store) {
  if (unit == 'kg') {
    return store.formatWorkoutWeight(value);
  }
  return '${formatWorkoutNumber(value)} $unit';
}
