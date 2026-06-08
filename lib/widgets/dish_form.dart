import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_item.dart';
import '../models/dish_item.dart';
import '../state/app_store.dart';
import '../ui/core/forms/form_error_messages.dart';
import '../ui/core/input/numeric_input_formatters.dart';
import '../ui/core/widgets/empty_state.dart';
import '../ui/core/widgets/form_shell.dart';
import '../ui/nutrition/catalog_item_search_sheet.dart';
import 'catalog_form_shared.dart';

class DishForm extends StatefulWidget {
  const DishForm({
    super.key,
    required this.store,
    this.initialDish,
    this.fullScreen = false,
  });

  final AppStore store;
  final DishItem? initialDish;
  final bool fullScreen;

  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _servingSizeController;
  final List<_DishComponentDraft> _componentDrafts = <_DishComponentDraft>[];
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
      _componentDrafts.addAll(
        dish.components.map(
          (component) => _DishComponentDraft(
            itemId: component.itemId,
            gramsText: _formatInput(component.grams),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    for (final draft in _componentDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _isEditing
        ? l10n?.dishFormEditTitle ?? 'Edit recipe'
        : l10n?.dishFormTitle ?? 'Recipe';
    final subtitle =
        l10n?.dishFormSubtitle ?? 'Combine foods into a reusable recipe.';
    final primaryActionLabel = l10n?.dishSaveAction ?? 'Save recipe';
    final children = [
      if (_isEditing) _buildComponentsSection(),
      _buildBasicsSection(),
      if (!_isEditing) _buildComponentsSection(),
      if (_errorText != null) InlineErrorBanner(message: _errorText!),
    ];

    return CatalogFormShell(
      title: title,
      subtitle: subtitle,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: _saveDish,
      fullScreen: widget.fullScreen,
      maxDialogWidth: 640,
      children: children,
    );
  }

  Widget _buildBasicsSection() {
    final l10n = AppLocalizations.of(context);
    return CatalogBasicsSection(
      sectionTitle: l10n?.dishBasicsSectionTitle ?? 'Recipe basics',
      sectionSubtitle:
          l10n?.dishBasicsSectionSubtitle ??
          'Name this recipe and define one serving.',
      nameLabel: l10n?.dishNameFieldLabel ?? 'Recipe name',
      descriptionLabel: l10n?.dishDescriptionFieldLabel ?? 'Recipe description',
      servingSizeLabel:
          l10n?.dishServingSizeGramsFieldLabel ?? 'Recipe serving size grams',
      nameController: _nameController,
      descriptionController: _descriptionController,
      servingSizeController: _servingSizeController,
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
              onPressed: _openAddIngredientSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n?.dishAddComponentAction ?? 'Add ingredient'),
            ),
          ),
          const SizedBox(height: 12),
          if (_componentDrafts.isEmpty)
            AppEmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: l10n?.dishNoComponentsTitle ?? 'No ingredients yet',
              message:
                  l10n?.dishNoComponentsMessage ??
                  'Add foods to calculate this recipe.',
            )
          else
            ..._componentDrafts.indexed.map((entry) {
              final index = entry.$1;
              final draft = entry.$2;
              final item = widget.store.itemById(draft.itemId);
              return _buildComponentRow(index: index, draft: draft, item: item);
            }),
        ],
      ),
    );
  }

  Widget _buildComponentRow({
    required int index,
    required _DishComponentDraft draft,
    required CatalogItem? item,
  }) {
    final l10n = AppLocalizations.of(context);
    final itemName = item?.name ?? draft.itemId;
    final itemKind = item == null
        ? null
        : item.isFood
        ? l10n?.catalogSubtypeFood ?? 'food'
        : l10n?.catalogSubtypeDish ?? 'recipe';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemName, style: Theme.of(context).textTheme.titleSmall),
                  if (itemKind != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      itemKind,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 128,
              child: TextField(
                controller: draft.gramsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: positiveDecimalInputFormatters,
                decoration: InputDecoration(
                  labelText:
                      l10n?.dishComponentGramsFieldLabel ?? 'Ingredient grams',
                  suffixText: 'g',
                ),
                onChanged: (_) {
                  if (_errorText == null) {
                    return;
                  }
                  setState(() {
                    _errorText = null;
                  });
                },
              ),
            ),
            IconButton(
              tooltip:
                  l10n?.dishRemoveComponentTooltip(itemName) ??
                  'Remove $itemName ingredient',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  _componentDrafts.removeAt(index).dispose();
                  _errorText = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddIngredientSheet() async {
    final l10n = AppLocalizations.of(context);
    final recentItems = _recentComponentItems();
    final frequentItems = widget.store.items.take(4).toList(growable: false);
    final result = await showCatalogItemSearchSheet(
      context: context,
      store: widget.store,
      title: l10n?.dishComponentAddTitle ?? 'Add ingredient',
      subtitle:
          'Search saved foods and recipes, then set the ingredient grams in the recipe list.',
      searchFieldLabel: l10n?.mealSearchFieldLabel ?? 'Search ingredients',
      recentItems: recentItems,
      recentLabel: l10n?.dishComponentsSectionTitle ?? 'Ingredients',
      frequentItems: frequentItems,
      frequentLabel: 'Frequent foods',
    );
    if (!mounted || result?.item == null) {
      return;
    }
    setState(() {
      _componentDrafts.add(
        _DishComponentDraft(
          itemId: result!.item!.id,
          gramsText: _formatInput(result.item!.servingSizeGrams),
        ),
      );
      _errorText = null;
    });
  }

  void _saveDish() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final components = _parseComponents();
    if (components == null) {
      setState(() {
        _errorText =
            AppLocalizations.of(context)?.dishComponentValidation ??
            'Choose an item and enter valid ingredient grams.';
      });
      return;
    }
    final servingSizeInput = _servingSizeController.text.trim();
    final servingSize = servingSizeInput.isEmpty
        ? components.fold<double>(
            0,
            (total, component) => total + component.grams,
          )
        : double.tryParse(servingSizeInput);
    if (name.isEmpty ||
        servingSize == null ||
        !servingSize.isFinite ||
        servingSize <= 0 ||
        components.isEmpty) {
      setState(() {
        _errorText =
            AppLocalizations.of(context)?.dishValidation ??
            'Enter recipe details and at least one ingredient.';
      });
      return;
    }

    final dish = DishItem(
      id: widget.initialDish?.id ?? widget.store.createId(),
      name: name,
      description: description,
      servingSizeGrams: servingSize,
      components: components,
    );
    try {
      if (_isEditing) {
        widget.store.updateDish(dish);
      } else {
        widget.store.createDish(dish);
      }
    } on ArgumentError catch (error) {
      setState(() {
        _errorText = humanReadableFormError(
          error,
          resourceName: 'recipe',
          fallback:
              AppLocalizations.of(context)?.dishCouldNotSave ??
              'Could not save recipe.',
        );
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  List<CatalogItem> _recentComponentItems() {
    final recentItems = <CatalogItem>[];
    final seenIds = <String>{};
    for (final draft in _componentDrafts.reversed) {
      if (!seenIds.add(draft.itemId)) {
        continue;
      }
      final item = widget.store.itemById(draft.itemId);
      if (item == null) {
        continue;
      }
      recentItems.add(item);
      if (recentItems.length == 4) {
        break;
      }
    }
    return recentItems;
  }

  List<DishComponent>? _parseComponents() {
    final components = <DishComponent>[];
    for (final draft in _componentDrafts) {
      final grams = double.tryParse(draft.gramsController.text.trim());
      if (grams == null || !grams.isFinite || grams <= 0) {
        return null;
      }
      components.add(DishComponent(itemId: draft.itemId, grams: grams));
    }
    return components;
  }

  String _formatInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}

class _DishComponentDraft {
  _DishComponentDraft({required this.itemId, required String gramsText})
    : gramsController = TextEditingController(text: gramsText);

  final String itemId;
  final TextEditingController gramsController;

  void dispose() {
    gramsController.dispose();
  }
}
