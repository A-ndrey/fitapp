import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/nutrition/nutrition_cards.dart';
import '../widgets/food_form.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Meal')),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add-meal-fab',
            tooltip: 'Add meal item',
            onPressed: () => _openAddMealFlow(context),
            child: const Icon(Icons.add),
          ),
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: 'Nutrition cockpit',
                subtitle: 'Log food, review macros, and keep today visible.',
                trailing: Tooltip(
                  message: 'Add meal item',
                  child: FilledButton.icon(
                    onPressed: () => _openAddMealFlow(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add meal item'),
                  ),
                ),
              ),
              Text(
                'Daily totals',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              NutritionSummaryGrid(values: store.dailyTotals),
              const SizedBox(height: 24),
              Text(
                'Meal entries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (store.mealEntries.isEmpty)
                const AppEmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'No meal entries yet',
                  message: "Use Add meal item to start today's log.",
                )
              else
                ...store.mealEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MealEntryCard(
                      store: store,
                      entry: entry,
                      onRemove: () => store.removeMealEntry(entry.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddMealFlow(BuildContext context) async {
    final result = await showModalBottomSheet<_MealSearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _MealSearchSheet(store: store);
      },
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
    final createdId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return FoodForm(store: store, initialName: name);
      },
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _LogAmountDialog(
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

class _MealSearchResult {
  const _MealSearchResult.item(this.item) : createName = '';

  const _MealSearchResult.create(this.createName) : item = null;

  final CatalogItem? item;
  final String createName;
}

class _MealSearchSheet extends StatefulWidget {
  const _MealSearchSheet({required this.store});

  final AppStore store;

  @override
  State<_MealSearchSheet> createState() => _MealSearchSheetState();
}

class _MealSearchSheetState extends State<_MealSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final results = widget.store.searchItems(query);
    final hasExactMatch = _hasExactNameMatch(results, query);
    final showCreateAction = query.isNotEmpty && !hasExactMatch;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add meal item',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Search your saved foods and dishes, or create a new food from your query.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search foods and dishes',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: maxHeight,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length + (showCreateAction ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (showCreateAction && index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: Text('Create "$query"'),
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(_MealSearchResult.create(query));
                    },
                  );
                }
                final resultIndex = showCreateAction ? index - 1 : index;
                final item = results[resultIndex];
                return MealSearchResultTile(
                  item: item,
                  onTap: () {
                    Navigator.of(context).pop(_MealSearchResult.item(item));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasExactNameMatch(List<CatalogItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    for (final item in items) {
      if (item.name.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }
}

enum _LogAmountMode { grams, servings }

class _LogAmountDialog extends StatefulWidget {
  const _LogAmountDialog({required this.item, required this.onAdd});

  final CatalogItem item;
  final void Function(_LogAmountMode mode, double value) onAdd;

  @override
  State<_LogAmountDialog> createState() => _LogAmountDialogState();
}

class _LogAmountDialogState extends State<_LogAmountDialog> {
  final TextEditingController _amountController = TextEditingController();
  _LogAmountMode _mode = _LogAmountMode.grams;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _mode == _LogAmountMode.grams ? 'Grams' : 'Servings';
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Choose how much you ate, then add it to today's meal log.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<_LogAmountMode>(
            segments: const [
              ButtonSegment(
                value: _LogAmountMode.grams,
                label: Text('Grams'),
                icon: Icon(Icons.scale),
              ),
              ButtonSegment(
                value: _LogAmountMode.servings,
                label: Text('Servings'),
                icon: Icon(Icons.ramen_dining),
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
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: label),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount == null || !amount.isFinite || amount <= 0) {
              return;
            }
            widget.onAdd(_mode, amount);
            Navigator.of(context).pop();
          },
          child: const Text('Add to meal'),
        ),
      ],
    );
  }
}
