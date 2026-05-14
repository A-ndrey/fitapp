import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/catalog_item.dart';
import '../../state/app_store.dart';

class CatalogItemSearchSheetResult {
  const CatalogItemSearchSheetResult.item(this.item) : createName = '';

  const CatalogItemSearchSheetResult.create(this.createName) : item = null;

  final CatalogItem? item;
  final String createName;
}

Future<CatalogItemSearchSheetResult?> showCatalogItemSearchSheet({
  required BuildContext context,
  required AppStore store,
  required String title,
  required String subtitle,
  required String searchFieldLabel,
  required List<CatalogItem> recentItems,
  required String recentLabel,
  required List<CatalogItem> frequentItems,
  required String frequentLabel,
  bool allowCreate = false,
  String Function(String query)? createActionLabelBuilder,
}) {
  return showModalBottomSheet<CatalogItemSearchSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _CatalogItemSearchSheet(
        store: store,
        title: title,
        subtitle: subtitle,
        searchFieldLabel: searchFieldLabel,
        recentItems: recentItems,
        recentLabel: recentLabel,
        frequentItems: frequentItems,
        frequentLabel: frequentLabel,
        allowCreate: allowCreate,
        createActionLabelBuilder: createActionLabelBuilder,
      );
    },
  );
}

class _CatalogItemSearchSheet extends StatefulWidget {
  const _CatalogItemSearchSheet({
    required this.store,
    required this.title,
    required this.subtitle,
    required this.searchFieldLabel,
    required this.recentItems,
    required this.recentLabel,
    required this.frequentItems,
    required this.frequentLabel,
    required this.allowCreate,
    this.createActionLabelBuilder,
  });

  final AppStore store;
  final String title;
  final String subtitle;
  final String searchFieldLabel;
  final List<CatalogItem> recentItems;
  final String recentLabel;
  final List<CatalogItem> frequentItems;
  final String frequentLabel;
  final bool allowCreate;
  final String Function(String query)? createActionLabelBuilder;

  @override
  State<_CatalogItemSearchSheet> createState() => _CatalogItemSearchSheetState();
}

class _CatalogItemSearchSheetState extends State<_CatalogItemSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final results = widget.store.searchItems(query);
    final hasExactMatch = _hasExactNameMatch(results, query);
    final showCreateAction =
        widget.allowCreate && query.isNotEmpty && !hasExactMatch;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(labelText: widget.searchFieldLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (query.isEmpty) ...[
                      if (widget.recentItems.isNotEmpty) ...[
                        _SheetLabel(title: widget.recentLabel),
                        const SizedBox(height: 8),
                        _QuickPickWrap(
                          items: widget.recentItems,
                          onTap: (item) {
                            Navigator.of(
                              context,
                            ).pop(CatalogItemSearchSheetResult.item(item));
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.frequentItems.isNotEmpty) ...[
                        _SheetLabel(title: widget.frequentLabel),
                        const SizedBox(height: 8),
                        _QuickPickWrap(
                          items: widget.frequentItems,
                          onTap: (item) {
                            Navigator.of(
                              context,
                            ).pop(CatalogItemSearchSheetResult.item(item));
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length + (showCreateAction ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (showCreateAction && index == 0) {
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: Text(
                              widget.createActionLabelBuilder?.call(query) ??
                                  'Create "$query"',
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pop(CatalogItemSearchSheetResult.create(query));
                            },
                          );
                        }
                        final resultIndex = showCreateAction ? index - 1 : index;
                        final item = results[resultIndex];
                        return _CatalogItemSearchResultTile(
                          item: item,
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pop(CatalogItemSearchSheetResult.item(item));
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasExactNameMatch(List<CatalogItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    for (final item in items) {
      if (item.name.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _QuickPickWrap extends StatelessWidget {
  const _QuickPickWrap({required this.items, required this.onTap});

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ActionChip(label: Text(item.name), onPressed: () => onTap(item)),
      ],
    );
  }
}

class _CatalogItemSearchResultTile extends StatelessWidget {
  const _CatalogItemSearchResultTile({
    required this.item,
    required this.onTap,
  });

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(item.name),
      subtitle: Text(
        item.isFood
            ? l10n?.catalogSubtypeFood ?? 'food'
            : l10n?.catalogSubtypeDish ?? 'recipe',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
