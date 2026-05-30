import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/layout/responsive_layout.dart';
import '../ui/core/widgets/action_card.dart';
import 'food_screen.dart';
import 'trainings_screen.dart';

enum TrainingLibraryTab { plans, exercises }

enum FoodLibraryTab { foods, recipes }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  TrainingLibraryTab? _selectedTrainingTab;
  FoodLibraryTab? _selectedFoodTab;

  bool get _inDetail =>
      _selectedTrainingTab != null || _selectedFoodTab != null;

  void resetToRoot() {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTrainingTab = null;
      _selectedFoodTab = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      appBar: AppBar(
        leading: _inDetail
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(l10n?.destinationLibrary ?? 'Library'),
      ),
      floatingActionButton: compact && _inDetail
          ? FloatingActionButton(
              heroTag: _fabHeroTag(),
              tooltip: _fabLabel(l10n),
              onPressed: () => _handleAdd(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: _buildBody(context, l10n, compact),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    bool compact,
  ) {
    if (!_inDetail) {
      return AdaptivePage(
        children: [
          const _LibraryGroupLabel(title: 'Training'),
          ResponsiveWrap(
            maxItemExtent: 360,
            minItemExtent: 260,
            spacing: 12,
            children: [
              ActionCard(
                title: l10n?.trainingPlansSegment ?? 'Plans',
                icon: Icons.assignment_outlined,
                onTap: () => _openTrainingTab(TrainingLibraryTab.plans),
              ),
              ActionCard(
                title: l10n?.trainingExercisesSegment ?? 'Exercises',
                icon: Icons.fitness_center_outlined,
                onTap: () => _openTrainingTab(TrainingLibraryTab.exercises),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _LibraryGroupLabel(title: 'Food'),
          ResponsiveWrap(
            maxItemExtent: 360,
            minItemExtent: 260,
            spacing: 12,
            children: [
              ActionCard(
                title: 'Foods',
                icon: Icons.eco_outlined,
                onTap: () => _openFoodTab(FoodLibraryTab.foods),
              ),
              ActionCard(
                title: 'Recipes',
                icon: Icons.ramen_dining_outlined,
                onTap: () => _openFoodTab(FoodLibraryTab.recipes),
              ),
            ],
          ),
        ],
      );
    }

    return _buildActiveContent(compact);
  }

  Widget _buildActiveContent(bool compact) {
    if (_selectedTrainingTab != null) {
      return TrainingsScreen(
        store: widget.store,
        embedded: true,
        initialView: _selectedTrainingTab == TrainingLibraryTab.plans
            ? TrainingsCatalogView.plans
            : TrainingsCatalogView.exercises,
        showEmbeddedAction: !compact,
        showViewSwitcher: false,
      );
    }

    return FoodScreen(
      store: widget.store,
      embedded: true,
      view: _selectedFoodTab == FoodLibraryTab.foods
          ? FoodLibraryView.foods
          : FoodLibraryView.recipes,
      showEmbeddedAction: !compact,
    );
  }

  void _goBack() {
    setState(() {
      if (_selectedTrainingTab != null) {
        _selectedTrainingTab = null;
        return;
      }
      if (_selectedFoodTab != null) {
        _selectedFoodTab = null;
        return;
      }
    });
  }

  void _openTrainingTab(TrainingLibraryTab tab) {
    setState(() {
      _selectedTrainingTab = tab;
      _selectedFoodTab = null;
    });
  }

  void _openFoodTab(FoodLibraryTab tab) {
    setState(() {
      _selectedFoodTab = tab;
      _selectedTrainingTab = null;
    });
  }

  String _fabHeroTag() {
    return switch ((_selectedTrainingTab, _selectedFoodTab)) {
      (TrainingLibraryTab.plans, _) => 'library-add-plan-fab',
      (TrainingLibraryTab.exercises, _) => 'library-add-exercise-fab',
      (_, FoodLibraryTab.foods) => 'library-add-food-fab',
      (_, FoodLibraryTab.recipes) => 'library-add-recipe-fab',
      _ => 'library-add-fab',
    };
  }

  String _fabLabel(AppLocalizations? l10n) {
    return switch ((_selectedTrainingTab, _selectedFoodTab)) {
      (TrainingLibraryTab.plans, _) =>
        l10n?.trainingAddPlanAction ?? 'Add training plan',
      (TrainingLibraryTab.exercises, _) =>
        l10n?.trainingAddExerciseAction ?? 'Add exercise',
      (_, FoodLibraryTab.foods) => 'Add food',
      (_, FoodLibraryTab.recipes) => 'Add recipe',
      _ => 'Add',
    };
  }

  Future<void> _handleAdd(BuildContext context) async {
    switch ((_selectedTrainingTab, _selectedFoodTab)) {
      case (TrainingLibraryTab.plans, _):
        await openTrainingPlanForm(context, widget.store);
      case (TrainingLibraryTab.exercises, _):
        await openExerciseForm(context, widget.store);
      case (_, FoodLibraryTab.foods):
        await openFoodFormScreen(context, widget.store);
      case (_, FoodLibraryTab.recipes):
        await openRecipeFormScreen(context, widget.store);
      case _:
        return;
    }
  }
}

class _LibraryGroupLabel extends StatelessWidget {
  const _LibraryGroupLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
