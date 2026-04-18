import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/dish_item.dart';
import '../state/app_store.dart';

class DishForm extends StatefulWidget {
  const DishForm({super.key, required this.store});

  final AppStore store;

  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final List<DishComponent> _components = <DishComponent>[];
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dish'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Dish name'),
            ),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Dish description'),
            ),
            TextField(
              controller: _servingSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Dish serving size grams',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openComponentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add component'),
            ),
            const SizedBox(height: 8),
            ..._components.map((component) {
              final item = widget.store.itemById(component.itemId);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item?.name ?? component.itemId),
                subtitle: Text('${_format(component.grams)} g'),
              );
            }),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveDish, child: const Text('Save dish')),
      ],
    );
  }

  Future<void> _openComponentDialog() async {
    final component = await showDialog<DishComponent>(
      context: context,
      builder: (context) {
        return _DishComponentDialog(items: widget.store.items);
      },
    );
    if (!mounted || component == null) {
      return;
    }
    setState(() {
      _components.add(component);
      _errorText = null;
    });
  }

  void _saveDish() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final servingSize = double.tryParse(_servingSizeController.text.trim());
    if (name.isEmpty ||
        servingSize == null ||
        !servingSize.isFinite ||
        servingSize <= 0 ||
        _components.isEmpty) {
      setState(() {
        _errorText = 'Enter dish details and at least one component.';
      });
      return;
    }

    try {
      widget.store.createDish(
        DishItem(
          id: widget.store.createIdFromName(name),
          name: name,
          description: description,
          servingSizeGrams: servingSize,
          components: List<DishComponent>.of(_components),
        ),
      );
    } on ArgumentError catch (error) {
      setState(() {
        _errorText = error.message?.toString() ?? 'Could not save dish.';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _DishComponentDialog extends StatefulWidget {
  const _DishComponentDialog({required this.items});

  final List<CatalogItem> items;

  @override
  State<_DishComponentDialog> createState() => _DishComponentDialogState();
}

class _DishComponentDialogState extends State<_DishComponentDialog> {
  final TextEditingController _gramsController = TextEditingController();
  CatalogItem? _selectedItem;
  String? _errorText;

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add component'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final selected = _selectedItem?.id == item.id;
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text(item.isFood ? 'food' : 'dish'),
                    trailing: selected ? const Icon(Icons.check) : null,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedItem = item;
                        _errorText = null;
                      });
                    },
                  );
                },
              ),
            ),
            TextField(
              controller: _gramsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Component grams'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveComponent,
          child: const Text('Save component'),
        ),
      ],
    );
  }

  void _saveComponent() {
    final grams = double.tryParse(_gramsController.text.trim());
    if (_selectedItem == null ||
        grams == null ||
        !grams.isFinite ||
        grams <= 0) {
      setState(() {
        _errorText = 'Choose an item and enter valid grams.';
      });
      return;
    }
    Navigator.of(
      context,
    ).pop(DishComponent(itemId: _selectedItem!.id, grams: grams));
  }
}
