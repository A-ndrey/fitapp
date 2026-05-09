import 'persisted_app_state.dart';

abstract interface class AppStorePersistence {
  Future<PersistedAppState?> load();
  Future<void> save(PersistedAppState state);
}
