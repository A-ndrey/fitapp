import 'package:flutter/material.dart';

import '../state/app_store.dart';
import '../widgets/dish_form.dart';
import '../widgets/food_form.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Food')),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add food or dish',
            onPressed: () => _openAddItemFlow(context),
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Food set',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...store.items.map((item) {
                  final nutrition = item.nutritionPerServing(store.catalog);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.isFood ? 'food' : 'dish'),
                            Text(
                              '${_format(item.servingSizeGrams)} g serving • '
                              '${_format(nutrition.calories)} kcal per serving',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit ${item.name}',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _openEditItemFlow(context, item.id),
                            ),
                            IconButton(
                              tooltip: 'Delete ${item.name}',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  _confirmDeleteItem(context, item.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
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

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

enum _AddFoodChoice { food, dish }
