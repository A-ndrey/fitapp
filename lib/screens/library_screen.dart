import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.destinationLibrary ?? 'Library')),
      body: AdaptivePage(
        fillRemaining: IndexedStack(
          index: _selectedSection.index,
          children: [
            TrainingsScreen(store: widget.store, embedded: true),
            FoodScreen(store: widget.store, embedded: true),
          ],
        ),
        children: [
          SectionHeader(
            title: l10n?.destinationLibrary ?? 'Library',
            subtitle:
                l10n?.librarySubtitle ??
                'Manage plans, exercises, foods, and recipes.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<LibrarySection>(
              segments: [
                ButtonSegment(
                  value: LibrarySection.training,
                  label: Text(l10n?.libraryTrainingSection ?? 'Training'),
                  icon: const Icon(Icons.fitness_center_outlined),
                ),
                ButtonSegment(
                  value: LibrarySection.foods,
                  label: Text(l10n?.libraryFoodsSection ?? 'Foods'),
                  icon: const Icon(Icons.inventory_2_outlined),
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
