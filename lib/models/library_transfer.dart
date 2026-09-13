enum LibraryCategory {
  foods,
  recipes,
  exercises,
  trainingPlans;

  String get label => switch (this) {
    LibraryCategory.foods => 'Foods',
    LibraryCategory.recipes => 'Recipes',
    LibraryCategory.exercises => 'Exercises',
    LibraryCategory.trainingPlans => 'Training plans',
  };
}

enum LibraryTransferScope { item, category }

enum LibraryImportAction { create, update, copy, error }

class LibraryImportEntry {
  const LibraryImportEntry({
    required this.key,
    required this.category,
    required this.id,
    required this.name,
    required this.value,
    required this.action,
    required this.missingReferences,
    this.error,
  });

  final String key;
  final LibraryCategory category;
  final String id;
  final String name;
  final Object? value;
  final LibraryImportAction action;
  final List<Object> missingReferences;
  final String? error;

  bool get canImport => action != LibraryImportAction.error;

  bool get canImportAsCopy =>
      value != null && action == LibraryImportAction.update;
}

class LibraryImportPreview {
  const LibraryImportPreview({
    required this.category,
    required this.scope,
    required this.entries,
  });

  final LibraryCategory category;
  final LibraryTransferScope scope;
  final List<LibraryImportEntry> entries;

  int get createCount => entries
      .where((entry) => entry.action == LibraryImportAction.create)
      .length;

  int get updateCount => entries
      .where((entry) => entry.action == LibraryImportAction.update)
      .length;

  int get errorCount => entries
      .where((entry) => entry.action == LibraryImportAction.error)
      .length;
}

class LibraryImportResult {
  const LibraryImportResult({
    required this.created,
    required this.updated,
    required this.copied,
    required this.failures,
  });

  final int created;
  final int updated;
  final int copied;
  final Map<String, String> failures;

  int get imported => created + updated + copied;
}
