enum AppearancePreference { system, light, dark }

enum LanguagePreference { english }

enum WorkoutWeightUnit { kilograms, pounds }

enum DishWeightUnit { grams, ounces }

enum HeightUnit { centimeters, inches }

enum DistanceUnit { kilometers, miles }

class AppPreferences {
  const AppPreferences({
    required this.appearance,
    required this.language,
    required this.workoutWeightUnit,
    required this.dishWeightUnit,
    required this.heightUnit,
    required this.distanceUnit,
  });

  const AppPreferences.defaults()
    : appearance = AppearancePreference.system,
      language = LanguagePreference.english,
      workoutWeightUnit = WorkoutWeightUnit.kilograms,
      dishWeightUnit = DishWeightUnit.grams,
      heightUnit = HeightUnit.centimeters,
      distanceUnit = DistanceUnit.kilometers;

  final AppearancePreference appearance;
  final LanguagePreference language;
  final WorkoutWeightUnit workoutWeightUnit;
  final DishWeightUnit dishWeightUnit;
  final HeightUnit heightUnit;
  final DistanceUnit distanceUnit;

  AppPreferences copyWith({
    AppearancePreference? appearance,
    LanguagePreference? language,
    WorkoutWeightUnit? workoutWeightUnit,
    DishWeightUnit? dishWeightUnit,
    HeightUnit? heightUnit,
    DistanceUnit? distanceUnit,
  }) {
    return AppPreferences(
      appearance: appearance ?? this.appearance,
      language: language ?? this.language,
      workoutWeightUnit: workoutWeightUnit ?? this.workoutWeightUnit,
      dishWeightUnit: dishWeightUnit ?? this.dishWeightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppPreferences &&
        other.appearance == appearance &&
        other.language == language &&
        other.workoutWeightUnit == workoutWeightUnit &&
        other.dishWeightUnit == dishWeightUnit &&
        other.heightUnit == heightUnit &&
        other.distanceUnit == distanceUnit;
  }

  @override
  int get hashCode => Object.hash(
    appearance,
    language,
    workoutWeightUnit,
    dishWeightUnit,
    heightUnit,
    distanceUnit,
  );
}
