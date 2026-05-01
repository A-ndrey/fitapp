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

  @override
  String get workoutTitle => 'Workout';

  @override
  String get workoutTrainingCockpitTitle => 'Training cockpit';

  @override
  String get workoutTrainingCockpitSubtitle =>
      'Start, resume, and review workout sessions.';

  @override
  String get workoutStatsTitle => 'Workout stats';

  @override
  String get workoutNoCompletedSessionsSubtitle => 'No completed sessions yet.';

  @override
  String workoutLatestSessionSubtitle(String sessionName) {
    return 'Latest: $sessionName';
  }

  @override
  String get workoutHistoryTitle => 'Workout history';

  @override
  String get workoutEmptyHistoryTitle => 'No completed workouts yet';

  @override
  String get workoutEmptyHistoryMessage =>
      'Start a training plan to build your workout history.';

  @override
  String get workoutChoosePlanTitle => 'Choose a training plan';

  @override
  String get workoutStartWorkoutSubtitle =>
      'Choose a training plan and begin tracking sets.';

  @override
  String get workoutDeleteDialogTitle => 'Delete workout?';

  @override
  String workoutDeleteDialogMessage(String sessionName, String date) {
    return 'Delete $sessionName from $date?';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get workoutOpenActiveTooltip => 'Open active workout';

  @override
  String get workoutActiveLabel => 'Active workout';

  @override
  String workoutElapsedLabel(String duration) {
    return 'Elapsed $duration';
  }

  @override
  String workoutExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get workoutCompletedMetricLabel => 'Completed';

  @override
  String workoutSessionCountSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sessions',
      one: 'session',
    );
    return '$_temp0';
  }

  @override
  String get workoutTotalTimeMetricLabel => 'Total time';

  @override
  String get workoutLatestMetricLabel => 'Latest';

  @override
  String workoutOpenCompletedTooltip(String sessionName) {
    return 'Open completed $sessionName';
  }

  @override
  String workoutDeleteCompletedTooltip(String sessionName) {
    return 'Delete completed $sessionName';
  }

  @override
  String get workoutSessionTitle => 'Workout session';

  @override
  String get workoutSessionCockpitLabel => 'Session cockpit';

  @override
  String get workoutExerciseQueueTitle => 'Exercise queue';

  @override
  String get workoutExerciseQueueSubtitle =>
      'Open an exercise to log sets and compare history.';

  @override
  String workoutOpenExerciseTooltip(String exerciseName) {
    return 'Open $exerciseName';
  }

  @override
  String workoutOpenExerciseEntryTooltip(String exerciseName, int entryNumber) {
    return 'Open $exerciseName entry $entryNumber';
  }

  @override
  String get workoutFinishAction => 'Finish workout';

  @override
  String get workoutCompletedTitle => 'Completed workout';

  @override
  String get workoutExerciseTitle => 'Workout exercise';

  @override
  String get workoutExerciseSubtitle =>
      'Log sets and reuse recent performance.';

  @override
  String get workoutExercisesTitle => 'Exercises';

  @override
  String workoutDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String workoutDurationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String workoutEntryLabel(int entryNumber) {
    return 'Entry $entryNumber';
  }

  @override
  String workoutSetLabel(int setNumber) {
    return 'Set $setNumber';
  }

  @override
  String get workoutNoSetsLogged => 'No sets logged';

  @override
  String get workoutTargetPrefix => 'Target:';

  @override
  String get workoutSetsLabel => 'sets';

  @override
  String get workoutRepsLabel => 'reps';

  @override
  String workoutSetCountLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets logged',
      one: '1 set logged',
    );
    return '$_temp0';
  }

  @override
  String get librarySubtitle =>
      'Manage reusable plans, exercises, foods, and dishes.';

  @override
  String get libraryTrainingSection => 'Training';

  @override
  String get libraryFoodsSection => 'Foods';

  @override
  String libraryEditItem(String itemName) {
    return 'Edit $itemName';
  }

  @override
  String libraryDeleteItem(String itemName) {
    return 'Delete $itemName';
  }

  @override
  String get libraryServingSuffix => 'serving';

  @override
  String libraryCaloriesPerServingLabel(String calories) {
    return '$calories kcal per serving';
  }

  @override
  String libraryExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get libraryMusclesEmpty => 'Muscles: -';

  @override
  String get formCancelAction => 'Cancel';

  @override
  String get workoutRepsFieldLabel => 'Reps';

  @override
  String get workoutWeightFieldLabel => 'Weight';

  @override
  String get workoutTimeFieldLabel => 'Time';

  @override
  String get workoutLogSetAction => 'Log set';

  @override
  String get workoutLoggedSetsTitle => 'Logged sets';

  @override
  String get workoutNoLoggedSetsYet => 'No logged sets yet';

  @override
  String workoutUseSetTooltip(int setNumber) {
    return 'Use Set $setNumber';
  }

  @override
  String get workoutPreviousResultsTitle => 'Previous results';

  @override
  String get workoutNoPreviousResults =>
      'No previous results for this exercise';

  @override
  String workoutPreviousSetLabel(int entryNumber, int setNumber) {
    return 'Entry $entryNumber • Set $setNumber';
  }

  @override
  String workoutUsePreviousSetTooltip(int setNumber, String sessionName) {
    return 'Use previous Set $setNumber from $sessionName';
  }

  @override
  String workoutUsePreviousEntrySetTooltip(
    int entryNumber,
    int setNumber,
    String sessionName,
  ) {
    return 'Use previous Entry $entryNumber Set $setNumber from $sessionName';
  }

  @override
  String get trainingsTitle => 'Trainings';

  @override
  String get trainingPlansSegment => 'Plans';

  @override
  String get trainingExercisesSegment => 'Exercises';

  @override
  String get trainingPlansTitle => 'Training plans';

  @override
  String get trainingAddPlanAction => 'Add training plan';

  @override
  String get trainingAddExerciseAction => 'Add exercise';

  @override
  String get trainingNoPlansTitle => 'No training plans yet';

  @override
  String get trainingNoPlansMessage =>
      'Create a training plan to organize exercises.';

  @override
  String get trainingNoExercisesTitle => 'No exercises yet';

  @override
  String get trainingNoExercisesMessage =>
      'Create an exercise to use it in training plans.';

  @override
  String trainingDeletePlanTitle(String planName) {
    return 'Delete $planName?';
  }

  @override
  String get trainingDeletePlanMessage => 'This removes the training plan.';

  @override
  String trainingDeleteExerciseTitle(String exerciseName) {
    return 'Delete $exerciseName?';
  }

  @override
  String get trainingDeleteExerciseMessage => 'This removes the exercise.';

  @override
  String get trainingCouldNotDelete => 'Could not delete.';

  @override
  String get exerciseDialogAddTitle => 'Add exercise';

  @override
  String get exerciseDialogEditTitle => 'Edit exercise';

  @override
  String get exerciseDialogSubtitle =>
      'Define instructions and muscle focus for workout plans.';

  @override
  String get exerciseSaveAction => 'Save exercise';

  @override
  String get exerciseProfileSectionTitle => 'Exercise profile';

  @override
  String get exerciseNameFieldLabel => 'Exercise name';

  @override
  String get exerciseDescriptionFieldLabel => 'Exercise description';

  @override
  String get exerciseInstructionFieldLabel => 'Exercise instruction';

  @override
  String get exerciseMuscleFocusTitle => 'Muscle focus';

  @override
  String get exerciseMuscleFocusSubtitle =>
      'Choose every area this exercise primarily trains.';

  @override
  String get exerciseSelectMuscleGroups => 'Select muscle groups';

  @override
  String get exerciseDetailsValidation =>
      'Enter a name, description, instruction, and muscle groups.';

  @override
  String get exerciseNameValidation => 'Enter a valid exercise name.';

  @override
  String get exerciseCouldNotSave => 'Could not save exercise.';

  @override
  String get trainingPlanDialogTitle => 'Training plan';

  @override
  String get trainingPlanEditDialogTitle => 'Edit training';

  @override
  String get trainingPlanDialogSubtitle =>
      'Assemble a reusable sequence for workout sessions.';

  @override
  String get trainingSaveAction => 'Save training';

  @override
  String get trainingBasicsSectionTitle => 'Training basics';

  @override
  String get trainingNameFieldLabel => 'Training name';

  @override
  String get trainingDescriptionFieldLabel => 'Training description';

  @override
  String get trainingExerciseSequenceTitle => 'Exercise sequence';

  @override
  String get trainingExerciseSequenceSubtitle =>
      'Add targets in the order you want to train.';

  @override
  String get trainingNoExercisesAdded => 'No exercises added yet';

  @override
  String trainingRemoveExerciseTooltip(String exerciseName) {
    return 'Remove $exerciseName';
  }

  @override
  String trainingTargetUnitLabel(String unit) {
    return 'Unit: $unit';
  }

  @override
  String get trainingSetsSummaryLabel => 'sets';

  @override
  String get trainingRepsSummaryLabel => 'reps';

  @override
  String get trainingWeightSummaryLabel => 'weight';

  @override
  String get trainingTimeSummaryLabel => 'time';

  @override
  String get trainingPlanValidation =>
      'Enter a training name and add at least one exercise.';

  @override
  String get trainingCouldNotSave => 'Could not save training.';

  @override
  String get trainingTargetDialogTitle => 'Add exercise';

  @override
  String get trainingTargetDialogEditTitle => 'Edit exercise';

  @override
  String get trainingTargetSectionTitle => 'Target prescription';

  @override
  String get trainingTargetSectionSubtitle =>
      'Set expected volume, load, duration, and unit.';

  @override
  String get trainingExpectedSetsFieldLabel => 'Expected sets';

  @override
  String get trainingExpectedRepsFieldLabel => 'Expected reps';

  @override
  String get trainingExpectedWeightFieldLabel => 'Expected weight';

  @override
  String get trainingExpectedTimeFieldLabel => 'Expected time';

  @override
  String get trainingUnitFieldLabel => 'Unit';

  @override
  String get trainingTargetValidation =>
      'Enter valid exercise targets and a unit.';

  @override
  String get foodScreenTitle => 'Food';

  @override
  String get foodSetTitle => 'Food set';

  @override
  String get foodAddItemAction => 'Add food or dish';

  @override
  String get foodEmptyTitle => 'No foods or dishes yet';

  @override
  String get foodEmptyMessage =>
      'Use Add food or dish to build your reusable catalog.';

  @override
  String foodDeleteItemTitle(String itemName) {
    return 'Delete $itemName?';
  }

  @override
  String get foodDeleteItemMessage =>
      'This removes the item from the food set.';

  @override
  String get foodItemChoiceLabel => 'Food item';

  @override
  String get dishChoiceLabel => 'Dish';

  @override
  String get foodFormTitle => 'Food item';

  @override
  String get foodFormEditTitle => 'Edit food';

  @override
  String get foodFormSubtitle =>
      'Define reusable food data for faster meal logging.';

  @override
  String get foodSaveAction => 'Save food';

  @override
  String get foodBasicsSectionTitle => 'Food basics';

  @override
  String get foodBasicsSectionSubtitle =>
      'Name this item and define the serving anchor.';

  @override
  String get foodNameFieldLabel => 'Name';

  @override
  String get foodDescriptionFieldLabel => 'Description';

  @override
  String get foodServingSizeGramsFieldLabel => 'Serving size grams';

  @override
  String get foodNutritionFactsTitle => 'Nutrition facts';

  @override
  String get foodNutritionFactsSubtitle =>
      'Enter values using the selected nutrition basis.';

  @override
  String get foodNutritionPer100g => 'Per 100g';

  @override
  String get foodNutritionPerServing => 'Per serving';

  @override
  String get foodValidation => 'Enter a name and valid nutrition values.';

  @override
  String get foodCouldNotSave => 'Could not save food.';

  @override
  String get dishFormTitle => 'Dish';

  @override
  String get dishFormEditTitle => 'Edit dish';

  @override
  String get dishFormSubtitle =>
      'Combine foods and dishes into a reusable recipe.';

  @override
  String get dishSaveAction => 'Save dish';

  @override
  String get dishBasicsSectionTitle => 'Dish basics';

  @override
  String get dishBasicsSectionSubtitle =>
      'Name this recipe and define one serving.';

  @override
  String get dishNameFieldLabel => 'Dish name';

  @override
  String get dishDescriptionFieldLabel => 'Dish description';

  @override
  String get dishServingSizeGramsFieldLabel => 'Dish serving size grams';

  @override
  String get dishComponentsSectionTitle => 'Components';

  @override
  String get dishComponentsSectionSubtitle =>
      'Add ingredients to calculate serving nutrition.';

  @override
  String get dishAddComponentAction => 'Add component';

  @override
  String get dishNoComponentsTitle => 'No components yet';

  @override
  String get dishNoComponentsMessage =>
      'Add foods or dishes to calculate this recipe.';

  @override
  String dishEditComponentTooltip(String itemName) {
    return 'Edit $itemName component';
  }

  @override
  String dishRemoveComponentTooltip(String itemName) {
    return 'Remove $itemName component';
  }

  @override
  String get dishComponentAddTitle => 'Add component';

  @override
  String get dishComponentEditTitle => 'Edit component';

  @override
  String get dishComponentAmountTitle => 'Component amount';

  @override
  String get dishComponentGramsFieldLabel => 'Component grams';

  @override
  String get dishCatalogItemSectionTitle => 'Catalog item';

  @override
  String get dishSaveComponentAction => 'Save component';

  @override
  String get dishValidation => 'Enter dish details and at least one component.';

  @override
  String get dishCouldNotSave => 'Could not save dish.';

  @override
  String get dishComponentValidation => 'Choose an item and enter valid grams.';
}
