import 'persisted_app_state.dart';

abstract interface class AppStorePersistence {
  /// Returns `null` when no saved state exists yet on the device.
  Future<PersistedAppState?> load();
  Future<void> save(PersistedAppState state);
}

/// Persistence for the single local cache owned by this device.
///
/// The cache can remain available while signed out. [ownerUserId] only guards
/// cloud synchronization; it does not control whether local data is visible.
abstract interface class DeviceAppStorePersistence
    implements AppStorePersistence {
  String? get ownerUserId;

  Object? get loadError;

  /// Selects and migrates this user's legacy account cache when startup could
  /// not choose one safely before authentication completed.
  Future<PersistedAppState?> migrateLegacyAccount(String userId);

  /// Atomically commits [state] and its synchronization owner.
  Future<void> replace(PersistedAppState state, {required String? ownerUserId});

  /// Removes the device cache and all retained legacy state.
  Future<void> clear();
}
