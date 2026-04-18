import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/models/catalog_item.dart';
import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/meal_entry.dart';
import 'package:fitapp/models/nutrition.dart';

void main() {
  group('NutritionValues', () {
    test('scales values by a factor', () {
      const values = NutritionValues(
        calories: 100,
        protein: 10,
        fat: 4,
        carbs: 20,
      );

      expect(values.scale(1.5).calories, 150);
      expect(values.scale(1.5).protein, 15);
      expect(values.scale(1.5).fat, 6);
      expect(values.scale(1.5).carbs, 30);
    });

    test('adds values together', () {
      const left = NutritionValues(calories: 100, protein: 10, fat: 4, carbs: 20);
      const right = NutritionValues(calories: 50, protein: 5, fat: 2, carbs: 10);

      expect((left + right).calories, 150);
      expect((left + right).protein, 15);
      expect((left + right).fat, 6);
      expect((left + right).carbs, 30);
    });
  });

  group('FoodItem', () {
    test('converts per 100g nutrition to serving nutrition', () {
      const food = FoodItem(
        id: 'rice',
        name: 'Rice',
        description: 'Cooked rice',
        servingSizeGrams: 150,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 130, protein: 2.7, fat: 0.3, carbs: 28),
      );

      expect(food.nutritionForGrams(150).calories, 195);
      expect(food.nutritionPerServing.calories, 195);
    });

    test('converts per 100g nutrition even when serving size is zero', () {
      const food = FoodItem(
        id: 'tomato',
        name: 'Tomato',
        description: '',
        servingSizeGrams: 0,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
      );

      expect(food.nutritionForGrams(50).calories, 9);
      expect(food.nutritionForGrams(50).protein, 0.45);
    });

    test('converts per serving nutrition to arbitrary grams', () {
      const food = FoodItem(
        id: 'oil',
        name: 'Olive oil',
        description: '',
        servingSizeGrams: 10,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(calories: 90, protein: 0, fat: 10, carbs: 0),
      );

      expect(food.nutritionForGrams(5).calories, 45);
      expect(food.nutritionForServings(1.2).fat, 12);
    });
  });

  group('DishItem', () {
    test('calculates nutrition from component items', () {
      const carrot = FoodItem(
        id: 'carrot',
        name: 'Carrot',
        description: '',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 41, protein: 0.9, fat: 0.2, carbs: 10),
      );
      const oil = FoodItem(
        id: 'oil',
        name: 'Olive oil',
        description: '',
        servingSizeGrams: 10,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(calories: 90, protein: 0, fat: 10, carbs: 0),
      );
      const dish = DishItem(
        id: 'salad',
        name: 'Salad',
        description: '',
        servingSizeGrams: 110,
        components: [
          DishComponent(itemId: 'carrot', grams: 100),
          DishComponent(itemId: 'oil', grams: 10),
        ],
      );
      final catalog = <String, CatalogItem>{
        carrot.id: CatalogItem.food(carrot),
        oil.id: CatalogItem.food(oil),
      };

      final values = dish.nutritionForGrams(110, catalog);

      expect(values.calories, 131);
      expect(values.fat, 10.2);
    });

    test('terminates on cyclic dish references and includes non-recursive items', () {
      const carrot = FoodItem(
        id: 'carrot',
        name: 'Carrot',
        description: '',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 41, protein: 0.9, fat: 0.2, carbs: 10),
      );
      const oil = FoodItem(
        id: 'oil',
        name: 'Olive oil',
        description: '',
        servingSizeGrams: 10,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(calories: 90, protein: 0, fat: 10, carbs: 0),
      );
      const dishA = DishItem(
        id: 'dish-a',
        name: 'Dish A',
        description: '',
        servingSizeGrams: 100,
        components: [
          DishComponent(itemId: 'dish-b', grams: 100),
          DishComponent(itemId: 'carrot', grams: 100),
        ],
      );
      const dishB = DishItem(
        id: 'dish-b',
        name: 'Dish B',
        description: '',
        servingSizeGrams: 100,
        components: [
          DishComponent(itemId: 'dish-a', grams: 100),
          DishComponent(itemId: 'oil', grams: 10),
        ],
      );
      final catalog = <String, CatalogItem>{
        carrot.id: CatalogItem.food(carrot),
        oil.id: CatalogItem.food(oil),
        dishA.id: CatalogItem.dish(dishA),
        dishB.id: CatalogItem.dish(dishB),
      };

      final values = CatalogItem.dish(dishA).nutritionForGrams(100, catalog);

      expect(values.calories, 131);
      expect(values.fat, 10.2);
    });
  });

  group('CatalogItem', () {
    test('returns live dish nutrition per serving from catalog', () {
      const carrot = FoodItem(
        id: 'carrot',
        name: 'Carrot',
        description: '',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 41, protein: 0.9, fat: 0.2, carbs: 10),
      );
      const oil = FoodItem(
        id: 'oil',
        name: 'Olive oil',
        description: '',
        servingSizeGrams: 10,
        basis: NutritionBasis.perServing,
        nutrition: NutritionValues(calories: 90, protein: 0, fat: 10, carbs: 0),
      );
      const dish = DishItem(
        id: 'salad',
        name: 'Salad',
        description: '',
        servingSizeGrams: 110,
        components: [
          DishComponent(itemId: 'carrot', grams: 100),
          DishComponent(itemId: 'oil', grams: 10),
        ],
      );
      final catalog = <String, CatalogItem>{
        carrot.id: CatalogItem.food(carrot),
        oil.id: CatalogItem.food(oil),
        dish.id: CatalogItem.dish(dish),
      };

      expect(
        CatalogItem.dish(dish).nutritionPerServing(catalog).calories,
        131,
      );
      expect(
        CatalogItem.dish(dish).nutritionPerServing(catalog).fat,
        10.2,
      );
    });
  });

  group('MealEntry', () {
    test('stores a nutrition snapshot independent of the source item', () {
      const source = FoodItem(
        id: 'chicken',
        name: 'Chicken breast',
        description: '',
        servingSizeGrams: 100,
        basis: NutritionBasis.per100g,
        nutrition: NutritionValues(calories: 165, protein: 31, fat: 3.6, carbs: 0),
      );

      final entry = MealEntry.fromItem(
        id: 'entry-1',
        item: CatalogItem.food(source),
        consumedGrams: 200,
        mode: MealEntryMode.grams,
        enteredQuantity: 200,
        catalog: const {},
      );

      expect(entry.itemName, 'Chicken breast');
      expect(entry.consumedGrams, 200);
      expect(entry.nutrition.calories, 330);
      expect(entry.nutrition.protein, 62);
    });
  });
}
