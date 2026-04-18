import 'package:fitapp/models/dish_item.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem tomato() => const FoodItem(
  id: 'tomato',
  name: 'Tomato',
  description: 'Fresh tomato',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9),
);

void main() {
  test('AppStore starts with exactly five sample foods', () {
    final store = AppStore();

    expect(store.items, hasLength(5));
    expect(store.searchItems('chicken').single.name, 'Chicken breast');
  });

  test('AppStore.empty creates food and searches by name or description', () {
    final store = AppStore.empty();

    store.createFood(tomato());

    expect(store.searchItems('tomato').single.id, 'tomato');
    expect(store.searchItems('fresh').single.id, 'tomato');
  });

  test('meal entries store snapshots across food updates', () {
    final store = AppStore.empty();
    store.createFood(tomato());

    final gramsEntry = store.addMealByGrams(itemId: 'tomato', grams: 200);
    final servingsEntry = store.addMealByServings(
      itemId: 'tomato',
      servings: 0.5,
    );

    store.updateFood(
      tomato().copyWith(
        nutrition: const NutritionValues(
          calories: 100,
          protein: 1,
          fat: 1,
          carbs: 1,
        ),
      ),
    );

    expect(gramsEntry.itemName, 'Tomato');
    expect(gramsEntry.nutrition.calories, 36);
    expect(servingsEntry.itemName, 'Tomato');
    expect(servingsEntry.nutrition.calories, 9);
    expect(store.dailyTotals.calories, 45);
  });

  test('updating a dish id with an existing food id is rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      () => store.updateDish(
        const DishItem(
          id: 'tomato',
          name: 'Tomato salad',
          description: 'Wrong type',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'tomato', grams: 100)],
        ),
      ),
      throwsArgumentError,
    );
  });

  test('updating a food id with an existing dish id is rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      () => store.updateFood(
        const FoodItem(
          id: 'salad',
          name: 'Salad',
          description: 'Wrong type',
          servingSizeGrams: 100,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: 10,
            protein: 1,
            fat: 1,
            carbs: 1,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('dish nutrition is live and deleting referenced food is blocked', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.createDish(
      const DishItem(
        id: 'salad',
        name: 'Salad',
        description: 'Tomato salad',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );

    expect(
      store.itemById('salad')!.nutritionPerServing(store.catalog).calories,
      18,
    );
    expect(() => store.deleteItem('tomato'), throwsStateError);
  });

  test('deleting items used only by meal snapshots is allowed', () {
    final store = AppStore.empty();
    store.createFood(tomato());
    store.addMealByGrams(itemId: 'tomato', grams: 100);

    store.deleteItem('tomato');

    expect(store.itemById('tomato'), isNull);
    expect(store.mealEntries.single.itemName, 'Tomato');
    expect(store.dailyTotals.calories, 18);
  });

  test('dish cycles are rejected', () {
    final store = AppStore.empty();
    store.createFood(tomato());

    expect(
      () => store.createDish(
        const DishItem(
          id: 'bad',
          name: 'Bad',
          description: 'Bad dish',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'bad', grams: 100)],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    store.createDish(
      const DishItem(
        id: 'base',
        name: 'Base',
        description: 'Base dish',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'tomato', grams: 100)],
      ),
    );
    store.createDish(
      const DishItem(
        id: 'wrapper',
        name: 'Wrapper',
        description: 'Wrapper dish',
        servingSizeGrams: 100,
        components: [DishComponent(itemId: 'base', grams: 100)],
      ),
    );

    expect(
      () => store.updateDish(
        const DishItem(
          id: 'base',
          name: 'Base',
          description: 'Base dish',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'wrapper', grams: 100)],
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'stored dishes are isolated from caller-side component list mutation',
    () {
      final store = AppStore.empty();
      store.createFood(tomato());
      final components = <DishComponent>[
        const DishComponent(itemId: 'tomato', grams: 100),
      ];

      store.createDish(
        DishItem(
          id: 'salad',
          name: 'Salad',
          description: 'Tomato salad',
          servingSizeGrams: 100,
          components: components,
        ),
      );

      components.clear();
      components.add(const DishComponent(itemId: 'missing', grams: 50));

      expect(
        store.itemById('salad')!.nutritionPerServing(store.catalog).calories,
        18,
      );
      expect(() => store.deleteItem('tomato'), throwsStateError);
    },
  );

  test('rejects non-finite numeric values', () {
    final store = AppStore.empty();

    expect(
      () => store.createFood(
        const FoodItem(
          id: 'bad-food',
          name: 'Bad food',
          description: 'Bad',
          servingSizeGrams: 100,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(
            calories: double.nan,
            protein: 1,
            fat: 1,
            carbs: 1,
          ),
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => store.createFood(
        const FoodItem(
          id: 'bad-serving',
          name: 'Bad serving',
          description: 'Bad',
          servingSizeGrams: double.infinity,
          basis: NutritionBasis.per100g,
          nutrition: NutritionValues(calories: 1, protein: 1, fat: 1, carbs: 1),
        ),
      ),
      throwsArgumentError,
    );

    store.createFood(tomato());

    expect(
      () => store.createDish(
        const DishItem(
          id: 'bad-dish',
          name: 'Bad dish',
          description: 'Bad',
          servingSizeGrams: 100,
          components: [DishComponent(itemId: 'tomato', grams: double.nan)],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => store.addMealByGrams(itemId: 'tomato', grams: double.infinity),
      throwsArgumentError,
    );
    expect(
      () => store.addMealByServings(itemId: 'tomato', servings: double.nan),
      throwsArgumentError,
    );
  });
}
