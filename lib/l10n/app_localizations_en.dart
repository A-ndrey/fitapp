// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FitApp';

  @override
  String get destinationToday => 'Today';

  @override
  String get destinationTrain => 'Train';

  @override
  String get destinationNutrition => 'Nutrition';

  @override
  String get destinationLibrary => 'Library';

  @override
  String get destinationMore => 'More';

  @override
  String get todayReadyState => 'Ready state';

  @override
  String get todayInSession => 'In session';

  @override
  String get todayCompletedWorkouts => 'Completed workouts';

  @override
  String get todaySessionsSuffix => 'sessions';

  @override
  String get todayElapsedSuffix => 'elapsed';

  @override
  String durationHoursMinutesSemantic(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String durationMinutesSecondsSemantic(int minutes, int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String durationSecondsSemantic(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get todayDailyFuelTitle => 'Daily fuel';

  @override
  String get todayDailyFuelSubtitle => 'Macros logged today';

  @override
  String get todayQuickActionsTitle => 'Quick actions';

  @override
  String get todayStartWorkoutAction => 'Start workout';

  @override
  String get todayOpenWorkoutAction => 'Open workout';

  @override
  String get todayStartWorkoutSubtitle => 'Choose a plan and begin training';

  @override
  String get todayOpenWorkoutSubtitle => 'Return to the active session';

  @override
  String get todayOpenTrainHint => 'Opens Train tab';

  @override
  String get todayLogMealAction => 'Log meal';

  @override
  String get todayLogMealSubtitle => 'Add calories and macros for today';

  @override
  String get todayOpenNutritionHint => 'Opens Nutrition tab';

  @override
  String get todayManageLibraryAction => 'Manage library';

  @override
  String get todayManageLibrarySubtitle =>
      'Update foods, dishes, exercises, and plans';

  @override
  String get todayOpenLibraryHint => 'Opens Library tab';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionKilocaloriesSemantic => 'kilocalories';

  @override
  String get nutritionGramsSemantic => 'grams';

  @override
  String get nutritionKilocalorieUnit => 'kcal';

  @override
  String get nutritionGramUnit => 'g';

  @override
  String get nutritionProteinInlineLabel => 'protein';

  @override
  String get nutritionFatInlineLabel => 'fat';

  @override
  String get nutritionCarbsInlineLabel => 'carbs';

  @override
  String get catalogSubtypeFood => 'food';

  @override
  String get catalogSubtypeDish => 'dish';

  @override
  String get mealLoggedSuffix => 'logged';

  @override
  String get mealServingsQuantitySuffix => 'servings';

  @override
  String get mealRemoveEntryTooltip => 'Remove meal entry';

  @override
  String get mealTitle => 'Meal';

  @override
  String get mealAddItemAction => 'Add meal item';

  @override
  String get mealCockpitTitle => 'Nutrition cockpit';

  @override
  String get mealCockpitSubtitle =>
      'Log food, review macros, and keep today visible.';

  @override
  String get mealDailyTotalsTitle => 'Daily totals';

  @override
  String get mealEntriesTitle => 'Meal entries';

  @override
  String get mealEmptyTitle => 'No meal entries yet';

  @override
  String get mealEmptyMessage => 'Use Add meal item to start today\'s log.';

  @override
  String get mealSearchSheetTitle => 'Add meal item';

  @override
  String get mealSearchSheetSubtitle =>
      'Search your saved foods and dishes, or create a new food from your query.';

  @override
  String get mealSearchFieldLabel => 'Search foods and dishes';

  @override
  String mealCreateItem(String query) {
    return 'Create \"$query\"';
  }

  @override
  String get mealAmountPrompt =>
      'Choose how much you ate, then add it to today\'s meal log.';

  @override
  String get mealGramsLabel => 'Grams';

  @override
  String get mealServingsLabel => 'Servings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get mealAddToMealAction => 'Add to meal';

  @override
  String get moreSubtitle => 'Tune units, appearance, and sync preferences.';

  @override
  String get moreSyncTitle => 'Sync';

  @override
  String get moreSyncStatusTitle => 'Sync status';

  @override
  String get moreSyncSignedInMessage =>
      'Sync status: signed in. Firebase sync is still a placeholder.';

  @override
  String get moreSyncSignedOutMessage =>
      'Sync status: signed out. Firebase sync is still a placeholder.';

  @override
  String get moreLoginAction => 'Login';

  @override
  String get moreLogoutAction => 'Logout';

  @override
  String get settingsUnitsTitle => 'Units';

  @override
  String get settingsWorkoutWeightTitle => 'Workout weight';

  @override
  String get settingsWorkoutWeightSubtitle =>
      'Weights shown during training sessions.';

  @override
  String get settingsDishWeightTitle => 'Dish weight';

  @override
  String get settingsDishWeightSubtitle =>
      'Food and recipe serving measurements.';

  @override
  String get settingsHeightTitle => 'Height';

  @override
  String get settingsDistanceTitle => 'Distance';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'App language';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle => 'Theme';

  @override
  String get unitKilograms => 'Kilograms';

  @override
  String get unitPounds => 'Pounds';

  @override
  String get unitGrams => 'Grams';

  @override
  String get unitOunces => 'Ounces';

  @override
  String get unitCentimeters => 'Centimeters';

  @override
  String get unitInches => 'Inches';

  @override
  String get unitKilometers => 'Kilometers';

  @override
  String get unitMiles => 'Miles';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';
}
