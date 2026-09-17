class SyncMetadata {
  const SyncMetadata({
    required this.installationId,
    this.lastKnownRemoteUpdatedAt,
    this.lastSyncedSnapshotHash,
    this.lastSyncError,
    this.lastSyncedEntityHashes = const <String, String>{},
    this.lastSyncedPreferenceGroupHashes = const <String, String>{},
  });

  final String installationId;
  final DateTime? lastKnownRemoteUpdatedAt;
  final String? lastSyncedSnapshotHash;
  final String? lastSyncError;
  final Map<String, String> lastSyncedEntityHashes;
  final Map<String, String> lastSyncedPreferenceGroupHashes;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'installationId': installationId,
      'lastKnownRemoteUpdatedAt': lastKnownRemoteUpdatedAt?.toIso8601String(),
      'lastSyncedSnapshotHash': lastSyncedSnapshotHash,
      'lastSyncError': lastSyncError,
      'lastSyncedEntityHashes': lastSyncedEntityHashes,
      'lastSyncedPreferenceGroupHashes': lastSyncedPreferenceGroupHashes,
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
    final lastSyncedEntityHashes = _readStringMap(
      json,
      key: 'lastSyncedEntityHashes',
    );
    final lastSyncedPreferenceGroupHashes = _readStringMap(
      json,
      key: 'lastSyncedPreferenceGroupHashes',
    );

    return SyncMetadata(
      installationId: installationId,
      lastKnownRemoteUpdatedAt: lastKnownRemoteUpdatedAt,
      lastSyncedSnapshotHash: lastSyncedSnapshotHash,
      lastSyncError: lastSyncError,
      lastSyncedEntityHashes: lastSyncedEntityHashes,
      lastSyncedPreferenceGroupHashes: lastSyncedPreferenceGroupHashes,
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

  static Map<String, String> _readStringMap(
    Map<String, Object?> json, {
    required String key,
  }) {
    final value = json[key];
    if (value == null) {
      return const <String, String>{};
    }
    if (value is! Map) {
      throw FormatException('Sync metadata $key must be an object.');
    }
    return Map.unmodifiable(
      value.map((mapKey, mapValue) {
        if (mapKey is! String || mapValue is! String) {
          throw FormatException(
            'Sync metadata $key must contain string values.',
          );
        }
        return MapEntry(mapKey, mapValue);
      }),
    );
  }
}
