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
}
