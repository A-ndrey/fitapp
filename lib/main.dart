import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'models/app_preferences.dart';
import 'screens/library_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/more_screen.dart';
import 'screens/today_screen.dart';
import 'screens/workout_screen.dart';
import 'state/app_store.dart';
import 'ui/core/layout/app_breakpoints.dart';
import 'ui/core/theme/app_theme.dart';

void main() {
  runApp(const FitApp());
}

class FitApp extends StatefulWidget {
  const FitApp({super.key, this.store});

  final AppStore? store;

  @override
  State<FitApp> createState() => _FitAppState();
}

class _FitAppState extends State<FitApp> {
  late final AppStore _store;
  late final bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? AppStore();
  }

  @override
  void dispose() {
    if (_ownsStore) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: _themeModeFor(_store.appearancePreference),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: FitHome(store: _store),
        );
      },
    );
  }
}

ThemeMode _themeModeFor(AppearancePreference preference) {
  return switch (preference) {
    AppearancePreference.system => ThemeMode.system,
    AppearancePreference.light => ThemeMode.light,
    AppearancePreference.dark => ThemeMode.dark,
  };
}

class FitHome extends StatefulWidget {
  const FitHome({super.key, required this.store});

  final AppStore store;

  @override
  State<FitHome> createState() => _FitHomeState();
}

class _FitHomeState extends State<FitHome> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _isWorkoutTabCurrent = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isWorkoutTabCurrent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = <_AppDestination>[
      _AppDestination(
        label: l10n?.destinationToday ?? 'Today',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
        screen: TodayScreen(
          store: widget.store,
          onOpenTrain: () => _selectDestination(1),
          onOpenNutrition: () => _selectDestination(2),
          onOpenLibrary: () => _selectDestination(3),
        ),
      ),
      _AppDestination(
        label: l10n?.destinationTrain ?? 'Train',
        icon: Icons.timer_outlined,
        selectedIcon: Icons.timer,
        screen: _WorkoutTabNavigator(
          store: widget.store,
          isCurrentTabListenable: _isWorkoutTabCurrent,
        ),
      ),
      _AppDestination(
        label: l10n?.destinationNutrition ?? 'Nutrition',
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        screen: MealScreen(store: widget.store),
      ),
      _AppDestination(
        label: l10n?.destinationLibrary ?? 'Library',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        screen: LibraryScreen(store: widget.store),
      ),
      _AppDestination(
        label: l10n?.destinationMore ?? 'More',
        icon: Icons.more_horiz,
        selectedIcon: Icons.more_horiz,
        screen: MoreScreen(store: widget.store),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = IndexedStack(
          index: _selectedIndex,
          children: [
            for (final destination in destinations) destination.screen,
          ],
        );

        if (constraints.maxWidth < AppBreakpoints.mediumMin) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                    tooltip: destination.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  extended: constraints.maxWidth >= AppBreakpoints.largeMin,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.icon),
                        ),
                        selectedIcon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.selectedIcon),
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    _isWorkoutTabCurrent.value = index == 1;
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

class _WorkoutTabNavigator extends StatelessWidget {
  const _WorkoutTabNavigator({
    required this.store,
    required this.isCurrentTabListenable,
  });

  final AppStore store;
  final ValueListenable<bool> isCurrentTabListenable;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (context) {
            return WorkoutScreen(
              store: store,
              isCurrentTabListenable: isCurrentTabListenable,
            );
          },
        );
      },
    );
  }
}
