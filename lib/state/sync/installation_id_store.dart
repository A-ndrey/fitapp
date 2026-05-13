import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallationIdStore {
  InstallationIdStore({
    Future<InstallationIdPreferences> Function()? preferencesLoader,
    String Function()? idGenerator,
  }) : _preferencesLoader =
           preferencesLoader ??
           SharedPreferencesInstallationIdPreferences.getInstance,
       _idGenerator = idGenerator ?? _generateInstallationId;

  static const storageKey = 'app_store_installation_id_v1';

  final Future<InstallationIdPreferences> Function() _preferencesLoader;
  final String Function() _idGenerator;
  Future<String>? _inFlightLoadOrCreate;

  Future<String> loadOrCreate() async {
    return _inFlightLoadOrCreate ??= _loadOrCreate().whenComplete(() {
      _inFlightLoadOrCreate = null;
    });
  }

  Future<String> _loadOrCreate() async {
    final preferences = await _preferencesLoader();
    final existing = preferences.getString(storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final installationId = _idGenerator();
    final didSave = await preferences.setString(storageKey, installationId);
    if (!didSave) {
      throw StateError('Failed to persist installation ID.');
    }

    return installationId;
  }

  static String _generateInstallationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

abstract class InstallationIdPreferences {
  String? getString(String key);

  Future<bool> setString(String key, String value);
}

class SharedPreferencesInstallationIdPreferences
    implements InstallationIdPreferences {
  SharedPreferencesInstallationIdPreferences._(this._preferences);

  final SharedPreferences _preferences;
  static Future<SharedPreferencesInstallationIdPreferences>? _instanceFuture;

  static Future<SharedPreferencesInstallationIdPreferences> getInstance() {
    return _instanceFuture ??= SharedPreferences.getInstance().then(
      SharedPreferencesInstallationIdPreferences._,
    );
  }

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);
}
