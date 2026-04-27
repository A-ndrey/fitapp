import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../models/dish_item.dart';
import '../state/app_store.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/core/widgets/form_shell.dart';

class DishForm extends StatefulWidget {
  const DishForm({super.key, required this.store, this.initialDish});

  final AppStore store;
  final DishItem? initialDish;

  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _servingSizeController;
  final List<DishComponent> _components = <DishComponent>[];
  String? _errorText;
  bool get _isEditing => widget.initialDish != null;

  @override
  void initState() {
    super.initState();
    final dish = widget.initialDish;
    _nameController = TextEditingController(text: dish?.name ?? '');
    _descriptionController = TextEditingController(
      text: dish?.description ?? '',
    );
    _servingSizeController = TextEditingController(
      text: dish == null ? '' : _formatInput(dish.servingSizeGrams),
    );
    if (dish != null) {
      _components.addAll(dish.components);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormShellDialog(
      title: _isEditing ? 'Edit dish' : 'Dish',
      subtitle: 'Combine foods and dishes into a reusable recipe.',
      primaryActionLabel: 'Save dish',
      onPrimaryAction: _saveDish,
      maxWidth: 640,
      children: [
        if (_isEditing) _buildComponentsSection(),
        _buildBasicsSection(),
        if (!_isEditing) _buildComponentsSection(),
        if (_errorText != null) InlineErrorBanner(message: _errorText!),
      ],
    );
  }

  Widget _buildBasicsSection() {
    return FormSectionCard(
      title: 'Dish basics',
      subtitle: 'Name this recipe and define one serving.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Dish serving size grams',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsSection() {
    return FormSectionCard(
      title: 'Components',
      subtitle: 'Add ingredients to calculate serving nutrition.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openComponentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add component'),
            ),
          ),
          const SizedBox(height: 12),
          if (_components.isEmpty)
            const AppEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: 'No components yet',
              message: 'Add foods or dishes to calculate this recipe.',
            )
          else
            ..._components.indexed.map((entry) {
              final index = entry.$1;
              final component = entry.$2;
              final item = widget.store.itemById(component.itemId);
              final itemName = item?.name ?? component.itemId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(itemName),
                  subtitle: Text('${_format(component.grams)} g'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit $itemName component',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openComponentDialog(index: index),
                      ),
                      IconButton(
                        tooltip: 'Remove $itemName component',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _components.removeAt(index);
                            _errorText = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openComponentDialog({int? index}) async {
    final initialComponent = index == null ? null : _components[index];
    final component = await showDialog<DishComponent>(
      context: context,
      builder: (context) {
        return _DishComponentDialog(
          items: widget.store.items,
          initialComponent: initialComponent,
        );
      },
    );
    if (!mounted || component == null) {
      return;
    }
    setState(() {
      if (index == null) {
        _components.add(component);
      } else {
        _components[index] = component;
      }
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

    final dish = DishItem(
      id: widget.initialDish?.id ?? widget.store.createIdFromName(name),
      name: name,
      description: description,
      servingSizeGrams: servingSize,
      components: List<DishComponent>.of(_components),
    );
    try {
      if (_isEditing) {
        widget.store.updateDish(dish);
      } else {
        widget.store.createDish(dish);
      }
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

  String _formatInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _DishComponentDialog extends StatefulWidget {
  const _DishComponentDialog({required this.items, this.initialComponent});

  final List<CatalogItem> items;
  final DishComponent? initialComponent;

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
  void initState() {
    super.initState();
    final component = widget.initialComponent;
    if (component != null) {
      for (final item in widget.items) {
        if (item.id == component.itemId) {
          _selectedItem = item;
          break;
        }
      }
      _gramsController.text = _formatInput(component.grams);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialComponent == null ? 'Add component' : 'Edit component',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                title: 'Component amount',
                child: Semantics(
                  label: 'Component grams',
                  textField: true,
                  child: TextField(
                    controller: _gramsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Component grams',
                    ),
                  ),
                ),
              ),
              FormSectionCard(
                title: 'Catalog item',
                child: SizedBox(
                  height: 160,
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
              ),
              if (_errorText != null) InlineErrorBanner(message: _errorText!),
            ],
          ),
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

  String _formatInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}
