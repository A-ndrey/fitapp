import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../state/app_store.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final preferences = store.preferences;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('More', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Sync',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.isLoggedIn
                          ? 'Signed in. Firebase sync is still a placeholder.'
                          : 'Signed out. Firebase sync is still a placeholder.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: store.isLoggedIn ? store.logOut : store.logIn,
                        child: Text(store.isLoggedIn ? 'Logout' : 'Login'),
                      ),
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: 'Units',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PreferenceField<WorkoutWeightUnit>(
                      label: 'Workout weight',
                      value: preferences.workoutWeightUnit,
                      options: const [
                        _PreferenceOption(
                          value: WorkoutWeightUnit.kilograms,
                          label: 'Kilograms',
                        ),
                        _PreferenceOption(
                          value: WorkoutWeightUnit.pounds,
                          label: 'Pounds',
                        ),
                      ],
                      onChanged: store.setWorkoutWeightUnit,
                    ),
                    const SizedBox(height: 16),
                    _PreferenceField<DishWeightUnit>(
                      label: 'Dish weight',
                      value: preferences.dishWeightUnit,
                      options: const [
                        _PreferenceOption(
                          value: DishWeightUnit.grams,
                          label: 'Grams',
                        ),
                        _PreferenceOption(
                          value: DishWeightUnit.ounces,
                          label: 'Ounces',
                        ),
                      ],
                      onChanged: store.setDishWeightUnit,
                    ),
                    const SizedBox(height: 16),
                    _PreferenceField<HeightUnit>(
                      label: 'Height',
                      value: preferences.heightUnit,
                      options: const [
                        _PreferenceOption(
                          value: HeightUnit.centimeters,
                          label: 'Centimeters',
                        ),
                        _PreferenceOption(
                          value: HeightUnit.inches,
                          label: 'Inches',
                        ),
                      ],
                      onChanged: store.setHeightUnit,
                    ),
                    const SizedBox(height: 16),
                    _PreferenceField<DistanceUnit>(
                      label: 'Distance',
                      value: preferences.distanceUnit,
                      options: const [
                        _PreferenceOption(
                          value: DistanceUnit.kilometers,
                          label: 'Kilometers',
                        ),
                        _PreferenceOption(
                          value: DistanceUnit.miles,
                          label: 'Miles',
                        ),
                      ],
                      onChanged: store.setDistanceUnit,
                    ),
                  ],
                ),
              ),
              _SectionCard(
                title: 'Language',
                child: _PreferenceField<LanguagePreference>(
                  label: 'App language',
                  value: preferences.language,
                  options: const [
                    _PreferenceOption(
                      value: LanguagePreference.english,
                      label: 'English',
                    ),
                  ],
                  onChanged: store.setLanguagePreference,
                ),
              ),
              _SectionCard(
                title: 'Appearance',
                child: _PreferenceField<AppearancePreference>(
                  label: 'Theme',
                  value: preferences.appearance,
                  options: const [
                    _PreferenceOption(
                      value: AppearancePreference.system,
                      label: 'System',
                    ),
                    _PreferenceOption(
                      value: AppearancePreference.light,
                      label: 'Light',
                    ),
                    _PreferenceOption(
                      value: AppearancePreference.dark,
                      label: 'Dark',
                    ),
                  ],
                  onChanged: store.setAppearancePreference,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PreferenceField<T> extends StatelessWidget {
  const _PreferenceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_PreferenceOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.label),
                selected: value == option.value,
                onSelected: (_) => onChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreferenceOption<T> {
  const _PreferenceOption({required this.value, required this.label});

  final T value;
  final String label;
}
