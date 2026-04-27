import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
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

        return AdaptivePage(
          children: [
            const SectionHeader(
              title: 'More',
              subtitle: 'Tune units, appearance, and sync preferences.',
            ),
            Text(
              'Sync',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SettingsStatusCard(
              title: 'Sync status',
              message: store.isLoggedIn
                  ? 'Sync status: signed in. Firebase sync is still a placeholder.'
                  : 'Sync status: signed out. Firebase sync is still a placeholder.',
              actionLabel: store.isLoggedIn ? 'Logout' : 'Login',
              onPressed: store.isLoggedIn ? store.logOut : store.logIn,
            ),
            const SizedBox(height: 20),
            Text(
              'Units',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  PreferenceChipCard<WorkoutWeightUnit>(
                    title: 'Workout weight',
                    subtitle: 'Weights shown during training sessions.',
                    value: preferences.workoutWeightUnit,
                    options: const [
                      PreferenceChipOption(
                        value: WorkoutWeightUnit.kilograms,
                        label: 'Kilograms',
                      ),
                      PreferenceChipOption(
                        value: WorkoutWeightUnit.pounds,
                        label: 'Pounds',
                      ),
                    ],
                    onChanged: store.setWorkoutWeightUnit,
                  ),
                  PreferenceChipCard<DishWeightUnit>(
                    title: 'Dish weight',
                    subtitle: 'Food and recipe serving measurements.',
                    value: preferences.dishWeightUnit,
                    options: const [
                      PreferenceChipOption(
                        value: DishWeightUnit.grams,
                        label: 'Grams',
                      ),
                      PreferenceChipOption(
                        value: DishWeightUnit.ounces,
                        label: 'Ounces',
                      ),
                    ],
                    onChanged: store.setDishWeightUnit,
                  ),
                  PreferenceChipCard<HeightUnit>(
                    title: 'Height',
                    value: preferences.heightUnit,
                    options: const [
                      PreferenceChipOption(
                        value: HeightUnit.centimeters,
                        label: 'Centimeters',
                      ),
                      PreferenceChipOption(
                        value: HeightUnit.inches,
                        label: 'Inches',
                      ),
                    ],
                    onChanged: store.setHeightUnit,
                  ),
                  PreferenceChipCard<DistanceUnit>(
                    title: 'Distance',
                    value: preferences.distanceUnit,
                    options: const [
                      PreferenceChipOption(
                        value: DistanceUnit.kilometers,
                        label: 'Kilometers',
                      ),
                      PreferenceChipOption(
                        value: DistanceUnit.miles,
                        label: 'Miles',
                      ),
                    ],
                    onChanged: store.setDistanceUnit,
                  ),
                  PreferenceChipCard<LanguagePreference>(
                    title: 'Language',
                    subtitle: 'App language',
                    value: preferences.language,
                    options: const [
                      PreferenceChipOption(
                        value: LanguagePreference.english,
                        label: 'English',
                      ),
                    ],
                    onChanged: store.setLanguagePreference,
                  ),
                  PreferenceChipCard<AppearancePreference>(
                    title: 'Appearance',
                    subtitle: 'Theme',
                    value: preferences.appearance,
                    options: const [
                      PreferenceChipOption(
                        value: AppearancePreference.system,
                        label: 'System',
                      ),
                      PreferenceChipOption(
                        value: AppearancePreference.light,
                        label: 'Light',
                      ),
                      PreferenceChipOption(
                        value: AppearancePreference.dark,
                        label: 'Dark',
                      ),
                    ],
                    onChanged: store.setAppearancePreference,
                  ),
                ];

                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      for (final card in cards) ...[
                        card,
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: card,
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
