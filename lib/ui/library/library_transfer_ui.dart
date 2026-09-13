import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/library_transfer.dart';
import '../../state/library_transfer/library_transfer_controller.dart';

enum _ExportDestination { clipboard, file }

enum _ImportSource { clipboard, file }

Future<void> showLibraryExportOptions(
  BuildContext context, {
  required LibraryTransferController controller,
  required LibraryCategory category,
  String? itemId,
  String? itemName,
}) async {
  late final String source;
  try {
    source = itemId == null
        ? controller.exportCategory(category)
        : controller.exportItem(category, itemId);
  } on Object catch (error) {
    _showMessage(context, 'Could not export: $error');
    return;
  }
  final destination = await showModalBottomSheet<_ExportDestination>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text(l10n?.libraryCopyJsonAction ?? 'Copy JSON'),
              subtitle: const Text(
                'Paste it directly into an AI conversation.',
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _ExportDestination.clipboard),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n?.librarySaveJsonAction ?? 'Save JSON file'),
              subtitle: const Text('Best for large libraries.'),
              onTap: () => Navigator.pop(sheetContext, _ExportDestination.file),
            ),
          ],
        ),
      );
    },
  );
  if (!context.mounted || destination == null) {
    return;
  }

  switch (destination) {
    case _ExportDestination.clipboard:
      await controller.copyJson(source);
      if (context.mounted && controller.error == null) {
        _showMessage(context, 'JSON copied to clipboard.');
      }
    case _ExportDestination.file:
      final baseName = itemName ?? category.name;
      await controller.saveJson(
        fileName: 'fitapp-${_fileSafe(baseName)}.json',
        contents: source,
      );
  }
  if (context.mounted) {
    final error = controller.error;
    if (error != null) {
      _showMessage(context, error);
      controller.clearError();
    }
  }
}

Future<bool> showLibraryImportOptions(
  BuildContext context, {
  required LibraryTransferController controller,
}) async {
  final sourceChoice = await showModalBottomSheet<_ImportSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_paste_outlined),
              title: Text(l10n?.libraryPasteJsonAction ?? 'Paste JSON'),
              subtitle: const Text(
                'Read a FitApp document from the clipboard.',
              ),
              onTap: () => Navigator.pop(sheetContext, _ImportSource.clipboard),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n?.libraryChooseJsonAction ?? 'Choose JSON file'),
              subtitle: const Text('Import a saved or generated library file.'),
              onTap: () => Navigator.pop(sheetContext, _ImportSource.file),
            ),
          ],
        ),
      );
    },
  );
  if (!context.mounted || sourceChoice == null) {
    return false;
  }

  final source = switch (sourceChoice) {
    _ImportSource.clipboard => await controller.readClipboard(),
    _ImportSource.file => await controller.pickJson(),
  };
  if (!context.mounted) {
    return false;
  }
  if (source == null) {
    if (controller.error case final error?) {
      _showMessage(context, error);
      controller.clearError();
    }
    return false;
  }

  late final LibraryImportPreview preview;
  try {
    preview = controller.preview(source);
  } on FormatException catch (error) {
    _showMessage(context, error.message.toString());
    return false;
  } on Object catch (error) {
    _showMessage(context, 'Could not read the import: $error');
    return false;
  }

  return await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (_) => LibraryImportPreviewPage(
            controller: controller,
            preview: preview,
          ),
        ),
      ) ??
      false;
}

class LibraryImportPreviewPage extends StatefulWidget {
  const LibraryImportPreviewPage({
    super.key,
    required this.controller,
    required this.preview,
  });

  final LibraryTransferController controller;
  final LibraryImportPreview preview;

  @override
  State<LibraryImportPreviewPage> createState() =>
      _LibraryImportPreviewPageState();
}

class _LibraryImportPreviewPageState extends State<LibraryImportPreviewPage> {
  late final Set<String> _selectedKeys;
  final Set<String> _copyKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.preview.entries
        .where((entry) => entry.canImport)
        .map((entry) => entry.key)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.libraryReviewImportTitle ??
              'Review import',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: _ImportSummary(preview: preview),
                    ),
                  ),
                  if (preview.entries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(
                                context,
                              )?.libraryEmptyImportMessage ??
                              'This file does not contain any items.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth < 600 ? 8 : 16,
                        0,
                        constraints.maxWidth < 600 ? 8 : 16,
                        96,
                      ),
                      sliver: SliverList.builder(
                        itemCount: preview.entries.length,
                        itemBuilder: (context, index) {
                          final entry = preview.entries[index];
                          return _ImportEntryCard(
                            entry: entry,
                            selected: _selectedKeys.contains(entry.key),
                            importAsCopy: _copyKeys.contains(entry.key),
                            onSelected: entry.canImport
                                ? (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedKeys.add(entry.key);
                                      } else {
                                        _selectedKeys.remove(entry.key);
                                      }
                                    });
                                  }
                                : null,
                            onCopyChanged: entry.canImportAsCopy
                                ? (copy) {
                                    setState(() {
                                      if (copy) {
                                        _copyKeys.add(entry.key);
                                      } else {
                                        _copyKeys.remove(entry.key);
                                      }
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('library-import-apply'),
                onPressed: _selectedKeys.isEmpty ? null : _apply,
                icon: const Icon(Icons.check),
                label: Text('Import ${_selectedKeys.length} items'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _apply() {
    final result = widget.controller.apply(
      widget.preview,
      selectedKeys: _selectedKeys,
      copyKeys: _copyKeys,
    );
    if (result.failures.isEmpty) {
      _showMessage(context, 'Imported ${result.imported} items.');
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _selectedKeys.removeAll(result.failures.keys);
    });
    _showMessage(
      context,
      'Imported ${result.imported}; ${result.failures.length} failed.',
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.preview});

  final LibraryImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.category.label,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.libraryReviewImportMessage ??
                  'Review every change before anything is saved.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  icon: Icons.add_circle_outline,
                  label: '${preview.createCount} new',
                ),
                _SummaryChip(
                  icon: Icons.update_outlined,
                  label: '${preview.updateCount} updates',
                ),
                _SummaryChip(
                  icon: Icons.error_outline,
                  label: '${preview.errorCount} errors',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _ImportEntryCard extends StatelessWidget {
  const _ImportEntryCard({
    required this.entry,
    required this.selected,
    required this.importAsCopy,
    required this.onSelected,
    required this.onCopyChanged,
  });

  final LibraryImportEntry entry;
  final bool selected;
  final bool importAsCopy;
  final ValueChanged<bool>? onSelected;
  final ValueChanged<bool>? onCopyChanged;

  @override
  Widget build(BuildContext context) {
    final status = switch (entry.action) {
      LibraryImportAction.create => 'Create',
      LibraryImportAction.update => importAsCopy ? 'Create copy' : 'Update',
      LibraryImportAction.copy => 'Create copy',
      LibraryImportAction.error => 'Cannot import',
    };
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          CheckboxListTile(
            key: ValueKey('library-import-entry-${entry.key}'),
            value: entry.canImport && selected,
            onChanged: onSelected == null
                ? null
                : (value) => onSelected!(value ?? false),
            secondary: Icon(
              entry.action == LibraryImportAction.error
                  ? Icons.error_outline
                  : entry.action == LibraryImportAction.update
                  ? Icons.update_outlined
                  : Icons.add_circle_outline,
              color: entry.action == LibraryImportAction.error
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
            title: Text(entry.name),
            subtitle: Text(
              entry.error != null
                  ? '$status · ${entry.error}'
                  : '$status${entry.missingReferences.isEmpty ? '' : ' · creates ${entry.missingReferences.length} missing references'}',
            ),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          if (onCopyChanged != null && selected)
            SwitchListTile(
              key: ValueKey('library-import-copy-${entry.key}'),
              value: importAsCopy,
              onChanged: onCopyChanged,
              secondary: const Icon(Icons.copy_all_outlined),
              title: Text(
                AppLocalizations.of(context)?.libraryImportAsCopyAction ??
                    'Import as copy',
              ),
              subtitle: Text(
                AppLocalizations.of(context)?.libraryImportAsCopyMessage ??
                    'Keep the current item unchanged.',
              ),
            ),
        ],
      ),
    );
  }
}

String _fileSafe(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  return normalized.replaceAll(RegExp(r'^-+|-+$'), '').isEmpty
      ? 'library'
      : normalized.replaceAll(RegExp(r'^-+|-+$'), '');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
