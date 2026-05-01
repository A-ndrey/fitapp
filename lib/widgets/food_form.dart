import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/food_item.dart';
import '../models/nutrition.dart';
import '../state/app_store.dart';
import '../ui/core/widgets/form_shell.dart';

class FoodForm extends StatefulWidget {
  const FoodForm({
    super.key,
    required this.store,
    this.initialName = '',
    this.initialFood,
  });

  final AppStore store;
  final String initialName;
  final FoodItem? initialFood;

  @override
  State<FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<FoodForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _servingSizeController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  NutritionBasis _basis = NutritionBasis.per100g;
  String? _errorText;
  bool get _isEditing => widget.initialFood != null;

  @override
  void initState() {
    super.initState();
    final food = widget.initialFood;
    _nameController = TextEditingController(
      text: food?.name ?? widget.initialName,
    );
    _descriptionController = TextEditingController(
      text: food?.description ?? '',
    );
    _servingSizeController = TextEditingController(
      text: food == null ? '' : _format(food.servingSizeGrams),
    );
    _caloriesController = TextEditingController(
      text: food == null ? '' : _format(food.nutrition.calories),
    );
    _proteinController = TextEditingController(
      text: food == null ? '' : _format(food.nutrition.protein),
    );
    _fatController = TextEditingController(
      text: food == null ? '' : _format(food.nutrition.fat),
    );
    _carbsController = TextEditingController(
      text: food == null ? '' : _format(food.nutrition.carbs),
    );
    _basis = food?.basis ?? NutritionBasis.per100g;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormShellDialog(
      title: _isEditing
          ? l10n?.foodFormEditTitle ?? 'Edit food'
          : l10n?.foodFormTitle ?? 'Food item',
      subtitle:
          l10n?.foodFormSubtitle ??
          'Define reusable food data for faster meal logging.',
      primaryActionLabel: l10n?.foodSaveAction ?? 'Save food',
      onPrimaryAction: _saveFood,
      children: [
        FormSectionCard(
          title: l10n?.foodBasicsSectionTitle ?? 'Food basics',
          subtitle:
              l10n?.foodBasicsSectionSubtitle ??
              'Name this item and define the serving anchor.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n?.foodNameFieldLabel ?? 'Name',
                ),
              ),
              TextField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n?.foodDescriptionFieldLabel ?? 'Description',
                ),
              ),
              TextField(
                controller: _servingSizeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText:
                      l10n?.foodServingSizeGramsFieldLabel ??
                      'Serving size grams',
                ),
              ),
            ],
          ),
        ),
        FormSectionCard(
          title: l10n?.foodNutritionFactsTitle ?? 'Nutrition facts',
          subtitle:
              l10n?.foodNutritionFactsSubtitle ??
              'Enter values using the selected nutrition basis.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<NutritionBasis>(
                segments: [
                  ButtonSegment(
                    value: NutritionBasis.per100g,
                    label: Text(l10n?.foodNutritionPer100g ?? 'Per 100g'),
                  ),
                  ButtonSegment(
                    value: NutritionBasis.perServing,
                    label: Text(l10n?.foodNutritionPerServing ?? 'Per serving'),
                  ),
                ],
                selected: {_basis},
                onSelectionChanged: (selection) {
                  setState(() {
                    _basis = selection.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              ResponsiveFormGrid(
                children: [
                  TextField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n?.nutritionCalories ?? 'Calories',
                    ),
                  ),
                  TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n?.nutritionProtein ?? 'Protein',
                    ),
                  ),
                  TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n?.nutritionFat ?? 'Fat',
                    ),
                  ),
                  TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n?.nutritionCarbs ?? 'Carbs',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_errorText != null) InlineErrorBanner(message: _errorText!),
      ],
    );
  }

  void _saveFood() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final servingSize = _parsePositive(_servingSizeController);
    final calories = _parseNonNegative(_caloriesController);
    final protein = _parseNonNegative(_proteinController);
    final fat = _parseNonNegative(_fatController);
    final carbs = _parseNonNegative(_carbsController);

    if (name.isEmpty ||
        servingSize == null ||
        calories == null ||
        protein == null ||
        fat == null ||
        carbs == null) {
      setState(() {
        _errorText =
            AppLocalizations.of(context)?.foodValidation ??
            'Enter a name and valid nutrition values.';
      });
      return;
    }

    final id = widget.initialFood?.id ?? widget.store.createIdFromName(name);
    final food = FoodItem(
      id: id,
      name: name,
      description: description,
      servingSizeGrams: servingSize,
      basis: _basis,
      nutrition: NutritionValues(
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
      ),
    );
    try {
      if (_isEditing) {
        widget.store.updateFood(food);
      } else {
        widget.store.createFood(food);
      }
    } on ArgumentError catch (error) {
      setState(() {
        _errorText =
            error.message?.toString() ??
            AppLocalizations.of(context)?.foodCouldNotSave ??
            'Could not save food.';
      });
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(id);
  }

  double? _parsePositive(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || !value.isFinite || value <= 0) {
      return null;
    }
    return value;
  }

  double? _parseNonNegative(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || !value.isFinite || value < 0) {
      return null;
    }
    return value;
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}
