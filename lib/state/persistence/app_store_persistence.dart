import 'persisted_app_state.dart';

abstract interface class AppStorePersistence {
  /// Returns `null` when no saved state exists yet on the device.
  Future<PersistedAppState?> load();
  Future<void> save(PersistedAppState state);
}
