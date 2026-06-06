import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/ui/core/layout/app_breakpoints.dart';
import 'package:fitapp/ui/core/widgets/action_card.dart';

void main() {
  const rootDestinationLabels = [
    'Today',
    'Train',
    'Nutrition',
    'Library',
    'Settings',
  ];

  const destinationBodyText = {
    'Today': 'Daily progress',
    'Train': 'Workout stats',
    'Nutrition': 'Nutrition log',
    'Library': 'Training',
    'Settings': 'Account',
  };

  Future<void> pumpFitAppAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FitApp());
  }

  Future<void> tapRootDestination(WidgetTester tester, String label) async {
    final index = rootDestinationLabels.indexOf(label);
    if (index == -1) {
      throw ArgumentError.value(label, 'label', 'Unknown root destination');
    }

    if (tester.any(find.byType(NavigationBar))) {
      final destinationLabel = find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          )
          .last;
      await tester.tapAt(tester.getCenter(destinationLabel));
      await tester.pumpAndSettle();
      return;
    }

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    rail.onDestinationSelected?.call(index);
    await tester.pumpAndSettle();
  }

  Future<void> selectRootDestination(WidgetTester tester, String label) async {
    final index = rootDestinationLabels.indexOf(label);
    if (index == -1) {
      throw ArgumentError.value(label, 'label', 'Unknown root destination');
    }

    if (tester.any(find.byType(NavigationBar))) {
      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      navigationBar.onDestinationSelected?.call(index);
      await tester.pumpAndSettle();
      return;
    }
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    rail.onDestinationSelected?.call(index);
    await tester.pumpAndSettle();
  }

  Future<void> openActiveWorkoutSession(WidgetTester tester) async {
    await selectRootDestination(tester, 'Train');
    await tester.ensureVisible(find.text('Start workout'));
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest day'));
    await tester.pumpAndSettle();
  }

  Future<void> openLibraryRecipes(WidgetTester tester) async {
    await selectRootDestination(tester, 'Library');
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
  }

  testWidgets('compact root shell uses NavigationBar', (tester) async {
    await pumpFitAppAtSize(tester, const Size(390, 844));

    expect(find.text('Today'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('compact root shell keeps NavigationBar above bottom safe area', (
    tester,
  ) async {
    tester.view.padding = FakeViewPadding.zero;
    addTearDown(tester.view.resetPadding);

    await pumpFitAppAtSize(tester, const Size(390, 844));

    final safeArea = tester.widget<SafeArea>(
      find.ancestor(
        of: find.byType(NavigationBar),
        matching: find.byType(SafeArea),
      ),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(safeArea.minimum.bottom, 8);
  });

  testWidgets('medium root shell uses NavigationRail', (tester) async {
    await pumpFitAppAtSize(tester, const Size(700, 900));

    expect(find.text('Today'), findsWidgets);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('root shell stays stable across target redesign widths', (
    tester,
  ) async {
    const targetSizes = <Size>[
      Size(390, 844),
      Size(700, 900),
      Size(1024, 768),
      Size(1440, 900),
    ];

    for (final size in targetSizes) {
      await pumpFitAppAtSize(tester, size);

      expect(find.text('Today'), findsWidgets);
      expect(tester.takeException(), isNull);

      if (size.width < 600) {
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      } else {
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(find.byType(NavigationBar), findsNothing);
        expect(AppBreakpoints.largeMin, 1200);
        expect(rail.extended, size.width >= 1200);
      }
    }
  });

  testWidgets('root destinations stay stable across target redesign widths', (
    tester,
  ) async {
    const targetSizes = <Size>[
      Size(390, 844),
      Size(700, 900),
      Size(1024, 768),
      Size(1440, 900),
    ];

    for (final size in targetSizes) {
      await pumpFitAppAtSize(tester, size);

      for (final label in rootDestinationLabels) {
        await tapRootDestination(tester, label);
        expect(find.text(label), findsWidgets);
        expect(find.text(destinationBodyText[label]!), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
    're-tapping Train after navigating into workout session returns to workout root',
    (tester) async {
      await pumpFitAppAtSize(tester, const Size(390, 844));
      await openActiveWorkoutSession(tester);

      expect(find.text('Workout session'), findsOneWidget);
      expect(find.text('Finish workout'), findsOneWidget);

      await tapRootDestination(tester, 'Train');

      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('Start workout'), findsNothing);
      expect(find.text('Workout session'), findsNothing);
      expect(find.text('Exercise queue'), findsNothing);
      expect(find.text('Finish workout'), findsNothing);
    },
  );

  testWidgets(
    're-tapping Library after drilling into recipes returns to library root',
    (tester) async {
      await pumpFitAppAtSize(tester, const Size(390, 844));
      await openLibraryRecipes(tester);

      expect(find.text('Recipes'), findsWidgets);
      expect(find.byTooltip('Back'), findsOneWidget);

      await tapRootDestination(tester, 'Library');

      expect(find.widgetWithText(ActionCard, 'Plans'), findsOneWidget);
      expect(find.widgetWithText(ActionCard, 'Exercises'), findsOneWidget);
      expect(find.widgetWithText(ActionCard, 'Foods'), findsOneWidget);
      expect(find.widgetWithText(ActionCard, 'Recipes'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.text('Training'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    },
  );
}
