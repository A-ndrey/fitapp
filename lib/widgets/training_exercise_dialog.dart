import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_preferences.dart';
import '../models/exercise.dart';
import '../models/training_plan.dart';
import '../state/app_store.dart';
import '../ui/core/widgets/form_shell.dart';

/// Edits optional targets using the selected exercise’s measurement fields.
class TrainingExerciseDialog extends StatefulWidget {
  const TrainingExerciseDialog({
    super.key,
    required this.store,
    required this.exercise,
    required this.initialExercise,
    this.fullScreen = false,
    this.title,
    this.primaryActionLabel,
  });

  final AppStore store;
  final Exercise exercise;
  final TrainingExercise? initialExercise;
  final bool fullScreen;
  final String? title;
  final String? primaryActionLabel;

  @override
  State<TrainingExerciseDialog> createState() => _TrainingExerciseDialogState();
}

class _TrainingExerciseDialogState extends State<TrainingExerciseDialog> {
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late final TextEditingController _assistanceController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExercise;
    _setsController = TextEditingController(text: _formatInput(initial?.sets));
    _repsController = TextEditingController(text: _formatInput(initial?.reps));
    _weightController = TextEditingController(
      text: _formatInput(_displayWeight(initial?.weightGrams)),
    );
    _durationController = TextEditingController(
      text: _formatInput(initial?.durationSeconds),
    );
    _distanceController = TextEditingController(
      text: _formatInput(_displayDistance(initial?.distanceMeters)),
    );
    _assistanceController = TextEditingController(
      text: _formatInput(_displayWeight(initial?.assistanceWeightGrams)),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _assistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title =
        widget.title ??
        (widget.initialExercise == null
            ? l10n?.trainingTargetDialogTitle ?? 'Add exercise'
            : l10n?.trainingTargetDialogEditTitle ?? 'Edit exercise');
    final children = [
      FormSectionCard(
        title: l10n?.trainingTargetSectionTitle ?? 'Set targets',
        subtitle: _targetSectionSubtitle(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFields(context),
        ),
      ),
      if (_errorText != null) InlineErrorBanner(message: _errorText!),
    ];
    if (widget.fullScreen) {
      return FormShellPage(
        title: title,
        subtitle: widget.exercise.name,
        primaryActionLabel:
            widget.primaryActionLabel ??
            l10n?.exerciseSaveAction ??
            'Save exercise',
        onPrimaryAction: _saveExercise,
        children: children,
      );
    }
    return FormShellDialog(
      title: title,
      subtitle: widget.exercise.name,
      primaryActionLabel:
          widget.primaryActionLabel ??
          l10n?.exerciseSaveAction ??
          'Save exercise',
      onPrimaryAction: _saveExercise,
      children: children,
    );
  }

  void _saveExercise() {
    final sets = _parsePositiveIntegerOptional(_setsController.text);
    final reps = _parsePositiveIntegerOptional(_repsController.text);
    final weightInput = _parsePositiveOptional(_weightController.text);
    final duration = _parsePositiveOptional(_durationController.text);
    final distanceInput = _parsePositiveOptional(_distanceController.text);
    final assistanceInput = _parsePositiveOptional(_assistanceController.text);
    if ((sets == null && _setsController.text.trim().isNotEmpty) ||
        (reps == null && _repsController.text.trim().isNotEmpty) ||
        (weightInput == null && _weightController.text.trim().isNotEmpty) ||
        (duration == null && _durationController.text.trim().isNotEmpty) ||
        (distanceInput == null && _distanceController.text.trim().isNotEmpty) ||
        (assistanceInput == null &&
            _assistanceController.text.trim().isNotEmpty)) {
      setState(() {
        _errorText = _validationMessage;
      });
      return;
    }

    final exercise = switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        weightGrams: weightInput == null ? null : _normalizeWeight(weightInput),
      ),
      ExerciseMeasurementType.bodyweight => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
      ),
      ExerciseMeasurementType.duration => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        durationSeconds: duration,
      ),
      ExerciseMeasurementType.weightedDuration => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        weightGrams: weightInput == null ? null : _normalizeWeight(weightInput),
        durationSeconds: duration,
      ),
      ExerciseMeasurementType.cardio => TrainingExercise(
        exerciseId: widget.exercise.id,
        durationSeconds: duration,
        distanceMeters: distanceInput == null
            ? null
            : _normalizeDistance(distanceInput),
      ),
      ExerciseMeasurementType.assisted => TrainingExercise(
        exerciseId: widget.exercise.id,
        sets: sets,
        reps: reps,
        assistanceWeightGrams: assistanceInput == null
            ? null
            : _normalizeWeight(assistanceInput),
      ),
    };

    Navigator.of(context).pop(exercise);
  }

  List<Widget> _buildFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fields = <Widget>[];
    switch (widget.exercise.measurementType) {
      case ExerciseMeasurementType.strength:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _weightController,
            label: l10n?.trainingExpectedWeightFieldLabel ?? 'Weight',
          ),
        ]);
        break;
      case ExerciseMeasurementType.bodyweight:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
        ]);
        break;
      case ExerciseMeasurementType.duration:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
        ]);
        break;
      case ExerciseMeasurementType.weightedDuration:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _weightController,
            label: l10n?.trainingExpectedWeightFieldLabel ?? 'Weight',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
        ]);
        break;
      case ExerciseMeasurementType.cardio:
        fields.addAll([
          _numberField(
            controller: _durationController,
            label: l10n?.trainingExpectedTimeFieldLabel ?? 'Duration',
          ),
          const SizedBox(height: 12),
          _numberField(controller: _distanceController, label: 'Distance'),
        ]);
        break;
      case ExerciseMeasurementType.assisted:
        fields.addAll([
          _numberField(
            controller: _setsController,
            label: l10n?.trainingExpectedSetsFieldLabel ?? 'Sets',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _repsController,
            label: l10n?.trainingExpectedRepsFieldLabel ?? 'Reps',
          ),
          const SizedBox(height: 12),
          _numberField(
            controller: _assistanceController,
            label: 'Assistance weight',
          ),
        ]);
        break;
    }
    return fields;
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label),
    );
  }

  String _targetSectionSubtitle() {
    return switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength => 'Set working sets, reps, and load.',
      ExerciseMeasurementType.bodyweight => 'Set working sets and reps.',
      ExerciseMeasurementType.duration => 'Set working sets and duration.',
      ExerciseMeasurementType.weightedDuration =>
        'Set working sets, load, and duration.',
      ExerciseMeasurementType.cardio =>
        'Set duration, distance, or both for the cardio target.',
      ExerciseMeasurementType.assisted =>
        'Set working sets, reps, and assistance weight.',
    };
  }

  String get _validationMessage {
    return switch (widget.exercise.measurementType) {
      ExerciseMeasurementType.strength =>
        'Use positive values for any filled sets, reps, or weight fields.',
      ExerciseMeasurementType.bodyweight =>
        'Use positive values for any filled sets or reps fields.',
      ExerciseMeasurementType.duration =>
        'Use positive values for any filled sets or duration fields.',
      ExerciseMeasurementType.weightedDuration =>
        'Use positive values for any filled sets, weight, or duration fields.',
      ExerciseMeasurementType.cardio =>
        'Use positive values for any filled duration or distance fields.',
      ExerciseMeasurementType.assisted =>
        'Use positive values for any filled sets, reps, or assistance fields.',
    };
  }

  double? _parsePositiveOptional(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double? _parsePositiveIntegerOptional(String value) {
    final parsed = _parsePositiveOptional(value);
    if (parsed == null || parsed != parsed.roundToDouble()) {
      return null;
    }
    return parsed;
  }

  double? _displayWeight(double? grams) {
    if (grams == null) {
      return null;
    }
    final kilograms = grams / 1000;
    return widget.store.workoutWeightUnit == WorkoutWeightUnit.pounds
        ? kilograms * 2.2046226218
        : kilograms;
  }

  double? _displayDistance(double? meters) {
    if (meters == null) {
      return null;
    }
    final kilometers = meters / 1000;
    return widget.store.distanceUnit == DistanceUnit.miles
        ? kilometers / 1.609344
        : kilometers;
  }

  double _normalizeWeight(double value) {
    final kilograms = widget.store.workoutWeightUnit == WorkoutWeightUnit.pounds
        ? value / 2.2046226218
        : value;
    return kilograms * 1000;
  }

  double _normalizeDistance(double value) {
    final kilometers = widget.store.distanceUnit == DistanceUnit.miles
        ? value * 1.609344
        : value;
    return kilometers * 1000;
  }

  String _formatInput(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
