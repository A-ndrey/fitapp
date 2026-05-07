import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.title,
    required this.child,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.emphasis = DashboardPanelEmphasis.defaultSurface,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final DashboardPanelEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = switch (emphasis) {
      DashboardPanelEmphasis.defaultSurface => (
        background: colorScheme.surfaceContainerLow,
        border: AppTheme.surfaceBorderColor(colorScheme),
      ),
      DashboardPanelEmphasis.raisedSurface => (
        background: colorScheme.surfaceContainerHigh,
        border: AppTheme.surfaceBorderColor(colorScheme),
      ),
      DashboardPanelEmphasis.live => (
        background: colorScheme.surfaceContainerHigh,
        border: colorScheme.primaryContainer,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(
          AppTheme.standardSurfaceRadius(colorScheme.brightness),
        ),
        border: Border.all(color: colors.border),
        boxShadow: AppTheme.ambientShadow(colorScheme.brightness),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || trailing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Expanded(
                    child: Text(
                      eyebrow!.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                ...?switch (trailing) {
                  final trailingWidget? => <Widget>[trailingWidget],
                  null => null,
                },
              ],
            ),
          if (eyebrow != null || trailing != null) const SizedBox(height: 8),
          Text(title, style: theme.textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

enum DashboardPanelEmphasis { defaultSurface, raisedSurface, live }

class GoalProgressRow extends StatelessWidget {
  const GoalProgressRow({
    required this.label,
    required this.valueLabel,
    required this.targetLabel,
    required this.progress,
    super.key,
    this.statusLabel,
    this.leading,
    this.barColor,
  });

  final String label;
  final String valueLabel;
  final String targetLabel;
  final double progress;
  final String? statusLabel;
  final Widget? leading;
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;
        final statusChip = statusLabel == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: AppTheme.surfaceBorderColor(colorScheme),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        '$valueLabel / $targetLabel',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact && statusChip != null) ...[
                  const SizedBox(width: 8),
                  statusChip,
                ],
              ],
            ),
            if (compact && statusChip != null) ...[
              const SizedBox(height: 8),
              statusChip,
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 8,
                backgroundColor: AppTheme.progressTrackColor(colorScheme),
                color: barColor ?? colorScheme.primaryContainer,
              ),
            ),
          ],
        );
      },
    );
  }
}

class DashboardStatChip extends StatelessWidget {
  const DashboardStatChip({
    required this.label,
    super.key,
    this.icon,
    this.tone,
  });

  final String label;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = tone ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: AppTheme.surfaceBorderColor(colorScheme)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
