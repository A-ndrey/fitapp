import 'package:flutter/material.dart';

class SettingsStatusCard extends StatelessWidget {
  const SettingsStatusCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.messageColor,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;
  final Color? messageColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: colorScheme.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: messageColor ?? colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceChipCard<T> extends StatelessWidget {
  const PreferenceChipCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final T value;
  final List<PreferenceChipOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option.label),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: value == option.value
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: colorScheme.surfaceContainerLow,
                    selectedColor: colorScheme.primaryContainer,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    selected: value == option.value,
                    onSelected: (_) => onChanged(option.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceChipOption<T> {
  const PreferenceChipOption({required this.value, required this.label});

  final T value;
  final String label;
}
