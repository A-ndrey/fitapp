import 'dart:math' as math;

import 'package:flutter/material.dart';

double responsivePageHorizontalPadding(double maxWidth) {
  return (maxWidth * 0.04).clamp(16.0, 36.0).toDouble();
}

double responsivePageMaxWidth(double maxWidth, {double upperBound = 1280}) {
  if (maxWidth <= upperBound) {
    return maxWidth;
  }
  return upperBound;
}

/// Returns a child width that targets [maxItemExtent] while preserving
/// [minItemExtent] before adding another column.
double responsiveItemWidth({
  required double maxWidth,
  required double maxItemExtent,
  required double spacing,
  double minItemExtent = 220,
}) {
  if (maxWidth <= 0 || !maxWidth.isFinite) {
    return maxItemExtent;
  }

  final usableMinExtent = math.min(minItemExtent, maxItemExtent);
  final maxColumns = math.max(
    1,
    ((maxWidth + spacing) / (usableMinExtent + spacing)).floor(),
  );
  final columns = math.max(
    1,
    math.min(
      maxColumns,
      ((maxWidth + spacing) / (maxItemExtent + spacing)).ceil(),
    ),
  );
  return (maxWidth - spacing * (columns - 1)) / columns;
}

class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    required this.children,
    super.key,
    this.maxItemExtent = 280,
    this.minItemExtent = 220,
    this.spacing = 12,
    this.runSpacing,
  });

  final List<Widget> children;
  final double maxItemExtent;
  final double minItemExtent;
  final double spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = responsiveItemWidth(
          maxWidth: constraints.maxWidth,
          maxItemExtent: maxItemExtent,
          minItemExtent: minItemExtent,
          spacing: spacing,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
