import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    super.key,
    this.suffix,
    this.semanticValue,
    this.semanticSuffix,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final String? suffix;
  final String? semanticValue;
  final String? semanticSuffix;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = color ?? colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final metricStyle = colorScheme.brightness == Brightness.light
        ? textTheme.displayLarge?.copyWith(
            fontFamily: 'Lexend',
            fontSize: 48,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          )
        : textTheme.displayMedium?.copyWith(
            fontFamily: 'Lexend',
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w500,
          );

    final expandedValue = semanticValue ?? _expandSemanticValue(value);
    final semanticLabel = suffix == null
        ? '$label, $expandedValue'
        : '$label, $expandedValue ${semanticSuffix ?? _expandSemanticUnit(suffix!)}';

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: accentColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metricStyle,
                          ),
                        ),
                        if (suffix != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                suffix!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _expandSemanticUnit(String unit) {
    return switch (unit) {
      'g' => 'grams',
      'kcal' => 'kilocalories',
      _ => unit,
    };
  }

  String _expandSemanticValue(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'\b(\d+)h\b'),
          (match) => _pluralUnit(match[1]!, 'hour'),
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+)m\b'),
          (match) => _pluralUnit(match[1]!, 'minute'),
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+)s\b'),
          (match) => _pluralUnit(match[1]!, 'second'),
        );
  }

  String _pluralUnit(String rawCount, String unit) {
    final count = int.parse(rawCount);
    final label = count == 1 ? unit : '${unit}s';
    return '$count $label';
  }
}
