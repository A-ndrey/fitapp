import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title used by the host platform.
  ///
  /// In en, this message translates to:
  /// **'FitApp'**
  String get appTitle;

  /// Root navigation destination for the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get destinationToday;

  /// Root navigation destination for workouts.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get destinationTrain;

  /// Root navigation destination for meal logging and nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get destinationNutrition;

  /// Root navigation destination for reusable app content.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get destinationLibrary;

  /// Root navigation destination for settings and preferences.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get destinationMore;

  /// Today screen header when no workout is active.
  ///
  /// In en, this message translates to:
  /// **'Ready state'**
  String get todayReadyState;

  /// Today screen header when a workout is active.
  ///
  /// In en, this message translates to:
  /// **'In session'**
  String get todayInSession;

  /// Metric label for completed workout count.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts'**
  String get todayCompletedWorkouts;

  /// Metric suffix for completed workout count.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get todaySessionsSuffix;

  /// Metric suffix for active workout duration.
  ///
  /// In en, this message translates to:
  /// **'elapsed'**
  String get todayElapsedSuffix;

  /// Semantic duration label for durations of at least one hour.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}} {minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String durationHoursMinutesSemantic(int hours, int minutes);

  /// Semantic duration label for durations below one hour.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}} {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String durationMinutesSecondsSemantic(int minutes, int seconds);

  /// Semantic duration label for durations below one minute.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String durationSecondsSemantic(int seconds);

  /// Today screen nutrition summary section title.
  ///
  /// In en, this message translates to:
  /// **'Daily fuel'**
  String get todayDailyFuelTitle;

  /// Today screen nutrition summary section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Macros logged today'**
  String get todayDailyFuelSubtitle;

  /// Today screen quick action section title.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get todayQuickActionsTitle;

  /// Today screen action to start a workout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get todayStartWorkoutAction;

  /// Today screen action to return to an active workout.
  ///
  /// In en, this message translates to:
  /// **'Open workout'**
  String get todayOpenWorkoutAction;

  /// Subtitle for the Today start workout action.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan and begin training'**
  String get todayStartWorkoutSubtitle;

  /// Subtitle for the Today open workout action.
  ///
  /// In en, this message translates to:
  /// **'Return to the active session'**
  String get todayOpenWorkoutSubtitle;

  /// Accessibility hint for Today actions that open the Train tab.
  ///
  /// In en, this message translates to:
  /// **'Opens Train tab'**
  String get todayOpenTrainHint;

  /// Today screen action to open nutrition logging.
  ///
  /// In en, this message translates to:
  /// **'Log meal'**
  String get todayLogMealAction;

  /// Subtitle for the Today log meal action.
  ///
  /// In en, this message translates to:
  /// **'Add calories and macros for today'**
  String get todayLogMealSubtitle;

  /// Accessibility hint for Today action that opens Nutrition.
  ///
  /// In en, this message translates to:
  /// **'Opens Nutrition tab'**
  String get todayOpenNutritionHint;

  /// Today screen action to open the library.
  ///
  /// In en, this message translates to:
  /// **'Manage library'**
  String get todayManageLibraryAction;

  /// Subtitle for the Today manage library action.
  ///
  /// In en, this message translates to:
  /// **'Update foods, dishes, exercises, and plans'**
  String get todayManageLibrarySubtitle;

  /// Accessibility hint for Today action that opens Library.
  ///
  /// In en, this message translates to:
  /// **'Opens Library tab'**
  String get todayOpenLibraryHint;

  /// Nutrition metric label for calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionCalories;

  /// Nutrition metric label for protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// Nutrition metric label for fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// Nutrition metric label for carbohydrates.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// Semantic unit label for kcal.
  ///
  /// In en, this message translates to:
  /// **'kilocalories'**
  String get nutritionKilocaloriesSemantic;

  /// Semantic unit label for gram-based nutrition metrics.
  ///
  /// In en, this message translates to:
  /// **'grams'**
  String get nutritionGramsSemantic;

  /// Visible abbreviated unit for kilocalories in compact nutrition lines.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get nutritionKilocalorieUnit;

  /// Visible abbreviated unit for grams in compact nutrition lines.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get nutritionGramUnit;

  /// Inline lowercase protein label used in compact nutrition lines.
  ///
  /// In en, this message translates to:
  /// **'protein'**
  String get nutritionProteinInlineLabel;

  /// Inline lowercase fat label used in compact nutrition lines.
  ///
  /// In en, this message translates to:
  /// **'fat'**
  String get nutritionFatInlineLabel;

  /// Inline lowercase carbs label used in compact nutrition lines.
  ///
  /// In en, this message translates to:
  /// **'carbs'**
  String get nutritionCarbsInlineLabel;

  /// Catalog subtype label for food items.
  ///
  /// In en, this message translates to:
  /// **'food'**
  String get catalogSubtypeFood;

  /// Catalog subtype label for dish items.
  ///
  /// In en, this message translates to:
  /// **'dish'**
  String get catalogSubtypeDish;

  /// Suffix shown after a logged meal quantity.
  ///
  /// In en, this message translates to:
  /// **'logged'**
  String get mealLoggedSuffix;

  /// Suffix shown after a meal quantity entered as servings.
  ///
  /// In en, this message translates to:
  /// **'servings'**
  String get mealServingsQuantitySuffix;

  /// Tooltip for removing a meal entry.
  ///
  /// In en, this message translates to:
  /// **'Remove meal entry'**
  String get mealRemoveEntryTooltip;

  /// Nutrition screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealTitle;

  /// Action label for adding a food or dish to the meal log.
  ///
  /// In en, this message translates to:
  /// **'Add meal item'**
  String get mealAddItemAction;

  /// Nutrition screen hero title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition cockpit'**
  String get mealCockpitTitle;

  /// Nutrition screen hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log food, review macros, and keep today visible.'**
  String get mealCockpitSubtitle;

  /// Nutrition screen daily totals section title.
  ///
  /// In en, this message translates to:
  /// **'Daily totals'**
  String get mealDailyTotalsTitle;

  /// Nutrition screen meal entries section title.
  ///
  /// In en, this message translates to:
  /// **'Meal entries'**
  String get mealEntriesTitle;

  /// Empty state title for meal entries.
  ///
  /// In en, this message translates to:
  /// **'No meal entries yet'**
  String get mealEmptyTitle;

  /// Empty state message for meal entries.
  ///
  /// In en, this message translates to:
  /// **'Use Add meal item to start today\'s log.'**
  String get mealEmptyMessage;

  /// Bottom sheet title for searching meal items.
  ///
  /// In en, this message translates to:
  /// **'Add meal item'**
  String get mealSearchSheetTitle;

  /// Bottom sheet helper text for meal item search.
  ///
  /// In en, this message translates to:
  /// **'Search your saved foods and dishes, or create a new food from your query.'**
  String get mealSearchSheetSubtitle;

  /// Search field label for foods and dishes.
  ///
  /// In en, this message translates to:
  /// **'Search foods and dishes'**
  String get mealSearchFieldLabel;

  /// Create action for a missing meal search item.
  ///
  /// In en, this message translates to:
  /// **'Create \"{query}\"'**
  String mealCreateItem(String query);

  /// Prompt in the log meal amount dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose how much you ate, then add it to today\'s meal log.'**
  String get mealAmountPrompt;

  /// Label for grams amount mode.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get mealGramsLabel;

  /// Label for servings amount mode.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get mealServingsLabel;

  /// Common cancel action label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Dialog action to add a selected item amount to the meal log.
  ///
  /// In en, this message translates to:
  /// **'Add to meal'**
  String get mealAddToMealAction;

  /// More screen header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune units, appearance, and sync preferences.'**
  String get moreSubtitle;

  /// More screen sync section title.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get moreSyncTitle;

  /// Title for sync status card.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get moreSyncStatusTitle;

  /// Sync status message when signed in.
  ///
  /// In en, this message translates to:
  /// **'Sync status: signed in. Firebase sync is still a placeholder.'**
  String get moreSyncSignedInMessage;

  /// Sync status message when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sync status: signed out. Firebase sync is still a placeholder.'**
  String get moreSyncSignedOutMessage;

  /// Login action label.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get moreLoginAction;

  /// Logout action label.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get moreLogoutAction;

  /// Settings units section title.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnitsTitle;

  /// Preference title for workout weight unit.
  ///
  /// In en, this message translates to:
  /// **'Workout weight'**
  String get settingsWorkoutWeightTitle;

  /// Preference subtitle for workout weight unit.
  ///
  /// In en, this message translates to:
  /// **'Weights shown during training sessions.'**
  String get settingsWorkoutWeightSubtitle;

  /// Preference title for dish weight unit.
  ///
  /// In en, this message translates to:
  /// **'Dish weight'**
  String get settingsDishWeightTitle;

  /// Preference subtitle for dish weight unit.
  ///
  /// In en, this message translates to:
  /// **'Food and recipe serving measurements.'**
  String get settingsDishWeightSubtitle;

  /// Preference title for height unit.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsHeightTitle;

  /// Preference title for distance unit.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get settingsDistanceTitle;

  /// Preference title for language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Preference subtitle for language.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageSubtitle;

  /// Preference title for app appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// Preference subtitle for app appearance.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceSubtitle;

  /// Kilograms unit label.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get unitKilograms;

  /// Pounds unit label.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get unitPounds;

  /// Grams unit label.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get unitGrams;

  /// Ounces unit label.
  ///
  /// In en, this message translates to:
  /// **'Ounces'**
  String get unitOunces;

  /// Centimeters unit label.
  ///
  /// In en, this message translates to:
  /// **'Centimeters'**
  String get unitCentimeters;

  /// Inches unit label.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get unitInches;

  /// Kilometers unit label.
  ///
  /// In en, this message translates to:
  /// **'Kilometers'**
  String get unitKilometers;

  /// Miles unit label.
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get unitMiles;

  /// English language option label.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// System appearance option label.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// Light appearance option label.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Dark appearance option label.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Workout tab app bar title.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTitle;

  /// Workout overview hero title.
  ///
  /// In en, this message translates to:
  /// **'Training cockpit'**
  String get workoutTrainingCockpitTitle;

  /// Workout overview hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start, resume, and review workout sessions.'**
  String get workoutTrainingCockpitSubtitle;

  /// Workout overview stats section title.
  ///
  /// In en, this message translates to:
  /// **'Workout stats'**
  String get workoutStatsTitle;

  /// Workout stats subtitle when there is no completed workout history.
  ///
  /// In en, this message translates to:
  /// **'No completed sessions yet.'**
  String get workoutNoCompletedSessionsSubtitle;

  /// Workout stats subtitle when there is a latest completed workout.
  ///
  /// In en, this message translates to:
  /// **'Latest: {sessionName}'**
  String workoutLatestSessionSubtitle(String sessionName);

  /// Workout history section title.
  ///
  /// In en, this message translates to:
  /// **'Workout history'**
  String get workoutHistoryTitle;

  /// Workout history empty state title.
  ///
  /// In en, this message translates to:
  /// **'No completed workouts yet'**
  String get workoutEmptyHistoryTitle;

  /// Workout history empty state message.
  ///
  /// In en, this message translates to:
  /// **'Start a training plan to build your workout history.'**
  String get workoutEmptyHistoryMessage;

  /// Bottom sheet title for choosing a training plan to start.
  ///
  /// In en, this message translates to:
  /// **'Choose a training plan'**
  String get workoutChoosePlanTitle;

  /// Workout overview start workout action subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a training plan and begin tracking sets.'**
  String get workoutStartWorkoutSubtitle;

  /// Confirmation dialog title for deleting a completed workout.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get workoutDeleteDialogTitle;

  /// Confirmation dialog message for deleting a completed workout.
  ///
  /// In en, this message translates to:
  /// **'Delete {sessionName} from {date}?'**
  String workoutDeleteDialogMessage(String sessionName, String date);

  /// Common delete action label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Tooltip for opening the active workout.
  ///
  /// In en, this message translates to:
  /// **'Open active workout'**
  String get workoutOpenActiveTooltip;

  /// Label for the currently active workout card.
  ///
  /// In en, this message translates to:
  /// **'Active workout'**
  String get workoutActiveLabel;

  /// Workout info pill label for elapsed duration.
  ///
  /// In en, this message translates to:
  /// **'Elapsed {duration}'**
  String workoutElapsedLabel(String duration);

  /// Workout info pill label for exercise count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String workoutExerciseCount(int count);

  /// Metric label for completed workouts.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get workoutCompletedMetricLabel;

  /// Metric suffix for completed workout sessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{session} other{sessions}}'**
  String workoutSessionCountSuffix(int count);

  /// Metric label for total workout time.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get workoutTotalTimeMetricLabel;

  /// Metric label for latest workout.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get workoutLatestMetricLabel;

  /// Tooltip for opening a completed workout.
  ///
  /// In en, this message translates to:
  /// **'Open completed {sessionName}'**
  String workoutOpenCompletedTooltip(String sessionName);

  /// Tooltip for deleting a completed workout.
  ///
  /// In en, this message translates to:
  /// **'Delete completed {sessionName}'**
  String workoutDeleteCompletedTooltip(String sessionName);

  /// Active workout session screen title.
  ///
  /// In en, this message translates to:
  /// **'Workout session'**
  String get workoutSessionTitle;

  /// Active workout session header label.
  ///
  /// In en, this message translates to:
  /// **'Session cockpit'**
  String get workoutSessionCockpitLabel;

  /// Active workout exercise queue section title.
  ///
  /// In en, this message translates to:
  /// **'Exercise queue'**
  String get workoutExerciseQueueTitle;

  /// Active workout exercise queue section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open an exercise to log sets and compare history.'**
  String get workoutExerciseQueueSubtitle;

  /// Tooltip for opening an exercise in an active workout.
  ///
  /// In en, this message translates to:
  /// **'Open {exerciseName}'**
  String workoutOpenExerciseTooltip(String exerciseName);

  /// Tooltip for opening a repeated exercise entry in an active workout.
  ///
  /// In en, this message translates to:
  /// **'Open {exerciseName} entry {entryNumber}'**
  String workoutOpenExerciseEntryTooltip(String exerciseName, int entryNumber);

  /// Action label for finishing the active workout.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinishAction;

  /// Completed workout screen title and summary label.
  ///
  /// In en, this message translates to:
  /// **'Completed workout'**
  String get workoutCompletedTitle;

  /// Active workout exercise screen title and header.
  ///
  /// In en, this message translates to:
  /// **'Workout exercise'**
  String get workoutExerciseTitle;

  /// Active workout exercise screen subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log sets and reuse recent performance.'**
  String get workoutExerciseSubtitle;

  /// Completed workout exercises section title.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get workoutExercisesTitle;

  /// Completed workout date info pill.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String workoutDateLabel(String date);

  /// Completed workout duration info pill.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String workoutDurationLabel(String duration);

  /// Repeated workout exercise entry label.
  ///
  /// In en, this message translates to:
  /// **'Entry {entryNumber}'**
  String workoutEntryLabel(int entryNumber);

  /// Workout set label.
  ///
  /// In en, this message translates to:
  /// **'Set {setNumber}'**
  String workoutSetLabel(int setNumber);

  /// Text shown when a workout exercise has no logged sets.
  ///
  /// In en, this message translates to:
  /// **'No sets logged'**
  String get workoutNoSetsLogged;

  /// Library screen header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage reusable plans, exercises, foods, and dishes.'**
  String get librarySubtitle;

  /// Library segment label for training content.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get libraryTrainingSection;

  /// Library segment label for foods and dishes.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get libraryFoodsSection;

  /// Tooltip for editing a catalog item.
  ///
  /// In en, this message translates to:
  /// **'Edit {itemName}'**
  String libraryEditItem(String itemName);

  /// Tooltip for deleting a catalog item.
  ///
  /// In en, this message translates to:
  /// **'Delete {itemName}'**
  String libraryDeleteItem(String itemName);

  /// Serving suffix used in catalog nutrition summaries.
  ///
  /// In en, this message translates to:
  /// **'serving'**
  String get libraryServingSuffix;

  /// Catalog calories per serving summary.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal per serving'**
  String libraryCaloriesPerServingLabel(String calories);

  /// Training plan exercise count label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String libraryExerciseCount(int count);

  /// Exercise muscle summary when no muscle groups are selected.
  ///
  /// In en, this message translates to:
  /// **'Muscles: -'**
  String get libraryMusclesEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
