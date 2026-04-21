import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/food_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/trainings_screen.dart';
import 'screens/workout_screen.dart';
import 'state/app_store.dart';

void main() {
  runApp(const FitApp());
}

class FitApp extends StatefulWidget {
  const FitApp({super.key});

  @override
  State<FitApp> createState() => _FitAppState();
}

class _FitAppState extends State<FitApp> {
  final AppStore _store = AppStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: FitHome(store: _store),
    );
  }
}

class FitHome extends StatefulWidget {
  const FitHome({super.key, required this.store});

  final AppStore store;

  @override
  State<FitHome> createState() => _FitHomeState();
}

class _FitHomeState extends State<FitHome> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _isWorkoutTabCurrent = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _isWorkoutTabCurrent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _WorkoutTabNavigator(
        store: widget.store,
        isCurrentTabListenable: _isWorkoutTabCurrent,
      ),
      TrainingsScreen(store: widget.store),
      MealScreen(store: widget.store),
      FoodScreen(store: widget.store),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _isWorkoutTabCurrent.value = index == 0;
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Trainings',
          ),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Meal'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Food',
          ),
        ],
      ),
    );
  }
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
