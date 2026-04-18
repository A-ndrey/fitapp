import 'package:flutter/material.dart';

import '../models/nutrition.dart';

class MacroSummary extends StatelessWidget {
  const MacroSummary({super.key, required this.title, required this.values});

  final String title;
  final NutritionValues values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MacroChip(
              label: 'Calories',
              value: _format(values.calories),
              suffix: 'kcal',
            ),
            _MacroChip(
              label: 'Protein',
              value: _format(values.protein),
              suffix: 'g',
            ),
            _MacroChip(label: 'Fat', value: _format(values.fat), suffix: 'g'),
            _MacroChip(
              label: 'Carbs',
              value: _format(values.carbs),
              suffix: 'g',
            ),
          ],
        ),
      ],
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.suffix,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value $suffix'));
  }
}
