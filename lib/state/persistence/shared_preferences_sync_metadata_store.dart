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
