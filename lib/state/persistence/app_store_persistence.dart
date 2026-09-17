import 'persisted_app_state.dart';

abstract interface class AppStorePersistence {
  /// Returns `null` when no saved state exists yet on the device.
  Future<PersistedAppState?> load();
  Future<void> save(PersistedAppState state);
}

/// Persistence that isolates guest data from each authenticated account.
abstract interface class AccountScopedAppStorePersistence
    implements AppStorePersistence {
  String? get activeUserId;

  Future<PersistedAppState?> activateGuest();

  Future<PersistedAppState?> activateAccount(
    String userId, {
    PersistedAppState? seed,
  });
}
