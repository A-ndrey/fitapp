import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/meal_entry.dart';
import '../state/app_store.dart';
import '../widgets/food_form.dart';
import '../widgets/macro_summary.dart';

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
            tooltip: 'Add meal item',
            onPressed: () => _openAddMealFlow(context),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MacroSummary(title: 'Daily totals', values: store.dailyTotals),
                const SizedBox(height: 24),
                Text(
                  'Meal entries',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (store.mealEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No meal entries yet'),
                  )
                else
                  ...store.mealEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MealEntryCard(
                        entry: entry,
                        onRemove: () => store.removeMealEntry(entry.id),
                      ),
                    ),
                  ),
              ],
            ),
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

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({required this.entry, required this.onRemove});

  final MealEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(entry.itemName),
        subtitle: Text(
          '${_formatQuantity(entry)} logged\n'
          '${_format(entry.nutrition.calories)} kcal • '
          '${_format(entry.nutrition.protein)} g protein • '
          '${_format(entry.nutrition.fat)} g fat • '
          '${_format(entry.nutrition.carbs)} g carbs',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Remove meal entry',
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }

  String _formatQuantity(MealEntry entry) {
    final value = entry.enteredQuantity;
    final unit = entry.mode == MealEntryMode.grams ? 'g' : 'servings';
    return '${_format(value)} $unit';
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
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
        children: [
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
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.isFood ? 'food' : 'dish'),
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
