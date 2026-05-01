import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../state/app_store.dart';
import 'library_formatters.dart';

class FoodCatalogCard extends StatelessWidget {
  const FoodCatalogCard({
    super.key,
    required this.item,
    required this.store,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogItem item;
  final AppStore store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: _BoundedText(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BoundedText(
              formatCatalogItemTypeLabel(
                item,
                foodLabel: l10n?.catalogSubtypeFood ?? 'food',
                dishLabel: l10n?.catalogSubtypeDish ?? 'dish',
              ),
            ),
            _BoundedText(
              formatCatalogServingNutritionLabel(
                item,
                store,
                servingLabel: l10n?.libraryServingSuffix ?? 'serving',
                caloriesPerServing: (calories) =>
                    l10n?.libraryCaloriesPerServingLabel(calories) ??
                    '$calories kcal per serving',
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip: l10n?.libraryEditItem(item.name) ?? 'Edit ${item.name}',
          deleteTooltip:
              l10n?.libraryDeleteItem(item.name) ?? 'Delete ${item.name}',
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class TrainingPlanCatalogCard extends StatelessWidget {
  const TrainingPlanCatalogCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: _BoundedText(plan.name),
        subtitle: _BoundedText(
          formatTrainingPlanSummaryLabel(
            plan,
            exerciseCountLabel: (count) =>
                l10n?.libraryExerciseCount(count) ??
                formatLibraryCountLabel(count, 'exercise'),
          ),
          maxLines: 2,
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip: l10n?.libraryEditItem(plan.name) ?? 'Edit ${plan.name}',
          deleteTooltip:
              l10n?.libraryDeleteItem(plan.name) ?? 'Delete ${plan.name}',
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class ExerciseCatalogCard extends StatelessWidget {
  const ExerciseCatalogCard({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: _BoundedText(exercise.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BoundedText(exercise.description),
            _BoundedText(exercise.instruction),
            _BoundedText(
              formatExerciseMuscleGroupSummaryLabel(
                exercise.muscleGroups,
                emptyLabel: l10n?.libraryMusclesEmpty ?? 'Muscles: -',
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip:
              l10n?.libraryEditItem(exercise.name) ?? 'Edit ${exercise.name}',
          deleteTooltip:
              l10n?.libraryDeleteItem(exercise.name) ??
              'Delete ${exercise.name}',
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _CatalogCardActions extends StatelessWidget {
  const _CatalogCardActions({
    required this.editTooltip,
    required this.deleteTooltip,
    required this.onEdit,
    required this.onDelete,
  });

  final String editTooltip;
  final String deleteTooltip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: editTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: deleteTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _BoundedText extends StatelessWidget {
  const _BoundedText(this.data, {this.maxLines = 1});

  final String data;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(data, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}
