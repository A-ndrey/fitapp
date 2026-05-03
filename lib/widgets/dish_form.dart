import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return FormShellDialog(
      title: _isEditing
          ? l10n?.dishFormEditTitle ?? 'Edit recipe'
          : l10n?.dishFormTitle ?? 'Recipe',
      subtitle:
          l10n?.dishFormSubtitle ?? 'Combine foods into a reusable recipe.',
      primaryActionLabel: l10n?.dishSaveAction ?? 'Save recipe',
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
    final l10n = AppLocalizations.of(context);
    return FormSectionCard(
      title: l10n?.dishBasicsSectionTitle ?? 'Recipe basics',
      subtitle:
          l10n?.dishBasicsSectionSubtitle ??
          'Name this recipe and define one serving.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n?.dishNameFieldLabel ?? 'Recipe name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText:
                  l10n?.dishDescriptionFieldLabel ?? 'Recipe description',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _servingSizeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText:
                  l10n?.dishServingSizeGramsFieldLabel ??
                  'Recipe serving size grams',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsSection() {
    final l10n = AppLocalizations.of(context);
    return FormSectionCard(
      title: l10n?.dishComponentsSectionTitle ?? 'Ingredients',
      subtitle:
          l10n?.dishComponentsSectionSubtitle ??
          'Add ingredients to calculate serving nutrition.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _openComponentDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n?.dishAddComponentAction ?? 'Add ingredient'),
            ),
          ),
          const SizedBox(height: 12),
          if (_components.isEmpty)
            AppEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: l10n?.dishNoComponentsTitle ?? 'No ingredients yet',
              message:
                  l10n?.dishNoComponentsMessage ??
                  'Add foods to calculate this recipe.',
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
                        tooltip:
                            l10n?.dishEditComponentTooltip(itemName) ??
                            'Edit $itemName ingredient',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openComponentDialog(index: index),
                      ),
                      IconButton(
                        tooltip:
                            l10n?.dishRemoveComponentTooltip(itemName) ??
                            'Remove $itemName ingredient',
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
    final servingSizeInput = _servingSizeController.text.trim();
    final servingSize = servingSizeInput.isEmpty
        ? _components.fold<double>(
            0,
            (total, component) => total + component.grams,
          )
        : double.tryParse(servingSizeInput);
    if (name.isEmpty ||
        servingSize == null ||
        !servingSize.isFinite ||
        servingSize <= 0 ||
        _components.isEmpty) {
      setState(() {
        _errorText =
            AppLocalizations.of(context)?.dishValidation ??
            'Enter recipe details and at least one ingredient.';
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
        _errorText =
            error.message?.toString() ??
            AppLocalizations.of(context)?.dishCouldNotSave ??
            'Could not save recipe.';
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initialComponent == null
            ? l10n?.dishComponentAddTitle ?? 'Add ingredient'
            : l10n?.dishComponentEditTitle ?? 'Edit ingredient',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSectionCard(
                title: l10n?.dishComponentAmountTitle ?? 'Ingredient amount',
                child: Semantics(
                  label:
                      l10n?.dishComponentGramsFieldLabel ?? 'Ingredient grams',
                  textField: true,
                  child: TextField(
                    controller: _gramsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          l10n?.dishComponentGramsFieldLabel ??
                          'Ingredient grams',
                    ),
                  ),
                ),
              ),
              FormSectionCard(
                title: l10n?.dishCatalogItemSectionTitle ?? 'Catalog item',
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
                        subtitle: Text(
                          item.isFood
                              ? l10n?.catalogSubtypeFood ?? 'food'
                              : l10n?.catalogSubtypeDish ?? 'recipe',
                        ),
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
          child: Text(l10n?.commonCancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _saveComponent,
          child: Text(l10n?.dishSaveComponentAction ?? 'Save ingredient'),
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
        _errorText =
            AppLocalizations.of(context)?.dishComponentValidation ??
            'Choose an item and enter valid grams.';
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
