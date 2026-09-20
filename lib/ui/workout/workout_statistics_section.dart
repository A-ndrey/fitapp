import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import '../../models/exercise.dart';
import '../../models/workout_statistics.dart';
import '../core/layout/responsive_layout.dart';
import '../core/widgets/section_header.dart';
import 'workout_overview_cards.dart';

class WorkoutStatisticsSection extends StatelessWidget {
  const WorkoutStatisticsSection({
    super.key,
    required this.period,
    required this.stats,
    required this.isCurrentPeriod,
    required this.onTypeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
  });

  final WorkoutPeriod period;
  final WorkoutPeriodStats stats;
  final bool isCurrentPeriod;
  final ValueChanged<WorkoutPeriodType> onTypeChanged;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final dates = MaterialLocalizations.of(context);
    final periodLabel = period.type == WorkoutPeriodType.month
        ? dates.formatMonthYear(period.start)
        : '${dates.formatShortDate(period.start)} – '
              '${dates.formatShortDate(period.lastDay)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final selector = SegmentedButton<WorkoutPeriodType>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
              segments: [
                ButtonSegment(
                  value: WorkoutPeriodType.week,
                  label: Text(l10n.workoutPeriodWeek),
                ),
                ButtonSegment(
                  value: WorkoutPeriodType.month,
                  label: Text(l10n.workoutPeriodMonth),
                ),
              ],
              selected: {period.type},
              onSelectionChanged: (value) => onTypeChanged(value.single),
            );
            final title = SectionHeader(title: l10n.workoutStatsTitle);
            final control = Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: selector,
            );
            if (constraints.maxWidth /
                    MediaQuery.textScalerOf(context).scale(1) <
                280) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: control,
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 12),
                control,
              ],
            );
          },
        ),
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: l10n.workoutPeriodPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                periodLabel,
                key: const ValueKey('workout-period-label'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: l10n.workoutPeriodNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (!isCurrentPeriod)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onCurrent,
              child: Text(l10n.workoutPeriodCurrent),
            ),
          ),
        const SizedBox(height: 8),
        WorkoutStatsGrid(
          completedCount: stats.completedCount,
          totalDuration: stats.totalDuration,
          setCount: stats.setCount,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        if (stats.completedCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.workoutPeriodEmpty, textAlign: TextAlign.center),
          )
        else
          _MuscleBalanceCard(stats: stats, l10n: l10n),
      ],
    );
  }
}

class _MuscleBalanceCard extends StatelessWidget {
  const _MuscleBalanceCard({required this.stats, required this.l10n});

  final WorkoutPeriodStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = [
      l10n.workoutMuscleChest,
      l10n.workoutMuscleBack,
      l10n.workoutMuscleShoulders,
      l10n.workoutMuscleArms,
      l10n.workoutMuscleCore,
      l10n.workoutMuscleGlutes,
      l10n.workoutMuscleLegs,
    ];
    final values = MuscleRegion.values
        .map((r) => stats.regionSets[r]!)
        .toList();
    final otherGroups = [MuscleGroup.cardio, MuscleGroup.fullBody];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.workoutBalanceTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.workoutBalanceDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _BalanceHelpButton(l10n: l10n),
              ],
            ),
            if (stats.setCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.workoutBalanceNoSets),
              )
            else ...[
              const SizedBox(height: 12),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context);
                      final indexedLabels =
                          constraints.maxWidth / scale.scale(1) < 230;
                      return Column(
                        children: [
                          Semantics(
                            label:
                                '${l10n.workoutBalanceTitle}. '
                                '${[for (var i = 0; i < labels.length; i++) '${labels[i]}: ${values[i]}'].join(', ')}. '
                                '${l10n.workoutRadarScale(stats.radarMaximum)}',
                            child: SizedBox(
                              height: constraints.maxWidth + scale.scale(24),
                              width: constraints.maxWidth,
                              child: CustomPaint(
                                key: const ValueKey('workout-muscle-radar'),
                                painter: _RadarPainter(
                                  values: values,
                                  labels: labels,
                                  indexedLabels: indexedLabels,
                                  maximum: stats.radarMaximum,
                                  color: theme.colorScheme.primary,
                                  gridColor: theme.colorScheme.outlineVariant,
                                  textStyle: theme.textTheme.labelMedium!
                                      .copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                  textScaler: scale,
                                  textDirection: Directionality.of(context),
                                ),
                              ),
                            ),
                          ),
                          if (indexedLabels)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ResponsiveWrap(
                                maxItemExtent: 240,
                                children: [
                                  for (var i = 0; i < labels.length; i++)
                                    _GroupCount(
                                      label: '${i + 1}. ${labels[i]}',
                                      count: values[i],
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Text(
                l10n.workoutRadarScale(stats.radarMaximum),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium,
              ),
              if (values.every((value) => value == 0)) ...[
                const SizedBox(height: 8),
                Text(l10n.workoutBalanceNoMuscles),
              ],
              const SizedBox(height: 12),
              ExpansionTile(
                key: const PageStorageKey('workout-muscle-group-details'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  l10n.workoutGroupDetails,
                  style: theme.textTheme.titleSmall,
                ),
                children: [
                  ResponsiveWrap(
                    maxItemExtent: 320,
                    children: [
                      for (final group in MuscleGroup.values)
                        if (!otherGroups.contains(group))
                          _GroupCount(
                            label: _groupLabel(group, l10n),
                            count: stats.groupSets[group]!,
                          ),
                    ],
                  ),
                ],
              ),
              if (stats.unknownGroupSets > 0 ||
                  otherGroups.any((group) => stats.groupSets[group]! > 0)) ...[
                const Divider(height: 32),
                Text(
                  l10n.workoutOtherGroups,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ResponsiveWrap(
                  maxItemExtent: 320,
                  children: [
                    for (final group in otherGroups)
                      if (stats.groupSets[group]! > 0)
                        _GroupCount(
                          label: _groupLabel(group, l10n),
                          count: stats.groupSets[group]!,
                        ),
                    if (stats.unknownGroupSets > 0)
                      _GroupCount(
                        label: l10n.workoutUnknownGroup,
                        count: stats.unknownGroupSets,
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceHelpButton extends StatefulWidget {
  const _BalanceHelpButton({required this.l10n});
  final AppLocalizations l10n;

  @override
  State<_BalanceHelpButton> createState() => _BalanceHelpButtonState();
}

class _BalanceHelpButtonState extends State<_BalanceHelpButton> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) => Tooltip(
    key: _tooltipKey,
    message: widget.l10n.workoutBalanceCountingNote,
    excludeFromSemantics: true,
    constraints: const BoxConstraints(maxWidth: 300),
    padding: const EdgeInsets.all(12),
    showDuration: const Duration(seconds: 12),
    child: IconButton(
      onPressed: () => _tooltipKey.currentState?.ensureTooltipVisible(),
      iconSize: 18,
      icon: Icon(
        Icons.help_outline,
        semanticLabel: widget.l10n.workoutBalanceHelp,
      ),
    ),
  );
}

class _GroupCount extends StatelessWidget {
  const _GroupCount({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Text('$count', style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

String _groupLabel(MuscleGroup group, AppLocalizations l10n) => switch (group) {
  MuscleGroup.chest => l10n.workoutMuscleChest,
  MuscleGroup.back => l10n.workoutMuscleBack,
  MuscleGroup.shoulders => l10n.workoutMuscleShoulders,
  MuscleGroup.biceps => l10n.workoutMuscleBiceps,
  MuscleGroup.triceps => l10n.workoutMuscleTriceps,
  MuscleGroup.forearms => l10n.workoutMuscleForearms,
  MuscleGroup.core => l10n.workoutMuscleCore,
  MuscleGroup.glutes => l10n.workoutMuscleGlutes,
  MuscleGroup.legs => l10n.workoutMuscleLegs,
  MuscleGroup.quads => l10n.workoutMuscleQuads,
  MuscleGroup.hamstrings => l10n.workoutMuscleHamstrings,
  MuscleGroup.calves => l10n.workoutMuscleCalves,
  MuscleGroup.cardio => l10n.workoutMuscleCardio,
  MuscleGroup.fullBody => l10n.workoutMuscleFullBody,
};

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.indexedLabels,
    required this.maximum,
    required this.color,
    required this.gridColor,
    required this.textStyle,
    required this.textScaler,
    required this.textDirection,
  });

  final List<int> values;
  final List<String> labels;
  final bool indexedLabels;
  final int maximum;
  final Color color;
  final Color gridColor;
  final TextStyle textStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * .28;
    Offset point(int index, double fraction) {
      final angle = -math.pi / 2 + 2 * math.pi * index / values.length;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * radius * fraction;
    }

    Path polygon(double Function(int) fraction) => Path()
      ..addPolygon([
        for (var i = 0; i < values.length; i++) point(i, fraction(i)),
      ], true);
    final grid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke;
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawPath(polygon((_) => ring / 4), grid);
    }
    for (var i = 0; i < values.length; i++) {
      canvas.drawLine(center, point(i, 1), grid);
    }
    final area = polygon((i) => values[i] / maximum);
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: .18));
    canvas.drawPath(
      area,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(
        point(i, values[i] / maximum),
        3,
        Paint()..color = color,
      );
      final anchor = point(i, 1.32);
      final text = TextPainter(
        text: TextSpan(
          text: indexedLabels ? '${i + 1}' : '${labels[i]}\n${values[i]}',
          style: textStyle,
        ),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: size.width * .27);
      final x = (anchor.dx - text.width / 2).clamp(
        0.0,
        size.width - text.width,
      );
      final y = (anchor.dy - text.height / 2).clamp(
        0.0,
        size.height - text.height,
      );
      text.paint(canvas, Offset(x, y));
      text.dispose();
    }
    // Numeric ring labels make the shared absolute scale explicit.
    for (var ring = 0; ring <= 4; ring++) {
      if (indexedLabels && ring.isOdd) continue;
      final text = TextPainter(
        text: TextSpan(
          text: '${maximum * ring ~/ 4}',
          style: textStyle.copyWith(fontSize: 10),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      text.paint(canvas, center + Offset(4, -radius * ring / 4));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      !listEquals(values, oldDelegate.values) ||
      !listEquals(labels, oldDelegate.labels) ||
      indexedLabels != oldDelegate.indexedLabels ||
      maximum != oldDelegate.maximum ||
      color != oldDelegate.color ||
      gridColor != oldDelegate.gridColor ||
      textStyle != oldDelegate.textStyle ||
      textScaler != oldDelegate.textScaler ||
      textDirection != oldDelegate.textDirection;
}
