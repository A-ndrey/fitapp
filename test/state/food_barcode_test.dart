import 'package:fitapp/models/food_barcode.dart';
import 'package:fitapp/models/food_item.dart';
import 'package:fitapp/models/nutrition.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/persistence/persisted_app_state_codec.dart';
import 'package:fitapp/state/persistence/shared_preferences_app_store_persistence.dart';
import 'package:fitapp/state/sync/persisted_entity_bundle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const food = FoodItem(
  id: 'milk',
  name: 'Milk',
  description: '',
  servingSizeGrams: 100,
  basis: NutritionBasis.per100g,
  nutrition: NutritionValues(calories: 60, protein: 3, fat: 3, carbs: 5),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy foods retain their serialized representation and content hash',
    () {
      final legacy = <String, Object?>{
        'id': 'milk',
        'name': 'Milk',
        'description': '',
        'servingSizeGrams': 100.0,
        'basis': 'per100g',
        'nutrition': <String, Object?>{
          'calories': 60.0,
          'protein': 3.0,
          'fat': 3.0,
          'carbs': 5.0,
        },
      };
      final decoded = PersistedAppStateCodec.decodeFoodItem(legacy);
      expect(decoded.barcodes, isEmpty);
      final encoded = PersistedAppStateCodec.encodeFoodItem(decoded);
      expect(encoded, legacy);
      expect(
        PersistedEntityBundle.hashJson(encoded),
        PersistedEntityBundle.hashJson(legacy),
      );
    },
  );

  test('barcodes round trip as text including leading zeroes', () {
    final original = food.copyWith(barcodes: ['0012345678905', '96385074']);
    final decoded = PersistedAppStateCodec.decodeFoodItem(
      PersistedAppStateCodec.encodeFoodItem(original),
    );
    expect(decoded.barcodes, original.barcodes);
    expect(() => decoded.barcodes.add('123'), throwsUnsupportedError);
    expect(
      () => PersistedAppStateCodec.decodeFoodItem({
        ...PersistedAppStateCodec.encodeFoodItem(food),
        'barcodes': [12345678],
      }),
      throwsFormatException,
    );
  });

  test('only packaging digit lengths are accepted', () {
    for (final value in [
      '96385074',
      '012345678905',
      '0012345678905',
      '00012345678905',
    ]) {
      expect(FoodBarcode.isValid(value), isTrue);
    }
    final store = AppStore();
    addTearDown(store.dispose);
    for (final invalid in [
      '',
      '123',
      'https://food.test',
      '1234567a',
      '123456789',
    ]) {
      expect(
        () => store.createFood(food.copyWith(barcodes: [invalid])),
        throwsArgumentError,
      );
    }
  });

  test('unique lookup treats equivalent UPC and EAN representations alike', () {
    final store = AppStore();
    addTearDown(store.dispose);
    store.createFood(food.copyWith(barcodes: ['012345678905', '96385074']));
    expect(store.foodByBarcode('0012345678905')?.id, food.id);
    expect(store.foodByBarcode('00012345678905')?.id, food.id);
    expect(store.foodByBarcode('96385074')?.id, food.id);
    expect(store.foodByBarcode('bad'), isNull);
    expect(store.searchItems('96385074').single.id, food.id);
    expect(
      () => store.createFood(
        food.copyWith(id: 'other', name: 'Other', barcodes: ['0012345678905']),
      ),
      throwsA(isA<BarcodeAlreadyBound>()),
    );
    expect(
      () => store.updateFood(
        food.copyWith(barcodes: ['012345678905', '0012345678905']),
      ),
      throwsArgumentError,
    );
    store.bindFoodBarcode(foodId: food.id, barcode: '0012345678905');
    expect(store.itemById(food.id)!.food!.barcodes, hasLength(2));
  });

  test(
    'store and snapshots own immutable barcode lists; history stays unchanged',
    () {
      final codes = ['0012345678905'];
      final store = AppStore();
      addTearDown(store.dispose);
      store.createFood(food.copyWith(barcodes: codes));
      final entry = store.addMealByGrams(itemId: food.id, grams: 100);
      final snapshot = store.persistedSnapshot;
      codes.clear();
      expect(store.foodByBarcode('0012345678905')?.id, food.id);
      expect(
        () => snapshot.userFoods.single.barcodes.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => store.itemById(food.id)!.food!.barcodes.clear(),
        throwsUnsupportedError,
      );
      store.updateFood(store.itemById(food.id)!.food!.copyWith(barcodes: []));
      expect(store.foodByBarcode('0012345678905'), isNull);
      store.createFood(
        food.copyWith(id: 'other', name: 'Other', barcodes: ['0012345678905']),
      );
      expect(store.foodByBarcode('0012345678905')?.id, 'other');
      expect(snapshot.userFoods.single.barcodes, ['0012345678905']);
      expect(store.mealEntries.single, entry);
      expect(store.mealEntries.single.nutrition.calories, 60);
    },
  );

  test(
    'old food loads and new bindings survive persistence and rehydration',
    () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = SharedPreferencesAppStorePersistence();
      final original = AppStore(persistence: persistence)..createFood(food);
      addTearDown(original.dispose);
      await original.flushPersistence();
      final loaded = await AppStore.hydrated(
        persistence: SharedPreferencesAppStorePersistence(),
      );
      addTearDown(loaded.dispose);
      expect(loaded.itemById(food.id)!.food!.barcodes, isEmpty);
      loaded.bindFoodBarcode(foodId: food.id, barcode: '0012345678905');
      loaded.bindFoodBarcode(foodId: food.id, barcode: '96385074');
      await loaded.flushPersistence();
      final reloaded = await AppStore.hydrated(
        persistence: SharedPreferencesAppStorePersistence(),
      );
      addTearDown(reloaded.dispose);
      expect(reloaded.foodByBarcode('0012345678905')?.id, food.id);
      expect(reloaded.itemById(food.id)!.food!.barcodes, [
        '0012345678905',
        '96385074',
      ]);
    },
  );
}
