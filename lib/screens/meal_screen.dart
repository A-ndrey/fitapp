import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_item.dart';
import '../state/app_store.dart';
import '../ui/core/input/numeric_input_formatters.dart';
import '../ui/core/layout/app_breakpoints.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/app_screen_scaffold.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/nutrition/catalog_item_search_sheet.dart';
import '../ui/nutrition/nutrition_cards.dart';
import '../ui/nutrition/nutrition_formatters.dart';
import '../widgets/food_form.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final showInlineAdd = AppBreakpoints.isMediumOrLarger(
              constraints.maxWidth,
            );
            final l10n = AppLocalizations.of(context);
            final addMealLabel = l10n?.mealAddItemAction ?? 'Log food';
            final historyGroups = store.mealHistoryGroups;

            return AppScreenScaffold(
              title: l10n?.mealTitle ?? 'Meal',
              floatingActionButton: showInlineAdd
                  ? null
                  : FloatingActionButton(
                      heroTag: 'add-meal-fab',
                      tooltip: addMealLabel,
                      onPressed: () => _openAddMealFlow(context),
                      child: const Icon(Icons.add),
                    ),
              body: AdaptivePage(
                children: [
                  if (showInlineAdd) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: addMealLabel,
                        child: FilledButton.icon(
                          onPressed: () => _openAddMealFlow(context),
                          icon: const Icon(Icons.add),
                          label: Text(addMealLabel),
                        ),
                      ),
                    ),
                    const AppPageHeaderContentGap(),
                  ],
                  NutritionSummaryGrid(
                    values: store.dailyTotals,
                    targets: store.dailyMacroTargets,
                  ),
                  const AppPageSectionGap(),
                  Text(
                    l10n?.mealEntriesTitle ?? 'Logged meals',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const AppPageHeaderContentGap(),
                  if (store.mealEntries.isEmpty)
                    AppEmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: l10n?.mealEmptyTitle ?? 'No food logged yet',
                      message:
                          l10n?.mealEmptyMessage ??
                          "Use Log food to start today's nutrition log.",
                    )
                  else
                    ...historyGroups.expand(
                      (group) => <Widget>[
                        _MealDayDivider(date: group.date),
                        ...group.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppPageSpacing.itemGap,
                            ),
                            child: MealEntryCard(
                              store: store,
                              entry: entry,
                              onRemove: () => store.removeMealEntry(entry.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAddMealFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final recommendations = store.mealItemRecommendations();
    final result = await showCatalogItemSearchSheet(
      context: context,
      store: store,
      title: l10n?.mealSearchSheetTitle ?? 'Log food',
      subtitle:
          l10n?.mealSearchSheetSubtitle ??
          'Search saved foods and recipes, or create a new food from your query.',
      searchFieldLabel:
          l10n?.mealSearchFieldLabel ?? 'Search foods and recipes',
      recentItems: recommendations.recent,
      recentLabel: 'Recent foods',
      frequentItems: recommendations.frequent,
      frequentLabel: 'Frequent foods',
      allowCreate: true,
      createActionLabelBuilder: (query) =>
          l10n?.mealCreateItem(query) ?? 'Create "$query"',
    );
    if (!context.mounted || result == null) {
      return;
    }
    if (result.item != null) {
      await _showLogAmountDialog(context, result.item!);
      return;
    }

    final name = result.createName.trim();
    if (name.isEmpty) {
      return;
    }
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (dialogContext) {
          return FoodForm(store: store, initialName: name, fullScreen: true);
        },
      ),
    );
    if (!context.mounted || createdId == null) {
      return;
    }
    final created = store.itemById(createdId);
    if (created != null) {
      await _showLogAmountDialog(context, created);
    }
  }

  Future<void> _showLogAmountDialog(
    BuildContext context,
    CatalogItem item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) {
        return _LogAmountSheet(
          item: item,
          onAdd: (mode, value) {
            if (mode == _LogAmountMode.grams) {
              store.addMealByGrams(itemId: item.id, grams: value);
            } else {
              store.addMealByServings(itemId: item.id, servings: value);
            }
          },
        );
      },
    );
  }
}

class _MealDayDivider extends StatelessWidget {
  const _MealDayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMMd(locale).format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

enum _LogAmountMode { grams, servings }

class _LogAmountSheet extends StatefulWidget {
  const _LogAmountSheet({required this.item, required this.onAdd});

  final CatalogItem item;
  final void Function(_LogAmountMode mode, double value) onAdd;

  @override
  State<_LogAmountSheet> createState() => _LogAmountSheetState();
}

class _LogAmountSheetState extends State<_LogAmountSheet> {
  late final TextEditingController _gramsController = TextEditingController(
    text: formatNutritionNumber(widget.item.servingSizeGrams),
  );
  final TextEditingController _servingsController = TextEditingController(
    text: '1',
  );
  _LogAmountMode _mode = _LogAmountMode.grams;

  @override
  void dispose() {
    _gramsController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gramsLabel = l10n?.mealGramsLabel ?? 'Grams';
    final servingsLabel = l10n?.mealServingsLabel ?? 'Servings';
    final label = _mode == _LogAmountMode.grams ? gramsLabel : servingsLabel;
    final controller = _mode == _LogAmountMode.grams
        ? _gramsController
        : _servingsController;
    final description = widget.item.description.trim();
    final servingSize =
        '${formatNutritionNumber(widget.item.servingSizeGrams)} g per serving';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          if (description.isNotEmpty) ...[
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
          ],
          Text(servingSize, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(
            l10n?.mealAmountPrompt ??
                "Choose how much you ate, then add it to today's meal log.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<_LogAmountMode>(
            segments: [
              ButtonSegment(
                value: _LogAmountMode.grams,
                label: Text(gramsLabel),
                icon: const Icon(Icons.scale),
              ),
              ButtonSegment(
                value: _LogAmountMode.servings,
                label: Text(servingsLabel),
                icon: const Icon(Icons.ramen_dining),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: positiveDecimalInputFormatters,
            decoration: InputDecoration(labelText: label),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n?.commonCancel ?? 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final amount = parsePositiveDecimalInput(controller.text);
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return;
                    }
                    widget.onAdd(_mode, amount);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n?.mealAddToMealAction ?? 'Log food'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
