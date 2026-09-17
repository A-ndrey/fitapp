import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/nutrition.dart';
import '../core/theme/app_theme.dart';

/// A history date with compact consumed totals, in calories/protein/fat/carbs order.
class MealDayHeader extends StatelessWidget {
  const MealDayHeader({super.key, required this.date, required this.totals});

  final DateTime date;
  final NutritionValues totals;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context);
    final grams = l10n?.nutritionGramUnit ?? 'g';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            DateFormat.yMMMMd(locale).format(date),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          // Keep the summary together when it moves below the date. Its own
          // wrap also accommodates large accessibility text and large totals.
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _NutrientTotal(
                value: totals.calories,
                label: l10n?.nutritionCalories ?? 'Calories',
                unit: l10n?.nutritionKilocalorieUnit ?? 'kcal',
                icon: Icons.local_fire_department_outlined,
                color: AppTheme.calorieAccent,
              ),
              _NutrientTotal(
                value: totals.protein,
                label: l10n?.nutritionProtein ?? 'Protein',
                unit: grams,
                icon: Icons.egg_alt_outlined,
                color: AppTheme.proteinAccent,
              ),
              _NutrientTotal(
                value: totals.fat,
                label: l10n?.nutritionFat ?? 'Fat',
                unit: grams,
                icon: Icons.water_drop_outlined,
                color: AppTheme.fatAccent,
              ),
              _NutrientTotal(
                value: totals.carbs,
                label: l10n?.nutritionCarbs ?? 'Carbs',
                unit: grams,
                icon: Icons.grain_outlined,
                color: AppTheme.carbAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientTotal extends StatelessWidget {
  const _NutrientTotal({
    required this.value,
    required this.label,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final double value;
  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final number = value.round().toString();
    final description = '$label: $number $unit';

    return Semantics(
      label: description,
      excludeSemantics: true,
      child: Tooltip(
        message: description,
        excludeFromSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(number, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
