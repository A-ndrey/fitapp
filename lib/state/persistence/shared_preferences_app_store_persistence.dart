import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_store_persistence.dart';
import 'persisted_app_state.dart';
import 'persisted_app_state_codec.dart';

class SharedPreferencesAppStorePersistence implements AppStorePersistence {
  SharedPreferencesAppStorePersistence({
    Set<String> knownExerciseIds = const {},
  }) : knownExerciseIds = Set.unmodifiable(knownExerciseIds);

  static const storageKey = 'app_store_state_v1';

  final Set<String> knownExerciseIds;

  @override
  Future<PersistedAppState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Persisted app state must be a JSON object.');
    }

    return PersistedAppStateCodec.decode(
      decoded,
      knownExerciseIds: knownExerciseIds,
    );
  }

  @override
  Future<void> save(PersistedAppState state) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(PersistedAppStateCodec.encode(state));
    final didSave = await preferences.setString(storageKey, raw);
    if (!didSave) {
      throw StateError('Failed to persist app store state.');
    }
  }
}
