import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_preferences.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/app_screen_scaffold.dart';
import '../ui/core/widgets/section_header.dart';
import '../ui/settings/settings_cards.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final preferences = store.preferences;
        final l10n = AppLocalizations.of(context);

        return AppScreenScaffold(
          title: l10n?.destinationMore ?? 'Settings',
          body: AdaptivePage(
            children: [
              SectionHeader(
                title: l10n?.destinationMore ?? 'Settings',
                subtitle:
                    l10n?.moreSubtitle ??
                    'Tune units, appearance, and training-log preferences.',
              ),
              Text(
                l10n?.moreSyncTitle ?? 'Sync',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SettingsStatusCard(
                title: l10n?.moreSyncStatusTitle ?? 'Sync status',
                message: store.isLoggedIn
                    ? l10n?.moreSyncSignedInMessage ??
                          'Signed in. Sync is not available yet.'
                    : l10n?.moreSyncSignedOutMessage ??
                          'Signed out. Sync is not available yet.',
                actionLabel: store.isLoggedIn
                    ? l10n?.moreLogoutAction ?? 'Logout'
                    : l10n?.moreLoginAction ?? 'Login',
                onPressed: store.isLoggedIn ? store.logOut : store.logIn,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final unitsCards = [
                    PreferenceChipCard<WorkoutWeightUnit>(
                      title:
                          l10n?.settingsWorkoutWeightTitle ?? 'Workout weight',
                      subtitle:
                          l10n?.settingsWorkoutWeightSubtitle ??
                          'Weights shown during training sessions.',
                      value: preferences.workoutWeightUnit,
                      options: [
                        PreferenceChipOption(
                          value: WorkoutWeightUnit.kilograms,
                          label: l10n?.unitKilograms ?? 'Kilograms',
                        ),
                        PreferenceChipOption(
                          value: WorkoutWeightUnit.pounds,
                          label: l10n?.unitPounds ?? 'Pounds',
                        ),
                      ],
                      onChanged: store.setWorkoutWeightUnit,
                    ),
                    PreferenceChipCard<DishWeightUnit>(
                      title: l10n?.settingsDishWeightTitle ?? 'Dish weight',
                      subtitle:
                          l10n?.settingsDishWeightSubtitle ??
                          'Food and recipe serving measurements.',
                      value: preferences.dishWeightUnit,
                      options: [
                        PreferenceChipOption(
                          value: DishWeightUnit.grams,
                          label: l10n?.unitGrams ?? 'Grams',
                        ),
                        PreferenceChipOption(
                          value: DishWeightUnit.ounces,
                          label: l10n?.unitOunces ?? 'Ounces',
                        ),
                      ],
                      onChanged: store.setDishWeightUnit,
                    ),
                    PreferenceChipCard<HeightUnit>(
                      title: l10n?.settingsHeightTitle ?? 'Height',
                      value: preferences.heightUnit,
                      options: [
                        PreferenceChipOption(
                          value: HeightUnit.centimeters,
                          label: l10n?.unitCentimeters ?? 'Centimeters',
                        ),
                        PreferenceChipOption(
                          value: HeightUnit.inches,
                          label: l10n?.unitInches ?? 'Inches',
                        ),
                      ],
                      onChanged: store.setHeightUnit,
                    ),
                    PreferenceChipCard<DistanceUnit>(
                      title: l10n?.settingsDistanceTitle ?? 'Distance',
                      value: preferences.distanceUnit,
                      options: [
                        PreferenceChipOption(
                          value: DistanceUnit.kilometers,
                          label: l10n?.unitKilometers ?? 'Kilometers',
                        ),
                        PreferenceChipOption(
                          value: DistanceUnit.miles,
                          label: l10n?.unitMiles ?? 'Miles',
                        ),
                      ],
                      onChanged: store.setDistanceUnit,
                    ),
                  ];
                  final appCards = [
                    PreferenceChipCard<LanguagePreference>(
                      title: l10n?.settingsLanguageTitle ?? 'Language',
                      subtitle:
                          l10n?.settingsLanguageSubtitle ?? 'App language',
                      value: preferences.language,
                      options: [
                        PreferenceChipOption(
                          value: LanguagePreference.english,
                          label: l10n?.languageEnglish ?? 'English',
                        ),
                      ],
                      onChanged: store.setLanguagePreference,
                    ),
                    PreferenceChipCard<AppearancePreference>(
                      title: l10n?.settingsAppearanceTitle ?? 'Appearance',
                      subtitle: l10n?.settingsAppearanceSubtitle ?? 'Theme',
                      value: preferences.appearance,
                      options: [
                        PreferenceChipOption(
                          value: AppearancePreference.system,
                          label: l10n?.appearanceSystem ?? 'System',
                        ),
                        PreferenceChipOption(
                          value: AppearancePreference.light,
                          label: l10n?.appearanceLight ?? 'Light',
                        ),
                        PreferenceChipOption(
                          value: AppearancePreference.dark,
                          label: l10n?.appearanceDark ?? 'Dark',
                        ),
                      ],
                      onChanged: store.setAppearancePreference,
                    ),
                  ];

                  if (constraints.maxWidth < 720) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SettingsGroup(
                          title: l10n?.settingsUnitsTitle ?? 'Units',
                          children: unitsCards,
                        ),
                        const SizedBox(height: 20),
                        _SettingsGroup(
                          title: l10n?.settingsAppTitle ?? 'App',
                          children: appCards,
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsGroup(
                        title: l10n?.settingsUnitsTitle ?? 'Units',
                        columns: 2,
                        children: unitsCards,
                      ),
                      const SizedBox(height: 20),
                      _SettingsGroup(
                        title: l10n?.settingsAppTitle ?? 'App',
                        columns: 2,
                        children: appCards,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
    this.columns = 1,
  });

  final String title;
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = columns > 1 ? 12.0 : 0.0;
        final itemWidth = columns > 1
            ? (constraints.maxWidth - spacing) / columns
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: [
                for (final child in children)
                  SizedBox(width: itemWidth, child: child),
              ],
            ),
          ],
        );
      },
    );
  }
}
