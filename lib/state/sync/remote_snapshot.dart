import '../persistence/persisted_app_state.dart';

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.state,
    required this.updatedAt,
    required this.snapshotHash,
  });

  final PersistedAppState state;
  final DateTime updatedAt;
  final String snapshotHash;
}
