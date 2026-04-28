import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../state/app_store.dart';
import '../core/widgets/metric_card.dart';
import 'nutrition_formatters.dart';

class NutritionSummaryGrid extends StatelessWidget {
  const NutritionSummaryGrid({required this.values, super.key});

  final NutritionValues values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420 ? 2 : 4;
        final spacing = columns == 2 ? 8.0 : 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: MetricCard(
                label: l10n?.nutritionCalories ?? 'Calories',
                value: formatNutritionNumber(values.calories),
                suffix: 'kcal',
                semanticSuffix:
                    l10n?.nutritionKilocaloriesSemantic ?? 'kilocalories',
                icon: Icons.local_fire_department_outlined,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: l10n?.nutritionProtein ?? 'Protein',
                value: formatNutritionNumber(values.protein),
                suffix: 'g',
                semanticSuffix: l10n?.nutritionGramsSemantic ?? 'grams',
                icon: Icons.fitness_center_outlined,
                color: colorScheme.secondary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: l10n?.nutritionFat ?? 'Fat',
                value: formatNutritionNumber(values.fat),
                suffix: 'g',
                semanticSuffix: l10n?.nutritionGramsSemantic ?? 'grams',
                icon: Icons.water_drop_outlined,
                color: colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: l10n?.nutritionCarbs ?? 'Carbs',
                value: formatNutritionNumber(values.carbs),
                suffix: 'g',
                semanticSuffix: l10n?.nutritionGramsSemantic ?? 'grams',
                icon: Icons.grain_outlined,
                color: colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class MealEntryCard extends StatelessWidget {
  const MealEntryCard({
    required this.store,
    required this.entry,
    required this.onRemove,
    super.key,
  });

  final AppStore store;
  final MealEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtypeLabel = entry.itemType == CatalogItemType.food
        ? l10n?.catalogSubtypeFood ?? 'food'
        : l10n?.catalogSubtypeDish ?? 'dish';
    return Card(
      child: ListTile(
        title: Text(entry.itemName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${formatMealQuantity(entry, store, servingsLabel: l10n?.mealServingsQuantitySuffix ?? 'servings')} ${l10n?.mealLoggedSuffix ?? 'logged'}',
              ),
              Text(
                formatNutritionLine(
                  entry.nutrition,
                  kilocalorieLabel: l10n?.nutritionKilocalorieUnit ?? 'kcal',
                  gramLabel: l10n?.nutritionGramUnit ?? 'g',
                  proteinLabel: l10n?.nutritionProteinInlineLabel ?? 'protein',
                  fatLabel: l10n?.nutritionFatInlineLabel ?? 'fat',
                  carbsLabel: l10n?.nutritionCarbsInlineLabel ?? 'carbs',
                ),
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(subtypeLabel),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: l10n?.mealRemoveEntryTooltip ?? 'Remove meal entry',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class MealSearchResultTile extends StatelessWidget {
  const MealSearchResultTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        item.isFood
            ? l10n?.catalogSubtypeFood ?? 'food'
            : l10n?.catalogSubtypeDish ?? 'dish',
      ),
      onTap: onTap,
    );
  }
}
