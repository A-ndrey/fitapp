import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_state_components.dart';
import 'app_store_persistence.dart';
import 'persisted_app_state.dart';
import 'persisted_app_state_codec.dart';
import 'persisted_state_slices.dart';

class SharedPreferencesAppStorePersistence
    implements DeviceAppStorePersistence {
  SharedPreferencesAppStorePersistence({
    Set<String> knownExerciseIds = const {},
  }) : knownExerciseIds = Set.unmodifiable(knownExerciseIds);

  static const storageKey = 'app_store_state_v1';
  static const _legacyV2Prefix = 'app_store_state_v2';
  static const _v3Prefix = 'app_store_state_v3';
  static const _deviceScope = 'device';

  final Set<String> knownExerciseIds;
  int _generationCounter = 0;
  String? _ownerUserId;
  Object? _loadError;

  @override
  String? get ownerUserId => _ownerUserId;

  @override
  Object? get loadError => _loadError;

  @override
  Future<PersistedAppState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    _loadError = null;
    try {
      final deviceCache = _loadV3(preferences);
      if (deviceCache != null) {
        _ownerUserId = deviceCache.ownerUserId;
        return deviceCache.state;
      }

      final legacyUsers = _legacyAccountUserIds(preferences);
      if (legacyUsers.length == 1) {
        return await _migrateLegacyAccount(preferences, legacyUsers.single);
      }

      if (legacyUsers.isEmpty) {
        return await _migrateUnscopedV1(preferences);
      }
      return null;
    } catch (error) {
      _loadError = error;
      return null;
    }
  }

  @override
  Future<void> save(PersistedAppState state) async {
    final preferences = await SharedPreferences.getInstance();
    await _saveV3(preferences, state, ownerUserId: _ownerUserId);
  }

  @override
  Future<PersistedAppState?> migrateLegacyAccount(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    final preferences = await SharedPreferences.getInstance();
    final deviceCache = _loadV3(preferences);
    if (deviceCache != null) {
      _ownerUserId = deviceCache.ownerUserId;
      _loadError = null;
      return deviceCache.state;
    }
    if (!_legacyAccountUserIds(preferences).contains(userId)) {
      return null;
    }
    try {
      final state = await _migrateLegacyAccount(preferences, userId);
      _loadError = null;
      return state;
    } catch (error) {
      _loadError = error;
      return null;
    }
  }

  @override
  Future<void> replace(
    PersistedAppState state, {
    required String? ownerUserId,
  }) async {
    if (ownerUserId != null && ownerUserId.trim().isEmpty) {
      throw ArgumentError.value(
        ownerUserId,
        'ownerUserId',
        'Must not be empty.',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    await _saveV3(preferences, state, ownerUserId: ownerUserId);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where(
          (key) =>
              key == storageKey ||
              key.startsWith('$_legacyV2Prefix:') ||
              key.startsWith('$_v3Prefix:'),
        )
        .toList(growable: false);
    for (final key in keys) {
      final didRemove = await preferences.remove(key);
      if (!didRemove) {
        throw StateError('Failed to remove persisted app state.');
      }
    }
    _ownerUserId = null;
    _loadError = null;
  }

  Future<PersistedAppState> _migrateLegacyAccount(
    SharedPreferences preferences,
    String userId,
  ) async {
    final state = _loadV2(preferences, 'user:$userId');
    if (state == null) {
      throw StateError('Legacy account cache disappeared during migration.');
    }
    await _saveV3(preferences, state, ownerUserId: userId);
    return state;
  }

  Future<PersistedAppState?> _migrateUnscopedV1(
    SharedPreferences preferences,
  ) async {
    final raw = preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }
    final legacy = _decodeLegacy(raw);
    await _saveV3(preferences, legacy, ownerUserId: null);
    return legacy;
  }

  PersistedAppState _decodeLegacy(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Persisted app state must be a JSON object.');
    }
    return PersistedAppStateCodec.decode(
      decoded,
      knownExerciseIds: knownExerciseIds,
    );
  }

  _DeviceCache? _loadV3(SharedPreferences preferences) {
    final rawManifest = preferences.getString(_v3ManifestKey);
    if (rawManifest == null) {
      return null;
    }
    final decodedManifest = jsonDecode(rawManifest);
    if (decodedManifest is! Map) {
      throw const FormatException('Persisted v3 manifest must be an object.');
    }
    if (decodedManifest['schemaVersion'] != 3) {
      throw const FormatException('Persisted v3 schemaVersion must be 3.');
    }
    final owner = decodedManifest['ownerUserId'];
    if (owner != null && owner is! String) {
      throw const FormatException('Persisted v3 ownerUserId is invalid.');
    }
    return _DeviceCache(
      state: _decodeManifestSlices(preferences, decodedManifest, version: 3),
      ownerUserId: owner as String?,
    );
  }

  PersistedAppState? _loadV2(SharedPreferences preferences, String scope) {
    final rawManifest = preferences.getString(_v2ManifestKey(scope));
    if (rawManifest == null) {
      return null;
    }
    final decodedManifest = jsonDecode(rawManifest);
    if (decodedManifest is! Map) {
      throw const FormatException('Persisted v2 manifest must be an object.');
    }
    if (decodedManifest['schemaVersion'] != 2) {
      throw const FormatException('Persisted v2 schemaVersion must be 2.');
    }
    return _decodeManifestSlices(preferences, decodedManifest, version: 2);
  }

  PersistedAppState _decodeManifestSlices(
    SharedPreferences preferences,
    Map<dynamic, dynamic> manifest, {
    required int version,
  }) {
    final encodedKeys = manifest['slices'];
    if (encodedKeys is! Map) {
      throw FormatException('Persisted v$version slices must be an object.');
    }
    final slices = <AppStateSlice, Object?>{};
    for (final slice in AppStateSlice.values) {
      final storageKey = encodedKeys[slice.name];
      if (storageKey is! String) {
        throw FormatException('Missing ${slice.name} slice pointer.');
      }
      final rawSlice = preferences.getString(storageKey);
      if (rawSlice == null) {
        throw FormatException('Missing persisted ${slice.name} slice.');
      }
      slices[slice] = jsonDecode(rawSlice);
    }
    return PersistedStateSlices.decode(
      slices,
      knownExerciseIds: knownExerciseIds,
    );
  }

  Future<void> _saveV3(
    SharedPreferences preferences,
    PersistedAppState state, {
    required String? ownerUserId,
  }) async {
    final currentPointers = _readCurrentV3Pointers(preferences);
    final nextPointers = <String, String>{};
    final encodedSlices = PersistedStateSlices.encode(state);
    final generation =
        '${DateTime.now().microsecondsSinceEpoch}-${_generationCounter++}';

    for (final slice in AppStateSlice.values) {
      final raw = jsonEncode(encodedSlices[slice]);
      final currentKey = currentPointers[slice.name];
      if (currentKey != null && preferences.getString(currentKey) == raw) {
        nextPointers[slice.name] = currentKey;
        continue;
      }
      final nextKey = '$_v3Prefix:$_deviceScope:$generation:${slice.name}';
      final didSave = await preferences.setString(nextKey, raw);
      if (!didSave) {
        throw StateError('Failed to persist ${slice.name} state.');
      }
      nextPointers[slice.name] = nextKey;
    }

    final candidateManifest = <String, Object?>{
      'schemaVersion': 3,
      'ownerUserId': ownerUserId,
      'slices': nextPointers,
    };
    final verified = _decodePointers(preferences, nextPointers);
    final expected = jsonEncode(PersistedAppStateCodec.encode(state));
    final actual = jsonEncode(PersistedAppStateCodec.encode(verified));
    if (actual != expected) {
      throw StateError('Persisted v3 verification failed.');
    }
    final didCommit = await preferences.setString(
      _v3ManifestKey,
      jsonEncode(candidateManifest),
    );
    if (!didCommit) {
      throw StateError('Failed to commit persisted v3 manifest.');
    }
    _ownerUserId = ownerUserId;
    _loadError = null;
    await _removeStaleV3Slices(preferences, nextPointers.values.toSet());
  }

  Future<void> _removeStaleV3Slices(
    SharedPreferences preferences,
    Set<String> retainedKeys,
  ) async {
    const prefix = '$_v3Prefix:$_deviceScope:';
    final staleKeys = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith(prefix) &&
              key != _v3ManifestKey &&
              !retainedKeys.contains(key),
        )
        .toList(growable: false);
    for (final key in staleKeys) {
      await preferences.remove(key);
    }
  }

  Map<String, String> _readCurrentV3Pointers(SharedPreferences preferences) {
    final rawManifest = preferences.getString(_v3ManifestKey);
    if (rawManifest == null) {
      return <String, String>{};
    }
    final decoded = jsonDecode(rawManifest);
    if (decoded is! Map ||
        decoded['schemaVersion'] != 3 ||
        decoded['slices'] is! Map) {
      throw const FormatException('Persisted v3 manifest is invalid.');
    }
    return (decoded['slices'] as Map).map((key, value) {
      if (key is! String || value is! String) {
        throw const FormatException('Persisted v3 pointer is invalid.');
      }
      return MapEntry(key, value);
    });
  }

  PersistedAppState _decodePointers(
    SharedPreferences preferences,
    Map<String, String> pointers,
  ) {
    final slices = <AppStateSlice, Object?>{};
    for (final slice in AppStateSlice.values) {
      final pointer = pointers[slice.name];
      final raw = pointer == null ? null : preferences.getString(pointer);
      if (raw == null) {
        throw StateError('Cannot verify ${slice.name} state.');
      }
      slices[slice] = jsonDecode(raw);
    }
    return PersistedStateSlices.decode(
      slices,
      knownExerciseIds: knownExerciseIds,
    );
  }

  Set<String> _legacyAccountUserIds(SharedPreferences preferences) {
    const prefix = '$_legacyV2Prefix:user:';
    const suffix = ':manifest';
    return preferences
        .getKeys()
        .where((key) {
          return key.startsWith(prefix) && key.endsWith(suffix);
        })
        .map((key) {
          return key.substring(prefix.length, key.length - suffix.length);
        })
        .where((userId) {
          return userId.isNotEmpty;
        })
        .toSet();
  }

  static String get _v3ManifestKey => '$_v3Prefix:$_deviceScope:manifest';

  static String _v2ManifestKey(String scope) =>
      '$_legacyV2Prefix:$scope:manifest';
}

class _DeviceCache {
  const _DeviceCache({required this.state, required this.ownerUserId});

  final PersistedAppState state;
  final String? ownerUserId;
}
