import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/nutrition.dart';
import '../state/app_store.dart';

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
    return AlertDialog(
      title: Text(_isEditing ? 'Edit food' : 'Food item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descriptionController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _servingSizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Serving size grams',
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<NutritionBasis>(
              segments: const [
                ButtonSegment(
                  value: NutritionBasis.per100g,
                  label: Text('Per 100g'),
                ),
                ButtonSegment(
                  value: NutritionBasis.perServing,
                  label: Text('Per serving'),
                ),
              ],
              selected: {_basis},
              onSelectionChanged: (selection) {
                setState(() {
                  _basis = selection.first;
                });
              },
            ),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Calories'),
            ),
            TextField(
              controller: _proteinController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Protein'),
            ),
            TextField(
              controller: _fatController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Fat'),
            ),
            TextField(
              controller: _carbsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Carbs'),
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
        FilledButton(onPressed: _saveFood, child: const Text('Save food')),
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
        _errorText = 'Enter a name and valid nutrition values.';
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
        _errorText = error.message?.toString() ?? 'Could not save food.';
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
