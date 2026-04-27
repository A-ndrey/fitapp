import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/ui/core/layout/app_breakpoints.dart';

void main() {
  const rootDestinationLabels = [
    'Today',
    'Train',
    'Nutrition',
    'Library',
    'More',
  ];

  const destinationBodyText = {
    'Today': 'Ready state',
    'Train': 'Training cockpit',
    'Nutrition': 'Nutrition cockpit',
    'Library': 'Training plans',
    'More': 'Sync',
  };

  Future<void> pumpFitAppAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FitApp());
  }

  Future<void> tapRootDestination(WidgetTester tester, String label) async {
    if (tester.any(find.byType(NavigationBar))) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            )
            .last,
      );
      await tester.pumpAndSettle();
      return;
    }

    final index = rootDestinationLabels.indexOf(label);
    if (index == -1) {
      throw ArgumentError.value(label, 'label', 'Unknown root destination');
    }
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    rail.onDestinationSelected?.call(index);
    await tester.pumpAndSettle();
  }

  testWidgets('compact root shell uses NavigationBar', (tester) async {
    await pumpFitAppAtSize(tester, const Size(390, 844));

    expect(find.text('Today'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
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
        expect(find.text(destinationBodyText[label]!), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
