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
  /// **'Ready to train'**
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
  /// **'Today\'s macros'**
  String get todayDailyFuelTitle;

  /// Today screen nutrition summary section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Logged intake'**
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
  /// **'Update plans, exercises, foods, and recipes'**
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
  /// **'recipe'**
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
  /// **'Nutrition'**
  String get mealTitle;

  /// Action label for adding a food or dish to the meal log.
  ///
  /// In en, this message translates to:
  /// **'Log food'**
  String get mealAddItemAction;

  /// Nutrition screen hero title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition log'**
  String get mealCockpitTitle;

  /// Nutrition screen hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track calories, protein, carbs, and fat.'**
  String get mealCockpitSubtitle;

  /// Nutrition screen daily totals section title.
  ///
  /// In en, this message translates to:
  /// **'Daily totals'**
  String get mealDailyTotalsTitle;

  /// Nutrition screen meal entries section title.
  ///
  /// In en, this message translates to:
  /// **'Logged meals'**
  String get mealEntriesTitle;

  /// Empty state title for meal entries.
  ///
  /// In en, this message translates to:
  /// **'No food logged yet'**
  String get mealEmptyTitle;

  /// Empty state message for meal entries.
  ///
  /// In en, this message translates to:
  /// **'Use Log food to start today\'s nutrition log.'**
  String get mealEmptyMessage;

  /// Bottom sheet title for searching meal items.
  ///
  /// In en, this message translates to:
  /// **'Log food'**
  String get mealSearchSheetTitle;

  /// Bottom sheet helper text for meal item search.
  ///
  /// In en, this message translates to:
  /// **'Search saved foods and recipes, or create a new food from your query.'**
  String get mealSearchSheetSubtitle;

  /// Search field label for foods and dishes.
  ///
  /// In en, this message translates to:
  /// **'Search foods and recipes'**
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
  /// **'Log food'**
  String get mealAddToMealAction;

  /// More screen header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tune units, appearance, and training-log preferences.'**
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
  /// **'Signed in. Sync is not available yet.'**
  String get moreSyncSignedInMessage;

  /// Sync status message when signed out.
  ///
  /// In en, this message translates to:
  /// **'Signed out. Sync is not available yet.'**
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

  /// Settings section title for app preferences.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppTitle;

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
  /// **'Training log'**
  String get workoutTrainingCockpitTitle;

  /// Workout overview hero subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start sessions, log sets, and review progress.'**
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
  /// **'Active session'**
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

  /// Prefix label for workout target summaries.
  ///
  /// In en, this message translates to:
  /// **'Target:'**
  String get workoutTargetPrefix;

  /// Compact visible hour unit used in workout duration labels.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get workoutHourUnit;

  /// Compact visible minute unit used in workout duration labels.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get workoutMinuteUnit;

  /// Label for workout set counts in compact target summaries.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get workoutSetsLabel;

  /// Label for workout repetition counts in compact set summaries.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get workoutRepsLabel;

  /// Label for number of workout sets logged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set logged} other{{count} sets logged}}'**
  String workoutSetCountLogged(int count);

  /// Library screen header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage plans, exercises, foods, and recipes.'**
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

  /// Shared cancel action label for custom form dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get formCancelAction;

  /// Workout set input field label for repetitions.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutRepsFieldLabel;

  /// Workout set input field label for weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get workoutWeightFieldLabel;

  /// Workout set input field label for time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get workoutTimeFieldLabel;

  /// Action label for logging a workout set.
  ///
  /// In en, this message translates to:
  /// **'Log set'**
  String get workoutLogSetAction;

  /// Workout logged sets section title.
  ///
  /// In en, this message translates to:
  /// **'Logged sets'**
  String get workoutLoggedSetsTitle;

  /// Empty state for active workout logged sets.
  ///
  /// In en, this message translates to:
  /// **'No logged sets yet'**
  String get workoutNoLoggedSetsYet;

  /// Tooltip for filling the workout set input from a logged set.
  ///
  /// In en, this message translates to:
  /// **'Use Set {setNumber}'**
  String workoutUseSetTooltip(int setNumber);

  /// Previous workout results section title.
  ///
  /// In en, this message translates to:
  /// **'Previous results'**
  String get workoutPreviousResultsTitle;

  /// Empty state for previous workout exercise results.
  ///
  /// In en, this message translates to:
  /// **'No previous results for this exercise'**
  String get workoutNoPreviousResults;

  /// Previous result set label when an exercise has repeated entries.
  ///
  /// In en, this message translates to:
  /// **'Entry {entryNumber} • Set {setNumber}'**
  String workoutPreviousSetLabel(int entryNumber, int setNumber);

  /// Tooltip for filling workout set input from previous workout history.
  ///
  /// In en, this message translates to:
  /// **'Use previous Set {setNumber} from {sessionName}'**
  String workoutUsePreviousSetTooltip(int setNumber, String sessionName);

  /// Tooltip for filling workout set input from previous workout history with repeated exercise entries.
  ///
  /// In en, this message translates to:
  /// **'Use previous Entry {entryNumber} Set {setNumber} from {sessionName}'**
  String workoutUsePreviousEntrySetTooltip(
    int entryNumber,
    int setNumber,
    String sessionName,
  );

  /// Standalone trainings screen title.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get trainingsTitle;

  /// Training screen segment label for plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get trainingPlansSegment;

  /// Training screen segment label for exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get trainingExercisesSegment;

  /// Training plans section title.
  ///
  /// In en, this message translates to:
  /// **'Training plans'**
  String get trainingPlansTitle;

  /// Action label for adding a training plan.
  ///
  /// In en, this message translates to:
  /// **'Add training plan'**
  String get trainingAddPlanAction;

  /// Action label for adding an exercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get trainingAddExerciseAction;

  /// Empty state title for training plans.
  ///
  /// In en, this message translates to:
  /// **'No training plans yet'**
  String get trainingNoPlansTitle;

  /// Empty state message for training plans.
  ///
  /// In en, this message translates to:
  /// **'Create a training plan to organize exercises.'**
  String get trainingNoPlansMessage;

  /// Empty state title for exercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get trainingNoExercisesTitle;

  /// Empty state message for exercises.
  ///
  /// In en, this message translates to:
  /// **'Create an exercise to use it in training plans.'**
  String get trainingNoExercisesMessage;

  /// Delete training plan confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete {planName}?'**
  String trainingDeletePlanTitle(String planName);

  /// Delete training plan confirmation message.
  ///
  /// In en, this message translates to:
  /// **'This removes the training plan.'**
  String get trainingDeletePlanMessage;

  /// Delete exercise confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete {exerciseName}?'**
  String trainingDeleteExerciseTitle(String exerciseName);

  /// Delete exercise confirmation message.
  ///
  /// In en, this message translates to:
  /// **'This removes the exercise.'**
  String get trainingDeleteExerciseMessage;

  /// Fallback delete error message for training content.
  ///
  /// In en, this message translates to:
  /// **'Could not delete.'**
  String get trainingCouldNotDelete;

  /// Add exercise dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get exerciseDialogAddTitle;

  /// Edit exercise dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get exerciseDialogEditTitle;

  /// Exercise dialog subtitle.
  ///
  /// In en, this message translates to:
  /// **'Define instructions and muscle focus for workout plans.'**
  String get exerciseDialogSubtitle;

  /// Save exercise action label.
  ///
  /// In en, this message translates to:
  /// **'Save exercise'**
  String get exerciseSaveAction;

  /// Exercise profile section title.
  ///
  /// In en, this message translates to:
  /// **'Exercise profile'**
  String get exerciseProfileSectionTitle;

  /// Exercise name field label.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get exerciseNameFieldLabel;

  /// Exercise description field label.
  ///
  /// In en, this message translates to:
  /// **'Exercise description'**
  String get exerciseDescriptionFieldLabel;

  /// Exercise instruction field label.
  ///
  /// In en, this message translates to:
  /// **'Exercise instruction'**
  String get exerciseInstructionFieldLabel;

  /// Muscle focus section title.
  ///
  /// In en, this message translates to:
  /// **'Muscle focus'**
  String get exerciseMuscleFocusTitle;

  /// Muscle focus section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose every area this exercise primarily trains.'**
  String get exerciseMuscleFocusSubtitle;

  /// Muscle group selector label.
  ///
  /// In en, this message translates to:
  /// **'Select muscle groups'**
  String get exerciseSelectMuscleGroups;

  /// Exercise validation error for missing required details.
  ///
  /// In en, this message translates to:
  /// **'Enter a name, description, instruction, and muscle groups.'**
  String get exerciseDetailsValidation;

  /// Exercise validation error for invalid name.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid exercise name.'**
  String get exerciseNameValidation;

  /// Fallback save error message for exercises.
  ///
  /// In en, this message translates to:
  /// **'Could not save exercise.'**
  String get exerciseCouldNotSave;

  /// Add training plan dialog title.
  ///
  /// In en, this message translates to:
  /// **'Training plan'**
  String get trainingPlanDialogTitle;

  /// Edit training plan dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit training'**
  String get trainingPlanEditDialogTitle;

  /// Training plan dialog subtitle.
  ///
  /// In en, this message translates to:
  /// **'Assemble a reusable sequence for workout sessions.'**
  String get trainingPlanDialogSubtitle;

  /// Save training plan action label.
  ///
  /// In en, this message translates to:
  /// **'Save training'**
  String get trainingSaveAction;

  /// Training plan basics section title.
  ///
  /// In en, this message translates to:
  /// **'Training basics'**
  String get trainingBasicsSectionTitle;

  /// Training name field label.
  ///
  /// In en, this message translates to:
  /// **'Training name'**
  String get trainingNameFieldLabel;

  /// Training description field label.
  ///
  /// In en, this message translates to:
  /// **'Training description'**
  String get trainingDescriptionFieldLabel;

  /// Training plan exercise sequence section title.
  ///
  /// In en, this message translates to:
  /// **'Exercise sequence'**
  String get trainingExerciseSequenceTitle;

  /// Training plan exercise sequence section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add targets in the order you want to train.'**
  String get trainingExerciseSequenceSubtitle;

  /// Empty state text for a training plan with no selected exercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises added yet'**
  String get trainingNoExercisesAdded;

  /// Tooltip for removing an exercise from a training plan.
  ///
  /// In en, this message translates to:
  /// **'Remove {exerciseName}'**
  String trainingRemoveExerciseTooltip(String exerciseName);

  /// Training target unit summary label.
  ///
  /// In en, this message translates to:
  /// **'Unit: {unit}'**
  String trainingTargetUnitLabel(String unit);

  /// Training target summary label for sets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get trainingSetsSummaryLabel;

  /// Training target summary label for repetitions.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get trainingRepsSummaryLabel;

  /// Training target summary label for weight.
  ///
  /// In en, this message translates to:
  /// **'weight'**
  String get trainingWeightSummaryLabel;

  /// Training target summary label for time.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get trainingTimeSummaryLabel;

  /// Training plan validation error for missing required details.
  ///
  /// In en, this message translates to:
  /// **'Enter a training name and add at least one exercise.'**
  String get trainingPlanValidation;

  /// Fallback save error message for training plans.
  ///
  /// In en, this message translates to:
  /// **'Could not save training.'**
  String get trainingCouldNotSave;

  /// Training exercise target dialog add title.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get trainingTargetDialogTitle;

  /// Training exercise target dialog edit title.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get trainingTargetDialogEditTitle;

  /// Training exercise target prescription section title.
  ///
  /// In en, this message translates to:
  /// **'Set targets'**
  String get trainingTargetSectionTitle;

  /// Training exercise target prescription section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set working volume, load, duration, and unit.'**
  String get trainingTargetSectionSubtitle;

  /// Working sets field label.
  ///
  /// In en, this message translates to:
  /// **'Working sets'**
  String get trainingExpectedSetsFieldLabel;

  /// Target reps field label.
  ///
  /// In en, this message translates to:
  /// **'Target reps'**
  String get trainingExpectedRepsFieldLabel;

  /// Target load field label.
  ///
  /// In en, this message translates to:
  /// **'Target load'**
  String get trainingExpectedWeightFieldLabel;

  /// Target duration field label.
  ///
  /// In en, this message translates to:
  /// **'Target duration'**
  String get trainingExpectedTimeFieldLabel;

  /// Training target unit field label.
  ///
  /// In en, this message translates to:
  /// **'Load or time unit'**
  String get trainingUnitFieldLabel;

  /// Training target validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter valid exercise targets and a unit.'**
  String get trainingTargetValidation;

  /// Standalone food screen title.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodScreenTitle;

  /// Food catalog section title.
  ///
  /// In en, this message translates to:
  /// **'Food library'**
  String get foodSetTitle;

  /// Action label for adding food or dish.
  ///
  /// In en, this message translates to:
  /// **'Add food or recipe'**
  String get foodAddItemAction;

  /// Empty state title for food catalog.
  ///
  /// In en, this message translates to:
  /// **'No foods or recipes yet'**
  String get foodEmptyTitle;

  /// Empty state message for food catalog.
  ///
  /// In en, this message translates to:
  /// **'Use Add food or recipe to build your reusable catalog.'**
  String get foodEmptyMessage;

  /// Delete food or dish confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete {itemName}?'**
  String foodDeleteItemTitle(String itemName);

  /// Delete food or dish confirmation message.
  ///
  /// In en, this message translates to:
  /// **'This removes the item from the food set.'**
  String get foodDeleteItemMessage;

  /// Bottom sheet choice label for creating a food item.
  ///
  /// In en, this message translates to:
  /// **'Food item'**
  String get foodItemChoiceLabel;

  /// Bottom sheet choice label for creating a dish.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get dishChoiceLabel;

  /// Food form title.
  ///
  /// In en, this message translates to:
  /// **'Food item'**
  String get foodFormTitle;

  /// Edit food form title.
  ///
  /// In en, this message translates to:
  /// **'Edit food'**
  String get foodFormEditTitle;

  /// Food form subtitle.
  ///
  /// In en, this message translates to:
  /// **'Define reusable food data for faster meal logging.'**
  String get foodFormSubtitle;

  /// Save food action label.
  ///
  /// In en, this message translates to:
  /// **'Save food'**
  String get foodSaveAction;

  /// Food basics section title.
  ///
  /// In en, this message translates to:
  /// **'Food basics'**
  String get foodBasicsSectionTitle;

  /// Food basics section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name this item and define the serving anchor.'**
  String get foodBasicsSectionSubtitle;

  /// Food name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get foodNameFieldLabel;

  /// Food description field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get foodDescriptionFieldLabel;

  /// Food serving size grams field label.
  ///
  /// In en, this message translates to:
  /// **'Serving size grams'**
  String get foodServingSizeGramsFieldLabel;

  /// Food nutrition facts section title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition facts'**
  String get foodNutritionFactsTitle;

  /// Food nutrition facts section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter values using the selected nutrition basis.'**
  String get foodNutritionFactsSubtitle;

  /// Nutrition basis label for per 100 grams.
  ///
  /// In en, this message translates to:
  /// **'Per 100g'**
  String get foodNutritionPer100g;

  /// Nutrition basis label for per serving.
  ///
  /// In en, this message translates to:
  /// **'Per serving'**
  String get foodNutritionPerServing;

  /// Food form validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter a name and valid nutrition values.'**
  String get foodValidation;

  /// Fallback save error for food form.
  ///
  /// In en, this message translates to:
  /// **'Could not save food.'**
  String get foodCouldNotSave;

  /// Dish form title.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get dishFormTitle;

  /// Edit dish form title.
  ///
  /// In en, this message translates to:
  /// **'Edit recipe'**
  String get dishFormEditTitle;

  /// Dish form subtitle.
  ///
  /// In en, this message translates to:
  /// **'Combine foods into a reusable recipe.'**
  String get dishFormSubtitle;

  /// Save dish action label.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get dishSaveAction;

  /// Dish basics section title.
  ///
  /// In en, this message translates to:
  /// **'Recipe basics'**
  String get dishBasicsSectionTitle;

  /// Dish basics section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name this recipe and define one serving.'**
  String get dishBasicsSectionSubtitle;

  /// Dish name field label.
  ///
  /// In en, this message translates to:
  /// **'Recipe name'**
  String get dishNameFieldLabel;

  /// Dish description field label.
  ///
  /// In en, this message translates to:
  /// **'Recipe description'**
  String get dishDescriptionFieldLabel;

  /// Dish serving size grams field label.
  ///
  /// In en, this message translates to:
  /// **'Recipe serving size grams'**
  String get dishServingSizeGramsFieldLabel;

  /// Dish components section title.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get dishComponentsSectionTitle;

  /// Dish components section subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to calculate serving nutrition.'**
  String get dishComponentsSectionSubtitle;

  /// Add dish component action label.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get dishAddComponentAction;

  /// Dish components empty state title.
  ///
  /// In en, this message translates to:
  /// **'No ingredients yet'**
  String get dishNoComponentsTitle;

  /// Dish components empty state message.
  ///
  /// In en, this message translates to:
  /// **'Add foods to calculate this recipe.'**
  String get dishNoComponentsMessage;

  /// Tooltip for editing a dish component.
  ///
  /// In en, this message translates to:
  /// **'Edit {itemName} ingredient'**
  String dishEditComponentTooltip(String itemName);

  /// Tooltip for removing a dish component.
  ///
  /// In en, this message translates to:
  /// **'Remove {itemName} ingredient'**
  String dishRemoveComponentTooltip(String itemName);

  /// Add dish component dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get dishComponentAddTitle;

  /// Edit dish component dialog title.
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get dishComponentEditTitle;

  /// Dish component amount section title.
  ///
  /// In en, this message translates to:
  /// **'Ingredient amount'**
  String get dishComponentAmountTitle;

  /// Dish component grams field label and semantic label.
  ///
  /// In en, this message translates to:
  /// **'Ingredient grams'**
  String get dishComponentGramsFieldLabel;

  /// Dish component catalog item selector title.
  ///
  /// In en, this message translates to:
  /// **'Catalog item'**
  String get dishCatalogItemSectionTitle;

  /// Save dish component action label.
  ///
  /// In en, this message translates to:
  /// **'Save ingredient'**
  String get dishSaveComponentAction;

  /// Dish form validation message.
  ///
  /// In en, this message translates to:
  /// **'Enter recipe details and at least one ingredient.'**
  String get dishValidation;

  /// Fallback save error for dish form.
  ///
  /// In en, this message translates to:
  /// **'Could not save recipe.'**
  String get dishCouldNotSave;

  /// Dish component validation message.
  ///
  /// In en, this message translates to:
  /// **'Choose an item and enter valid ingredient grams.'**
  String get dishComponentValidation;
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
