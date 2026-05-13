class SyncMetadata {
  const SyncMetadata({
    required this.installationId,
    this.lastKnownRemoteUpdatedAt,
    this.lastSyncedSnapshotHash,
    this.lastSyncError,
  });

  final String installationId;
  final DateTime? lastKnownRemoteUpdatedAt;
  final String? lastSyncedSnapshotHash;
  final String? lastSyncError;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'installationId': installationId,
      'lastKnownRemoteUpdatedAt': lastKnownRemoteUpdatedAt?.toIso8601String(),
      'lastSyncedSnapshotHash': lastSyncedSnapshotHash,
      'lastSyncError': lastSyncError,
    };
  }

  static SyncMetadata fromJson(Map<String, Object?> json) {
    final installationId = json['installationId'];
    if (installationId is! String) {
      throw const FormatException(
        'Sync metadata installationId must be a string.',
      );
    }

    final lastKnownRemoteUpdatedAt = _readDateTime(
      json,
      key: 'lastKnownRemoteUpdatedAt',
    );
    final lastSyncedSnapshotHash = _readNullableString(
      json,
      key: 'lastSyncedSnapshotHash',
    );
    final lastSyncError = _readNullableString(json, key: 'lastSyncError');

    return SyncMetadata(
      installationId: installationId,
      lastKnownRemoteUpdatedAt: lastKnownRemoteUpdatedAt,
      lastSyncedSnapshotHash: lastSyncedSnapshotHash,
      lastSyncError: lastSyncError,
    );
  }

  static DateTime? _readDateTime(
    Map<String, Object?> json, {
    required String key,
  }) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Sync metadata $key must be an ISO-8601 string.');
    }

    try {
      return DateTime.parse(value);
    } on FormatException {
      throw FormatException('Sync metadata $key must be an ISO-8601 string.');
    }
  }

  static String? _readNullableString(
    Map<String, Object?> json, {
    required String key,
  }) {
    final value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }

    throw FormatException('Sync metadata $key must be a string or null.');
  }
}
