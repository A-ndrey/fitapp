import 'package:flutter/material.dart';

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
    return Card(
      child: ListTile(
        title: _BoundedText(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BoundedText(formatCatalogItemTypeLabel(item)),
            _BoundedText(formatCatalogServingNutritionLabel(item, store)),
          ],
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip: 'Edit ${item.name}',
          deleteTooltip: 'Delete ${item.name}',
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
    return Card(
      child: ListTile(
        title: _BoundedText(plan.name),
        subtitle: _BoundedText(
          formatTrainingPlanSummaryLabel(plan),
          maxLines: 2,
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip: 'Edit ${plan.name}',
          deleteTooltip: 'Delete ${plan.name}',
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
              formatExerciseMuscleGroupSummaryLabel(exercise.muscleGroups),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: _CatalogCardActions(
          editTooltip: 'Edit ${exercise.name}',
          deleteTooltip: 'Delete ${exercise.name}',
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
