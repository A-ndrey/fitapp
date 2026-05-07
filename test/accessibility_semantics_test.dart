import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/ui/core/widgets/action_card.dart';
import 'package:fitapp/ui/core/widgets/metric_card.dart';

void main() {
  testWidgets('ActionCard exposes one button semantic with destination hint', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionCard(
            title: 'Start workout',
            subtitle: 'Choose a plan and begin training',
            semanticHint: 'Opens Train tab',
            icon: Icons.play_arrow,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(ActionCard)),
      matchesSemantics(
        label: 'Start workout. Choose a plan and begin training.',
        hint: 'Opens Train tab',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('MetricCard exposes a single expanded value label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'Calories',
            value: '120',
            suffix: 'kcal',
            icon: Icons.local_fire_department_outlined,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MetricCard)),
      matchesSemantics(label: 'Calories, 120 kilocalories'),
    );
    semantics.dispose();
  });

  testWidgets('MetricCard expands duration abbreviations in semantic value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'Active workout',
            value: '1h 02m',
            suffix: 'elapsed',
            icon: Icons.timer_outlined,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MetricCard)),
      matchesSemantics(label: 'Active workout, 1 hour 2 minutes elapsed'),
    );
    semantics.dispose();
  });

  testWidgets('MetricCard accepts localized semantic value and suffix', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'Protein',
            value: '7',
            suffix: 'g',
            semanticValue: 'seven',
            semanticSuffix: 'localized grams',
            icon: Icons.fitness_center_outlined,
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MetricCard)),
      matchesSemantics(label: 'Protein, seven localized grams'),
    );
    semantics.dispose();
  });

  testWidgets('ActionCard semantic label does not duplicate punctuation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionCard(
            title: 'Start workout',
            subtitle: 'Choose a training plan and begin tracking sets.',
            icon: Icons.play_arrow,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(ActionCard)),
      matchesSemantics(
        label: 'Start workout. Choose a training plan and begin tracking sets.',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('root destinations expose labels on compact and medium shells', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    for (final size in const [Size(390, 844), Size(700, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(FitApp(store: AppStore.empty()));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Today').last).label,
        contains('Today'),
      );
      expect(
        tester.getSemantics(find.text('Train').last).label,
        contains('Train'),
      );
      expect(
        tester.getSemantics(find.text('Nutrition').last).label,
        contains('Nutrition'),
      );
      expect(
        tester.getSemantics(find.text('Library').last).label,
        contains('Library'),
      );
      expect(
        tester.getSemantics(find.text('Settings').last).label,
        contains('Settings'),
      );
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    semantics.dispose();
  });
}
