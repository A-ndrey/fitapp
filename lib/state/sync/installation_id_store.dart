import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallationIdStore {
  static const storageKey = 'app_store_installation_id_v1';

  Future<String> loadOrCreate() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final installationId = _generateInstallationId();
    final didSave = await preferences.setString(storageKey, installationId);
    if (!didSave) {
      throw StateError('Failed to persist installation ID.');
    }

    return installationId;
  }

  String _generateInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
