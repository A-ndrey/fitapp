import 'package:flutter/material.dart';

import '../ui/core/input/numeric_input_formatters.dart';
import '../ui/core/widgets/form_shell.dart';

class CatalogFormShell extends StatelessWidget {
  const CatalogFormShell({
    required this.title,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.children,
    required this.fullScreen,
    super.key,
    this.subtitle,
    this.maxDialogWidth = 560,
  });

  final String title;
  final String? subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final List<Widget> children;
  final bool fullScreen;
  final double maxDialogWidth;

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return FormShellPage(
        title: title,
        subtitle: subtitle,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        children: children,
      );
    }

    return FormShellDialog(
      title: title,
      subtitle: subtitle,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction,
      maxWidth: maxDialogWidth,
      children: children,
    );
  }
}

class CatalogBasicsSection extends StatelessWidget {
  const CatalogBasicsSection({
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.nameLabel,
    required this.descriptionLabel,
    required this.servingSizeLabel,
    required this.nameController,
    required this.descriptionController,
    required this.servingSizeController,
    super.key,
  });

  final String sectionTitle;
  final String sectionSubtitle;
  final String nameLabel;
  final String descriptionLabel;
  final String servingSizeLabel;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController servingSizeController;

  @override
  Widget build(BuildContext context) {
    return FormSectionCard(
      title: sectionTitle,
      subtitle: sectionSubtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: nameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: descriptionLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: servingSizeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: positiveDecimalInputFormatters,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: servingSizeLabel),
          ),
        ],
      ),
    );
  }
}
