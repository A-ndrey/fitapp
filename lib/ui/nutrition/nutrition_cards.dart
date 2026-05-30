import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/meal_entry.dart';
import '../../models/nutrition.dart';
import '../../state/app_store.dart';
import '../core/layout/app_breakpoints.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/swipe_action_card.dart';
import '../core/widgets/dashboard_panels.dart';
import 'nutrition_formatters.dart';

class NutritionSummaryGrid extends StatelessWidget {
  const NutritionSummaryGrid({
    required this.values,
    required this.targets,
    super.key,
  });

  final NutritionValues values;
  final NutritionValues targets;

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
                '${formatNutritionNumber(targets.calories)} ${l10n?.nutritionKilocalorieUnit ?? 'kcal'}',
            progress: values.calories / targets.calories,
            statusLabel:
                '${formatNutritionNumber((targets.calories - values.calories).clamp(0, targets.calories))} left',
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
                '${formatNutritionNumber(targets.protein)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.protein / targets.protein,
            statusLabel:
                '${formatNutritionNumber((targets.protein - values.protein).clamp(0, targets.protein))} left',
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
                '${formatNutritionNumber(targets.carbs)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.carbs / targets.carbs,
            statusLabel:
                '${formatNutritionNumber((targets.carbs - values.carbs).clamp(0, targets.carbs))} left',
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
                '${formatNutritionNumber(targets.fat)} ${l10n?.nutritionGramUnit ?? 'g'}',
            progress: values.fat / targets.fat,
            statusLabel:
                '${formatNutritionNumber((targets.fat - values.fat).clamp(0, targets.fat))} left',
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
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    return SwipeActionCard(
      actions: [
        SwipeCardAction(
          label: l10n?.commonDelete ?? 'Delete',
          icon: Icons.delete_outline,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: onRemove,
        ),
      ],
      child: Card(
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
                    proteinLabel:
                        l10n?.nutritionProteinInlineLabel ?? 'protein',
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing: isCompact
              ? null
              : PopupMenuButton<_MealEntryAction>(
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
