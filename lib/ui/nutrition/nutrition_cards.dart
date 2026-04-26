import 'package:flutter/material.dart';

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
                label: 'Calories',
                value: formatNutritionNumber(values.calories),
                suffix: 'kcal',
                icon: Icons.local_fire_department_outlined,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Protein',
                value: formatNutritionNumber(values.protein),
                suffix: 'g',
                icon: Icons.fitness_center_outlined,
                color: colorScheme.secondary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Fat',
                value: formatNutritionNumber(values.fat),
                suffix: 'g',
                icon: Icons.water_drop_outlined,
                color: colorScheme.tertiary,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: 'Carbs',
                value: formatNutritionNumber(values.carbs),
                suffix: 'g',
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
    final subtypeLabel = entry.itemType == CatalogItemType.food
        ? 'food'
        : 'dish';
    return Card(
      child: ListTile(
        title: Text(entry.itemName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${formatMealQuantity(entry, store)} logged'),
              Text(formatNutritionLine(entry.nutrition)),
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
          tooltip: 'Remove meal entry',
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
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.isFood ? 'food' : 'dish'),
      onTap: onTap,
    );
  }
}
