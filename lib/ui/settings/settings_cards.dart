import 'package:flutter/material.dart';

import '../../models/nutrition.dart';
import '../core/input/numeric_input_formatters.dart';

class SettingsStatusCard extends StatelessWidget {
  const SettingsStatusCard({
    required this.title,
    required this.message,
    this.icon = Icons.cloud_sync_outlined,
    this.messageColor,
    this.secondaryMessage,
    this.secondaryMessageColor,
    this.actionLabel,
    this.onPressed,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? messageColor;
  final String? secondaryMessage;
  final Color? secondaryMessageColor;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: messageColor ?? colorScheme.onSurfaceVariant,
              ),
            ),
            if (secondaryMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                secondaryMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryMessageColor ?? colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPressed,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PreferenceChipCard<T> extends StatelessWidget {
  const PreferenceChipCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<PreferenceChipOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option.label),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: value == option.value
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    backgroundColor: colorScheme.surfaceContainerLow,
                    selectedColor: colorScheme.primaryContainer,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    selected: value == option.value,
                    onSelected: (_) => onChanged(option.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceChipOption<T> {
  const PreferenceChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

class UnitsSettingsCard extends StatelessWidget {
  const UnitsSettingsCard({
    super.key,
    required this.workoutWeightUnit,
    required this.dishWeightUnit,
    required this.heightUnit,
    required this.distanceUnit,
    required this.workoutWeightOptions,
    required this.dishWeightOptions,
    required this.heightOptions,
    required this.distanceOptions,
    required this.onWorkoutWeightChanged,
    required this.onDishWeightChanged,
    required this.onHeightChanged,
    required this.onDistanceChanged,
    this.title,
  });

  final String? title;
  final dynamic workoutWeightUnit;
  final dynamic dishWeightUnit;
  final dynamic heightUnit;
  final dynamic distanceUnit;
  final List<PreferenceChipOption<dynamic>> workoutWeightOptions;
  final List<PreferenceChipOption<dynamic>> dishWeightOptions;
  final List<PreferenceChipOption<dynamic>> heightOptions;
  final List<PreferenceChipOption<dynamic>> distanceOptions;
  final ValueChanged<dynamic> onWorkoutWeightChanged;
  final ValueChanged<dynamic> onDishWeightChanged;
  final ValueChanged<dynamic> onHeightChanged;
  final ValueChanged<dynamic> onDistanceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _PreferenceChipRow<dynamic>(
              title: 'Workout weight',
              value: workoutWeightUnit,
              options: workoutWeightOptions,
              onChanged: onWorkoutWeightChanged,
            ),
            const SizedBox(height: 16),
            _PreferenceChipRow<dynamic>(
              title: 'Dish weight',
              value: dishWeightUnit,
              options: dishWeightOptions,
              onChanged: onDishWeightChanged,
            ),
            const SizedBox(height: 16),
            _PreferenceChipRow<dynamic>(
              title: 'Height',
              value: heightUnit,
              options: heightOptions,
              onChanged: onHeightChanged,
            ),
            const SizedBox(height: 16),
            _PreferenceChipRow<dynamic>(
              title: 'Distance',
              value: distanceUnit,
              options: distanceOptions,
              onChanged: onDistanceChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class MacroTargetsSettingsCard extends StatefulWidget {
  const MacroTargetsSettingsCard({
    required this.initialValue,
    required this.onApply,
    super.key,
    this.title = 'Daily macro targets',
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final NutritionValues initialValue;
  final ValueChanged<NutritionValues> onApply;

  @override
  State<MacroTargetsSettingsCard> createState() =>
      _MacroTargetsSettingsCardState();
}

class _MacroTargetsSettingsCardState extends State<MacroTargetsSettingsCard> {
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: _format(widget.initialValue.calories),
    );
    _proteinController = TextEditingController(
      text: _format(widget.initialValue.protein),
    );
    _fatController = TextEditingController(
      text: _format(widget.initialValue.fat),
    );
    _carbsController = TextEditingController(
      text: _format(widget.initialValue.carbs),
    );
  }

  @override
  void didUpdateWidget(covariant MacroTargetsSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _caloriesController.text = _format(widget.initialValue.calories);
      _proteinController.text = _format(widget.initialValue.protein);
      _fatController.text = _format(widget.initialValue.fat);
      _carbsController.text = _format(widget.initialValue.carbs);
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _NumberField(
                  controller: _caloriesController,
                  label: 'Daily calories target',
                  suffix: 'kcal',
                ),
                _NumberField(
                  controller: _proteinController,
                  label: 'Daily protein target',
                  suffix: 'g',
                ),
                _NumberField(
                  controller: _fatController,
                  label: 'Daily fat target',
                  suffix: 'g',
                ),
                _NumberField(
                  controller: _carbsController,
                  label: 'Daily carbs target',
                  suffix: 'g',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _applyTargets,
                child: const Text('Apply targets'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyTargets() {
    final calories = _parse(_caloriesController);
    final protein = _parse(_proteinController);
    final fat = _parse(_fatController);
    final carbs = _parse(_carbsController);
    if (calories == null || protein == null || fat == null || carbs == null) {
      return;
    }
    widget.onApply(
      NutritionValues(
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
      ),
    );
  }

  static double? _parse(TextEditingController controller) {
    return parsePositiveDecimalInput(controller.text);
  }

  static String _format(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: positiveDecimalInputFormatters,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _PreferenceChipRow<T> extends StatelessWidget {
  const _PreferenceChipRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<PreferenceChipOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.label),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: value == option.value
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                checkmarkColor: colorScheme.onPrimaryContainer,
                backgroundColor: colorScheme.surfaceContainerLow,
                selectedColor: colorScheme.primaryContainer,
                side: BorderSide(color: colorScheme.outlineVariant),
                selected: value == option.value,
                onSelected: (_) => onChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}
