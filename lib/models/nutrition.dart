class NutritionValues {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const NutritionValues({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  static const zero = NutritionValues(
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
  );

  NutritionValues scale(double factor) {
    return NutritionValues(
      calories: calories * factor,
      protein: protein * factor,
      fat: fat * factor,
      carbs: carbs * factor,
    );
  }

  NutritionValues operator +(NutritionValues other) {
    return NutritionValues(
      calories: calories + other.calories,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
    );
  }
}

enum NutritionBasis { per100g, perServing }
