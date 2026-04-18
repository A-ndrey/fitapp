import 'package:flutter/material.dart';

import 'screens/food_screen.dart';
import 'screens/meal_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      MealScreen(store: widget.store),
      FoodScreen(store: widget.store),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
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
