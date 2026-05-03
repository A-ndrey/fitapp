import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_store.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/action_card.dart';
import '../ui/core/widgets/section_header.dart';
import 'food_screen.dart';
import 'trainings_screen.dart';

enum LibrarySection { training, foods }

enum TrainingLibraryTab { plans, exercises }

enum FoodLibraryTab { foods, recipes }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibrarySection? _selectedSection;
  TrainingLibraryTab? _selectedTrainingTab;
  FoodLibraryTab? _selectedFoodTab;

  bool get _inDetail =>
      _selectedTrainingTab != null || _selectedFoodTab != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Scaffold(
      appBar: AppBar(
        leading: _selectedSection == null
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(_appBarTitle(l10n)),
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
    if (_selectedSection == null) {
      return AdaptivePage(
        children: [
          SectionHeader(
            title: l10n?.destinationLibrary ?? 'Library',
            subtitle:
                l10n?.librarySubtitle ??
                'Manage plans, exercises, foods, and recipes.',
          ),
          ActionCard(
            title: 'Training library',
            subtitle: 'Browse plans and exercises.',
            icon: Icons.fitness_center_outlined,
            onTap: () {
              setState(() {
                _selectedSection = LibrarySection.training;
              });
            },
          ),
          const SizedBox(height: 12),
          ActionCard(
            title: 'Food library',
            subtitle: 'Browse foods and recipes.',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              setState(() {
                _selectedSection = LibrarySection.foods;
              });
            },
          ),
        ],
      );
    }

    if (_selectedSection == LibrarySection.training &&
        _selectedTrainingTab == null) {
      return AdaptivePage(
        children: [
          SectionHeader(
            title: 'Training library',
            subtitle: 'Choose which catalog you want to manage.',
          ),
          ActionCard(
            title: l10n?.trainingPlansSegment ?? 'Plans',
            subtitle: 'Manage reusable workout plans.',
            icon: Icons.assignment_outlined,
            onTap: () {
              setState(() {
                _selectedTrainingTab = TrainingLibraryTab.plans;
              });
            },
          ),
          const SizedBox(height: 12),
          ActionCard(
            title: l10n?.trainingExercisesSegment ?? 'Exercises',
            subtitle: 'Manage your exercise catalog.',
            icon: Icons.fitness_center_outlined,
            onTap: () {
              setState(() {
                _selectedTrainingTab = TrainingLibraryTab.exercises;
              });
            },
          ),
        ],
      );
    }

    if (_selectedSection == LibrarySection.foods && _selectedFoodTab == null) {
      return AdaptivePage(
        children: [
          SectionHeader(
            title: 'Food library',
            subtitle: 'Choose which catalog you want to manage.',
          ),
          ActionCard(
            title: 'Foods',
            subtitle: 'Manage individual foods.',
            icon: Icons.eco_outlined,
            onTap: () {
              setState(() {
                _selectedFoodTab = FoodLibraryTab.foods;
              });
            },
          ),
          const SizedBox(height: 12),
          ActionCard(
            title: 'Recipes',
            subtitle: 'Manage reusable recipes.',
            icon: Icons.ramen_dining_outlined,
            onTap: () {
              setState(() {
                _selectedFoodTab = FoodLibraryTab.recipes;
              });
            },
          ),
        ],
      );
    }

    return AdaptivePage(
      fillRemaining: _buildActiveContent(compact),
      children: [
        SectionHeader(title: _detailTitle(l10n), subtitle: _detailSubtitle()),
      ],
    );
  }

  Widget _buildActiveContent(bool compact) {
    if (_selectedSection == LibrarySection.training) {
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

  String _appBarTitle(AppLocalizations? l10n) {
    if (_selectedSection == null) {
      return l10n?.destinationLibrary ?? 'Library';
    }
    if (_selectedSection == LibrarySection.training) {
      return 'Training library';
    }
    return 'Food library';
  }

  String _detailTitle(AppLocalizations? l10n) {
    if (_selectedSection == LibrarySection.training) {
      return _selectedTrainingTab == TrainingLibraryTab.plans
          ? l10n?.trainingPlansTitle ?? 'Training plans'
          : l10n?.trainingExercisesSegment ?? 'Exercises';
    }
    return _selectedFoodTab == FoodLibraryTab.foods ? 'Foods' : 'Recipes';
  }

  String _detailSubtitle() {
    if (_selectedSection == LibrarySection.training) {
      return _selectedTrainingTab == TrainingLibraryTab.plans
          ? 'Build and edit reusable workout plans.'
          : 'Build and edit your exercise catalog.';
    }
    return _selectedFoodTab == FoodLibraryTab.foods
        ? 'Build and edit your saved foods.'
        : 'Build and edit your saved recipes.';
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
      _selectedSection = null;
    });
  }

  String _fabHeroTag() {
    return switch ((_selectedSection, _selectedTrainingTab, _selectedFoodTab)) {
      (LibrarySection.training, TrainingLibraryTab.plans, _) =>
        'library-add-plan-fab',
      (LibrarySection.training, TrainingLibraryTab.exercises, _) =>
        'library-add-exercise-fab',
      (LibrarySection.foods, _, FoodLibraryTab.foods) => 'library-add-food-fab',
      (LibrarySection.foods, _, FoodLibraryTab.recipes) =>
        'library-add-recipe-fab',
      _ => 'library-add-fab',
    };
  }

  String _fabLabel(AppLocalizations? l10n) {
    return switch ((_selectedSection, _selectedTrainingTab, _selectedFoodTab)) {
      (LibrarySection.training, TrainingLibraryTab.plans, _) =>
        l10n?.trainingAddPlanAction ?? 'Add training plan',
      (LibrarySection.training, TrainingLibraryTab.exercises, _) =>
        l10n?.trainingAddExerciseAction ?? 'Add exercise',
      (LibrarySection.foods, _, FoodLibraryTab.foods) => 'Add food',
      (LibrarySection.foods, _, FoodLibraryTab.recipes) => 'Add recipe',
      _ => 'Add',
    };
  }

  Future<void> _handleAdd(BuildContext context) async {
    switch ((_selectedSection, _selectedTrainingTab, _selectedFoodTab)) {
      case (LibrarySection.training, TrainingLibraryTab.plans, _):
        await openTrainingPlanForm(context, widget.store);
      case (LibrarySection.training, TrainingLibraryTab.exercises, _):
        await openExerciseForm(context, widget.store);
      case (LibrarySection.foods, _, FoodLibraryTab.foods):
        await openFoodFormScreen(context, widget.store);
      case (LibrarySection.foods, _, FoodLibraryTab.recipes):
        await openRecipeFormScreen(context, widget.store);
      case _:
        return;
    }
  }
}
