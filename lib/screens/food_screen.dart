import 'package:flutter/material.dart';

import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/library/library_cards.dart';
import '../widgets/dish_form.dart';
import '../widgets/food_form.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key, required this.store, this.embedded = false});

  final AppStore store;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final body = _buildBody(context);
        if (embedded) {
          return body;
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Food')),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add-food-fab',
            tooltip: 'Add food or dish',
            onPressed: () => _openAddItemFlow(context),
            child: const Icon(Icons.add),
          ),
          body: body,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return AdaptivePage(
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        if (store.items.isEmpty)
          const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No foods or dishes yet',
            message: 'Use Add food or dish to build your reusable catalog.',
          )
        else
          ...store.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FoodCatalogCard(
                item: item,
                store: store,
                onEdit: () => _openEditItemFlow(context, item.id),
                onDelete: () => _confirmDeleteItem(context, item.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = Text(
      'Food set',
      style: Theme.of(context).textTheme.titleMedium,
    );
    if (!embedded) {
      return title;
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        title,
        IntrinsicWidth(
          child: FilledButton.icon(
            onPressed: () => _openAddItemFlow(context),
            icon: const Icon(Icons.add),
            label: const Text('Add food or dish'),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditItemFlow(BuildContext context, String itemId) async {
    final item = store.itemById(itemId);
    if (item == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        if (item.isFood) {
          return FoodForm(store: store, initialFood: item.food);
        }
        return DishForm(store: store, initialDish: item.dish);
      },
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, String itemId) async {
    final item = store.itemById(itemId);
    if (item == null) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${item.name}?'),
          content: const Text('This removes the item from the food set.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!context.mounted || shouldDelete != true) {
      return;
    }
    try {
      store.deleteItem(itemId);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openAddItemFlow(BuildContext context) async {
    final choice = await showModalBottomSheet<_AddFoodChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.eco_outlined),
                title: const Text('Food item'),
                onTap: () {
                  Navigator.of(context).pop(_AddFoodChoice.food);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ramen_dining_outlined),
                title: const Text('Dish'),
                onTap: () {
                  Navigator.of(context).pop(_AddFoodChoice.dish);
                },
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || choice == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return choice == _AddFoodChoice.food
            ? FoodForm(store: store)
            : DishForm(store: store);
      },
    );
  }
}

enum _AddFoodChoice { food, dish }
