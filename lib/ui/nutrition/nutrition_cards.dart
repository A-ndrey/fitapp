import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../state/app_store.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/dashboard_panels.dart';
import 'nutrition_formatters.dart';

class NutritionSummaryGrid extends StatelessWidget {
  const NutritionSummaryGrid({required this.values, super.key});

  static const _calorieGoal = 3200.0;
  static const _proteinGoal = 220.0;
  static const _fatGoal = 80.0;
  static const _carbGoal = 360.0;

  final NutritionValues values;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DashboardPanel(
      title: 'Macro targets',
      eyebrow: 'Today',
      subtitle:
          'Use the remaining values to steer the next meal, not just review the day after it is over.',
      emphasis: DashboardPanelEmphasis.raisedSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalProgressRow(
            label: l10n?.nutritionCalories ?? 'Calories',
            valueLabel:
                '${formatNutritionNumber(values.calories)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
            targetLabel:
                '${formatNutritionNumber(_calorieGoal)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
            progress: values.calories / _calorieGoal,
            statusLabel:
                '${formatNutritionNumber((_calorieGoal - values.calories).clamp(0, _calorieGoal))} left',
            leading: const Icon(
              Icons.local_fire_department_outlined,
              color: AppTheme.calorieAccent,
            ),
            barColor: AppTheme.calorieAccent,
          ),
          const SizedBox(height: 14),
          GoalProgressRow(
            label: l10n?.nutritionProtein ?? 'Protein',
            valueLabel:
                '${formatNutritionNumber(values.protein)} ${l10n?.nutritionGramUnit ?? 'g'}',
            targetLabel:
                '${formatNutritionNumber(_proteinGoal)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.protein / _proteinGoal,
            statusLabel:
                '${formatNutritionNumber((_proteinGoal - values.protein).clamp(0, _proteinGoal))} left',
            leading: const Icon(
              Icons.egg_alt_outlined,
              color: AppTheme.proteinAccent,
            ),
            barColor: AppTheme.proteinAccent,
          ),
          const SizedBox(height: 14),
          GoalProgressRow(
            label: l10n?.nutritionCarbs ?? 'Carbs',
            valueLabel:
                '${formatNutritionNumber(values.carbs)} ${l10n?.nutritionGramUnit ?? 'g'}',
            targetLabel:
                '${formatNutritionNumber(_carbGoal)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.carbs / _carbGoal,
            statusLabel:
                '${formatNutritionNumber((_carbGoal - values.carbs).clamp(0, _carbGoal))} left',
            leading: const Icon(
              Icons.grain_outlined,
              color: AppTheme.carbAccent,
            ),
            barColor: AppTheme.carbAccent,
          ),
          const SizedBox(height: 14),
          GoalProgressRow(
            label: l10n?.nutritionFat ?? 'Fat',
            valueLabel:
                '${formatNutritionNumber(values.fat)} ${l10n?.nutritionGramUnit ?? 'g'}',
            targetLabel:
                '${formatNutritionNumber(_fatGoal)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.fat / _fatGoal,
            statusLabel:
                '${formatNutritionNumber((_fatGoal - values.fat).clamp(0, _fatGoal))} left',
            leading: const Icon(
              Icons.water_drop_outlined,
              color: AppTheme.fatAccent,
            ),
            barColor: AppTheme.fatAccent,
          ),
        ],
      ),
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
        : l10n?.catalogSubtypeDish ?? 'recipe';

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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                formatNutritionLine(
                  entry.nutrition,
                  kilocalorieLabel: l10n?.nutritionKilocalorieUnit ?? 'kcal',
                  gramLabel: l10n?.nutritionGramUnit ?? 'g',
                  proteinLabel: l10n?.nutritionProteinInlineLabel ?? 'protein',
                  fatLabel: l10n?.nutritionFatInlineLabel ?? 'fat',
                  carbsLabel: l10n?.nutritionCarbsInlineLabel ?? 'carbs',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtypeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.secondaryAccent,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<_MealEntryAction>(
          tooltip: l10n?.mealRemoveEntryTooltip ?? 'Remove meal entry',
          onSelected: (action) {
            if (action == _MealEntryAction.remove) {
              onRemove();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _MealEntryAction.remove,
              child: Text(l10n?.commonDelete ?? 'Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MealEntryAction { remove }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(item.name),
      subtitle: Text(
        item.isFood
            ? l10n?.catalogSubtypeFood ?? 'food'
            : l10n?.catalogSubtypeDish ?? 'recipe',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
