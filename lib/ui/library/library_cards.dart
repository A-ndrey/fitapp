import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../models/exercise.dart';
import '../../models/training_plan.dart';
import '../../state/app_store.dart';
import '../core/layout/app_breakpoints.dart';
import '../core/widgets/swipe_action_card.dart';
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
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    return SwipeActionCard(
      actions: [
        SwipeCardAction(
          label: 'Edit',
          icon: Icons.edit_outlined,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: onEdit,
        ),
        SwipeCardAction(
          label: l10n?.commonDelete ?? 'Delete',
          icon: Icons.delete_outline,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: onDelete,
        ),
      ],
      child: Card(
        child: ListTile(
          title: _BoundedText(item.name),
          subtitle: _CatalogInfoList(
            children: [
              _CatalogInfoRow(
                icon: Icons.category_outlined,
                label: 'Type',
                value: formatCatalogItemTypeLabel(
                  item,
                  foodLabel: l10n?.catalogSubtypeFood ?? 'food',
                  dishLabel: l10n?.catalogSubtypeDish ?? 'recipe',
                ),
              ),
              _CatalogInfoRow(
                icon: Icons.scale_outlined,
                label: 'Serving',
                value: formatCatalogNutritionServingLabel(
                  item,
                  store,
                  servingLabel: l10n?.libraryServingSuffix ?? 'serving',
                ),
              ),
              _CatalogInfoRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Calories',
                value: formatCatalogCaloriesPerServingLabel(
                  item,
                  store,
                  caloriesPerServing: (calories) =>
                      l10n?.libraryCaloriesPerServingLabel(calories) ??
                      '$calories kcal per serving',
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: isCompact
              ? null
              : _CatalogCardActions(
                  editTooltip:
                      l10n?.libraryEditItem(item.name) ?? 'Edit ${item.name}',
                  deleteTooltip:
                      l10n?.libraryDeleteItem(item.name) ??
                      'Delete ${item.name}',
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
        ),
      ),
    );
  }
}

class TrainingPlanCatalogCard extends StatelessWidget {
  const TrainingPlanCatalogCard({
    super.key,
    required this.plan,
    required this.store,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingPlan plan;
  final AppStore store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    return SwipeActionCard(
      actions: [
        SwipeCardAction(
          label: 'Edit',
          icon: Icons.edit_outlined,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: onEdit,
        ),
        SwipeCardAction(
          label: l10n?.commonDelete ?? 'Delete',
          icon: Icons.delete_outline,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: onDelete,
        ),
      ],
      child: Card(
        child: ListTile(
          title: _BoundedText(plan.name),
          subtitle: _CatalogInfoList(
            children: [
              _CatalogInfoRow(
                icon: Icons.format_list_numbered_outlined,
                label: 'Exercises',
                value:
                    l10n?.libraryExerciseCount(plan.exercises.length) ??
                    formatLibraryCountLabel(plan.exercises.length, 'exercise'),
              ),
              if (formatTrainingPlanFirstTargetLabel(plan, store)
                  case final firstTarget?)
                _CatalogInfoRow(
                  icon: Icons.flag_outlined,
                  label: 'First target',
                  value: firstTarget,
                  maxLines: 2,
                ),
              if (plan.description.trim().isNotEmpty)
                _CatalogInfoText(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: plan.description.trim(),
                  maxLines: 2,
                ),
            ],
          ),
          isThreeLine: true,
          trailing: isCompact
              ? null
              : _CatalogCardActions(
                  editTooltip:
                      l10n?.libraryEditItem(plan.name) ?? 'Edit ${plan.name}',
                  deleteTooltip:
                      l10n?.libraryDeleteItem(plan.name) ??
                      'Delete ${plan.name}',
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
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
    final isCompact = AppBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    return SwipeActionCard(
      actions: [
        SwipeCardAction(
          label: 'Edit',
          icon: Icons.edit_outlined,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          onPressed: onEdit,
        ),
        SwipeCardAction(
          label: l10n?.commonDelete ?? 'Delete',
          icon: Icons.delete_outline,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: onDelete,
        ),
      ],
      child: Card(
        child: ListTile(
          title: _BoundedText(exercise.name),
          subtitle: _CatalogInfoList(
            children: [
              _CatalogInfoRow(
                icon: Icons.tune_outlined,
                label: 'Type',
                value: formatExerciseMeasurementTypeLabel(
                  exercise.measurementType,
                ),
              ),
              _CatalogInfoRow(
                icon: Icons.accessibility_new_outlined,
                label: 'Muscles',
                value: formatExerciseMuscleGroupSummaryLabel(
                  exercise.muscleGroups,
                  emptyLabel: l10n?.libraryMusclesEmpty ?? 'Muscles: -',
                ),
                maxLines: 2,
              ),
              if (exercise.description.trim().isNotEmpty)
                _CatalogInfoText(
                  icon: Icons.subject_outlined,
                  label: 'Description',
                  value: exercise.description.trim(),
                  maxLines: 2,
                ),
              if (exercise.instruction.trim().isNotEmpty)
                _CatalogInfoText(
                  icon: Icons.fact_check_outlined,
                  label: 'Instruction',
                  value: exercise.instruction.trim(),
                  maxLines: 2,
                ),
            ],
          ),
          isThreeLine: true,
          trailing: isCompact
              ? null
              : _CatalogCardActions(
                  editTooltip:
                      l10n?.libraryEditItem(exercise.name) ??
                      'Edit ${exercise.name}',
                  deleteTooltip:
                      l10n?.libraryDeleteItem(exercise.name) ??
                      'Delete ${exercise.name}',
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
        ),
      ),
    );
  }
}

class _CatalogInfoList extends StatelessWidget {
  const _CatalogInfoList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final child in children) ...[
            child,
            if (child != children.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _CatalogInfoRow extends StatelessWidget {
  const _CatalogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogInfoText extends StatelessWidget {
  const _CatalogInfoText({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
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
    return PopupMenuButton<_CatalogAction>(
      tooltip: 'More actions',
      onSelected: (action) {
        if (action == _CatalogAction.edit) {
          onEdit();
        } else {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_CatalogAction>(
          value: _CatalogAction.edit,
          child: Text(editTooltip),
        ),
        PopupMenuItem<_CatalogAction>(
          value: _CatalogAction.delete,
          child: Text(deleteTooltip),
        ),
      ],
    );
  }
}

enum _CatalogAction { edit, delete }

class _BoundedText extends StatelessWidget {
  const _BoundedText(this.data);

  final String data;

  @override
  Widget build(BuildContext context) {
    return Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
