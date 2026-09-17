import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_store_persistence.dart';
import 'persisted_app_state.dart';
import 'persisted_app_state_codec.dart';
import 'persisted_state_slices.dart';
import '../app_state_components.dart';

class SharedPreferencesAppStorePersistence
    implements AccountScopedAppStorePersistence {
  SharedPreferencesAppStorePersistence({
    Set<String> knownExerciseIds = const {},
  }) : knownExerciseIds = Set.unmodifiable(knownExerciseIds);

  static const storageKey = 'app_store_state_v1';
  static const _v2Prefix = 'app_store_state_v2';

  final Set<String> knownExerciseIds;
  String _scope = 'guest';
  int _generationCounter = 0;

  @override
  String? get activeUserId =>
      _scope.startsWith('user:') ? _scope.substring(5) : null;

  @override
  Future<PersistedAppState?> load() async {
    final scope = _scope;
    final preferences = await SharedPreferences.getInstance();
    final v2 = _loadV2(preferences, scope);
    if (v2 != null) {
      return v2;
    }
    if (scope != 'guest') {
      return null;
    }
    final raw = preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }
    final legacy = _decodeLegacy(raw);
    await _saveV2(preferences, scope, legacy);
    return legacy;
  }

  @override
  Future<void> save(PersistedAppState state) async {
    final scope = _scope;
    final preferences = await SharedPreferences.getInstance();
    await _saveV2(preferences, scope, state);
  }

  @override
  Future<PersistedAppState?> activateGuest() async {
    final preferences = await SharedPreferences.getInstance();
    final state = _loadV2(preferences, 'guest');
    _scope = 'guest';
    if (state != null) {
      return state;
    }
    final raw = preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }
    final legacy = _decodeLegacy(raw);
    await _saveV2(preferences, 'guest', legacy);
    return legacy;
  }

  @override
  Future<PersistedAppState?> activateAccount(
    String userId, {
    PersistedAppState? seed,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    final scope = 'user:$userId';
    final preferences = await SharedPreferences.getInstance();
    final existing = _loadV2(preferences, scope);
    if (existing != null || seed == null) {
      _scope = scope;
      return existing;
    }
    await _saveV2(preferences, scope, seed);
    _scope = scope;
    return seed;
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

  PersistedAppState? _loadV2(SharedPreferences preferences, String scope) {
    final rawManifest = preferences.getString(_manifestKey(scope));
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
    final encodedKeys = decodedManifest['slices'];
    if (encodedKeys is! Map) {
      throw const FormatException('Persisted v2 slices must be an object.');
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

  Future<void> _saveV2(
    SharedPreferences preferences,
    String scope,
    PersistedAppState state,
  ) async {
    final currentPointers = _readCurrentPointers(preferences, scope);
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
      final nextKey = '$_v2Prefix:$scope:$generation:${slice.name}';
      final didSave = await preferences.setString(nextKey, raw);
      if (!didSave) {
        throw StateError('Failed to persist ${slice.name} state.');
      }
      nextPointers[slice.name] = nextKey;
    }

    final candidateManifest = <String, Object?>{
      'schemaVersion': 2,
      'slices': nextPointers,
    };
    final verified = _decodePointers(preferences, nextPointers);
    final expected = jsonEncode(PersistedAppStateCodec.encode(state));
    final actual = jsonEncode(PersistedAppStateCodec.encode(verified));
    if (actual != expected) {
      throw StateError('Persisted v2 verification failed.');
    }
    final didCommit = await preferences.setString(
      _manifestKey(scope),
      jsonEncode(candidateManifest),
    );
    if (!didCommit) {
      throw StateError('Failed to commit persisted v2 manifest.');
    }
    await _removeStaleSlices(preferences, scope, nextPointers.values.toSet());
  }

  Future<void> _removeStaleSlices(
    SharedPreferences preferences,
    String scope,
    Set<String> retainedKeys,
  ) async {
    final prefix = '$_v2Prefix:$scope:';
    final manifestKey = _manifestKey(scope);
    final staleKeys = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith(prefix) &&
              key != manifestKey &&
              !retainedKeys.contains(key),
        )
        .toList(growable: false);
    for (final key in staleKeys) {
      await preferences.remove(key);
    }
  }

  Map<String, String> _readCurrentPointers(
    SharedPreferences preferences,
    String scope,
  ) {
    final rawManifest = preferences.getString(_manifestKey(scope));
    if (rawManifest == null) {
      return <String, String>{};
    }
    final decoded = jsonDecode(rawManifest);
    if (decoded is! Map || decoded['slices'] is! Map) {
      throw const FormatException('Persisted v2 manifest is invalid.');
    }
    return (decoded['slices'] as Map).map((key, value) {
      if (key is! String || value is! String) {
        throw const FormatException('Persisted v2 pointer is invalid.');
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

  static String _manifestKey(String scope) => '$_v2Prefix:$scope:manifest';
}
