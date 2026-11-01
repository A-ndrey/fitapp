import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/core/widgets/form_shell.dart';
import 'barcode_input_screen.dart';

class FoodBarcodeSection extends StatelessWidget {
  const FoodBarcodeSection({
    super.key,
    required this.barcodes,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> barcodes;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSectionCard(
      title: l10n?.barcodeSectionTitle ?? 'Barcodes (optional)',
      subtitle:
          l10n?.barcodeSectionHint ??
          'Find this food quickly when logging a meal.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final code in barcodes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.barcode_reader),
              title: Text(code),
              trailing: IconButton(
                tooltip: l10n?.barcodeRemove ?? 'Remove barcode',
                onPressed: () => onRemove(code),
                icon: const Icon(Icons.close),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final value = await showBarcodeInput(context);
              if (!context.mounted || value == null) return;
              onAdd(value);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n?.barcodeAdd ?? 'Add barcode'),
          ),
        ],
      ),
    );
  }
}
