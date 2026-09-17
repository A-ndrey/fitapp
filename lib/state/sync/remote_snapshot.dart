import '../persistence/persisted_app_state.dart';

class RemoteSnapshot {
  const RemoteSnapshot({
    required this.state,
    required this.updatedAt,
    required this.snapshotHash,
    this.isLegacy = false,
    this.entityHashes = const <String, String>{},
    this.activeWorkoutLeaseOwnerId,
    this.activeWorkoutLeaseExpiresAt,
  });

  final PersistedAppState state;
  final DateTime updatedAt;
  final String snapshotHash;
  final bool isLegacy;
  final Map<String, String> entityHashes;
  final String? activeWorkoutLeaseOwnerId;
  final DateTime? activeWorkoutLeaseExpiresAt;
}
