import 'package:flutter/material.dart';

import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/section_header.dart';
import 'food_screen.dart';
import 'trainings_screen.dart';

enum LibrarySection { training, foods }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibrarySection _selectedSection = LibrarySection.training;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: AdaptivePage(
        fillRemaining: IndexedStack(
          index: _selectedSection.index,
          children: [
            TrainingsScreen(store: widget.store, embedded: true),
            FoodScreen(store: widget.store, embedded: true),
          ],
        ),
        children: [
          const SectionHeader(
            title: 'Library',
            subtitle: 'Manage reusable plans, exercises, foods, and dishes.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<LibrarySection>(
              segments: const [
                ButtonSegment(
                  value: LibrarySection.training,
                  label: Text('Training'),
                  icon: Icon(Icons.fitness_center_outlined),
                ),
                ButtonSegment(
                  value: LibrarySection.foods,
                  label: Text('Foods'),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
              ],
              selected: {_selectedSection},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedSection = selection.first;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
