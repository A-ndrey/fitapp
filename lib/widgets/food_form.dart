import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/nutrition.dart';
import '../state/app_store.dart';

class FoodForm extends StatefulWidget {
  const FoodForm({super.key, required this.store, this.initialName = ''});

  final AppStore store;
  final String initialName;

  @override
  State<FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<FoodForm> {
  late final TextEditingController _nameController;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingSizeController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  NutritionBasis _basis = NutritionBasis.per100g;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
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
      title: const Text('Food item'),
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

    final id = widget.store.createIdFromName(name);
    try {
      widget.store.createFood(
        FoodItem(
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
        ),
      );
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
}
