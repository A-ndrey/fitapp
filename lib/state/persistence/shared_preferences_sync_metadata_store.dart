import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_metadata.dart';

class SharedPreferencesSyncMetadataStore {
  static const storageKey = 'app_store_sync_metadata_v1';

  Future<SyncMetadata?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Sync metadata must be a JSON object.');
    }

    return SyncMetadata.fromJson(decoded);
  }

  Future<void> save(SyncMetadata metadata) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(metadata.toJson());
    final didSave = await preferences.setString(storageKey, raw);
    if (!didSave) {
      throw StateError('Failed to persist sync metadata.');
    }
  }
}

Future<SyncMetadata?> loadSyncMetadataFor(
  SharedPreferencesSyncMetadataStore store,
  String installationId,
) async {
  if (store.runtimeType != SharedPreferencesSyncMetadataStore) {
    return store.load();
  }
  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(
    '${SharedPreferencesSyncMetadataStore.storageKey}:$installationId',
  );
  if (raw == null) {
    final legacy = await store.load();
    return legacy?.installationId == installationId ? legacy : null;
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Scoped sync metadata must be an object.');
  }
  return SyncMetadata.fromJson(decoded);
}

Future<void> saveSyncMetadataFor(
  SharedPreferencesSyncMetadataStore store,
  SyncMetadata metadata,
) async {
  if (store.runtimeType != SharedPreferencesSyncMetadataStore) {
    await store.save(metadata);
    return;
  }
  final preferences = await SharedPreferences.getInstance();
  final raw = jsonEncode(metadata.toJson());
  final didSave = await preferences.setString(
    '${SharedPreferencesSyncMetadataStore.storageKey}:${metadata.installationId}',
    raw,
  );
  if (!didSave) {
    throw StateError('Failed to persist scoped sync metadata.');
  }
}
