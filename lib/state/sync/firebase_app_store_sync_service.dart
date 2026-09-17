import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../persistence/persisted_app_state.dart';
import '../persistence/persisted_app_state_codec.dart';
import 'installation_id_store.dart';
import 'persisted_entity_bundle.dart';
import 'remote_snapshot.dart';

class FirebaseAppStoreSyncService {
  FirebaseAppStoreSyncService({
    FirebaseFirestore? firestore,
    RemoteSnapshotStore? backend,
    Set<String> knownExerciseIds = const {},
    InstallationIdStore? writerIdStore,
  }) : backend =
           backend ??
           FirestoreRemoteSnapshotStore(
             firestore ?? FirebaseFirestore.instance,
           ),
       knownExerciseIds = Set.unmodifiable(knownExerciseIds),
       _writerIdStore = writerIdStore ?? InstallationIdStore();

  static const int schemaVersion = 1;

  final RemoteSnapshotStore backend;
  final Set<String> knownExerciseIds;
  final InstallationIdStore _writerIdStore;
  final Map<String, Map<String, String>> _knownEntityHashes = {};
  final Map<String, Map<String, RemoteEntityRecord>> _entityDocuments = {};
  final Map<String, String?> _activeLeaseOwners = {};
  final Map<String, DateTime?> _activeLeaseExpirations = {};

  Future<RemoteSnapshot?> fetch(String installationId) async {
    if (backend is EntityRemoteSnapshotStore) {
      return _fetchEntitySnapshot(installationId);
    }
    final document = await backend.fetch(_documentPath(installationId));
    if (document == null) {
      return null;
    }

    return _decodeRemoteSnapshot(document);
  }

  Future<RemoteSnapshot> push(
    String installationId,
    PersistedAppState state,
    String snapshotHash,
  ) async {
    if (backend is EntityRemoteSnapshotStore) {
      return _pushEntitySnapshot(installationId, state);
    }
    final path = _documentPath(installationId);
    await backend.set(path, <String, Object?>{
      'schemaVersion': schemaVersion,
      'updatedAt': FieldValue.serverTimestamp(),
      'snapshotHash': snapshotHash,
      'payload': PersistedAppStateCodec.encode(state),
    });

    final remoteSnapshot = await fetch(installationId);
    if (remoteSnapshot == null) {
      throw StateError('Remote snapshot was missing after push.');
    }
    if (remoteSnapshot.snapshotHash != snapshotHash) {
      throw StateError(
        'Remote snapshot hash mismatch after push: expected '
        '"$snapshotHash", got "${remoteSnapshot.snapshotHash}".',
      );
    }

    return remoteSnapshot;
  }

  Future<void> deleteUserState(String userId) {
    final entityBackend = backend;
    if (entityBackend is EntityRemoteSnapshotStore) {
      return _deleteEntityState(entityBackend, userId);
    }
    return backend.delete(_documentPath(userId));
  }

  static String _documentPath(String userId) => 'users/$userId/state/current';

  RemoteSnapshot _decodeRemoteSnapshot(Map<String, Object?> document) {
    final decodedSchemaVersion = _readInt(document, 'schemaVersion');
    if (decodedSchemaVersion != schemaVersion) {
      throw const FormatException(
        'Remote snapshot schemaVersion must be $schemaVersion.',
      );
    }

    final payload = document['payload'];
    if (payload == null) {
      throw const FormatException('Remote snapshot payload is required.');
    }

    return RemoteSnapshot(
      state: PersistedAppStateCodec.decode(
        payload,
        knownExerciseIds: knownExerciseIds,
      ),
      updatedAt: _readDateTime(document, 'updatedAt'),
      snapshotHash: _readString(document, 'snapshotHash'),
      isLegacy: true,
    );
  }

  Future<RemoteSnapshot?> _fetchEntitySnapshot(String userId) async {
    final entityBackend = backend as EntityRemoteSnapshotStore;
    final manifest = await entityBackend.fetch(
      FirebaseAppStoreSyncService._manifestPath(userId),
    );
    if (manifest != null &&
        manifest['schemaVersion'] == 2 &&
        manifest['committed'] == true) {
      return _readCommittedEntityState(entityBackend, userId);
    }

    final legacy = await entityBackend.fetch(_documentPath(userId));
    if (legacy == null) {
      return null;
    }
    return _decodeRemoteSnapshot(legacy);
  }

  Future<RemoteSnapshot> _pushEntitySnapshot(
    String userId,
    PersistedAppState state,
  ) async {
    final entityBackend = backend as EntityRemoteSnapshotStore;
    final writerId = await _writerIdStore.loadOrCreate();
    final manifest = await entityBackend.fetch(_manifestPath(userId));
    final isCommitted =
        manifest?['schemaVersion'] == 2 && manifest?['committed'] == true;
    if (!isCommitted) {
      final acquired = await entityBackend.acquireMigrationLease(
        _manifestPath(userId),
        writerId: writerId,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 4)),
      );
      if (!acquired) {
        throw StateError('Another device is migrating this account.');
      }
    }

    if (!_knownEntityHashes.containsKey(userId)) {
      final current = await _readEntityState(entityBackend, userId);
      _knownEntityHashes[userId] = current.entityHashes;
    }

    final desired = PersistedEntityBundle.encode(state);
    final desiredHashes = desired.map(
      (key, value) => MapEntry(key, PersistedEntityBundle.hashJson(value)),
    );
    final previousHashes = _knownEntityHashes[userId] ?? const {};
    final writes = <String, Map<String, Object?>>{};
    for (final entry in desired.entries) {
      if (previousHashes[entry.key] == desiredHashes[entry.key]) {
        continue;
      }
      final isActiveWorkout = entry.key == 'runtime/activeWorkout';
      if (isActiveWorkout && _hasForeignActiveLease(userId, writerId)) {
        throw StateError('The active workout is owned by another device.');
      }
      writes['users/$userId/${entry.key}'] = <String, Object?>{
        'schemaVersion': 2,
        'payload': entry.value,
        'contentHash': desiredHashes[entry.key],
        'contentHashVersion': 3,
        'updatedAt': FieldValue.serverTimestamp(),
        'writerId': writerId,
        'deletedAt': null,
        if (isActiveWorkout) 'leaseOwnerId': writerId,
        if (isActiveWorkout)
          'leaseExpiresAt': Timestamp.fromDate(
            DateTime.now().toUtc().add(const Duration(minutes: 4)),
          ),
      };
    }
    for (final previousKey in previousHashes.keys) {
      if (desired.containsKey(previousKey) ||
          previousHashes[previousKey] == 'deleted') {
        continue;
      }
      if (previousKey == 'runtime/activeWorkout' &&
          _hasForeignActiveLease(userId, writerId)) {
        throw StateError('The active workout is owned by another device.');
      }
      writes['users/$userId/$previousKey'] = <String, Object?>{
        'schemaVersion': 2,
        'payload': null,
        'contentHash': 'deleted',
        'contentHashVersion': 3,
        'updatedAt': FieldValue.serverTimestamp(),
        'writerId': writerId,
        'deletedAt': FieldValue.serverTimestamp(),
      };
    }
    if (isCommitted && writes.length > 450) {
      throw StateError(
        'A single incremental sync cannot safely update more than 450 '
        'entities.',
      );
    }
    await entityBackend.setAll(writes);

    final verified = await _readEntityState(entityBackend, userId);
    final expectedHash = PersistedEntityBundle.snapshotHash(state);
    if (verified.snapshotHash != expectedHash) {
      throw StateError(
        'Entity migration verification failed: expected "$expectedHash", '
        'got "${verified.snapshotHash}".',
      );
    }
    await entityBackend.set(_manifestPath(userId), <String, Object?>{
      'schemaVersion': 2,
      'committed': true,
      'snapshotHash': verified.snapshotHash,
      'updatedAt': FieldValue.serverTimestamp(),
      'writerId': writerId,
    });
    _knownEntityHashes[userId] = verified.entityHashes;
    return verified;
  }

  Future<RemoteSnapshot> _readCommittedEntityState(
    EntityRemoteSnapshotStore entityBackend,
    String userId,
  ) async {
    final snapshot = await _readEntityState(entityBackend, userId);
    _knownEntityHashes[userId] = snapshot.entityHashes;
    return snapshot;
  }

  Future<RemoteSnapshot> _readEntityState(
    EntityRemoteSnapshotStore entityBackend,
    String userId,
  ) async {
    final records = await Future.wait(
      PersistedEntityBundle.collections.map(
        (collection) =>
            entityBackend.fetchCollection('users/$userId/$collection'),
      ),
    );
    final flattened = records.expand((collection) => collection).toList();
    _entityDocuments[userId] = <String, RemoteEntityRecord>{
      for (final record in flattened) record.path: record,
    };
    return _decodeEntityRecords(userId, flattened);
  }

  RemoteSnapshot _decodeEntityRecords(
    String userId,
    Iterable<RemoteEntityRecord> records,
  ) {
    final entities = <String, Map<String, Object?>>{};
    final hashes = <String, String>{};
    final storedContentHashes = <String, String>{};
    final contentHashVersions = <String, int?>{};
    DateTime? latestUpdatedAt;
    String? activeLeaseOwner;
    DateTime? activeLeaseExpiration;
    var containsLegacyContentHashes = false;
    for (final record in records) {
      final document = record.data;
      if (document['schemaVersion'] != 2) {
        throw FormatException('Entity ${record.path} schemaVersion must be 2.');
      }
      final relativePath = record.path.split('/').skip(2).join('/');
      final updatedAt = _readDateTime(document, 'updatedAt');
      if (latestUpdatedAt == null || updatedAt.isAfter(latestUpdatedAt)) {
        latestUpdatedAt = updatedAt;
      }
      if (document['deletedAt'] != null) {
        hashes[relativePath] = 'deleted';
        continue;
      }
      if (relativePath == 'runtime/activeWorkout') {
        activeLeaseOwner = document['leaseOwnerId'] as String?;
        final leaseValue = document['leaseExpiresAt'];
        activeLeaseExpiration = leaseValue is Timestamp
            ? leaseValue.toDate().toUtc()
            : null;
      }
      final payload = document['payload'];
      if (payload is! Map) {
        throw FormatException('Entity ${record.path} payload is required.');
      }
      final normalizedPayload = Map<String, Object?>.from(payload);
      final contentHash = _readString(document, 'contentHash');
      final contentHashVersion = document['contentHashVersion'];
      if (contentHashVersion != null &&
          contentHashVersion != 2 &&
          contentHashVersion != 3) {
        throw FormatException(
          'Entity ${record.path} contentHashVersion is unsupported.',
        );
      }
      entities[relativePath] = normalizedPayload;
      storedContentHashes[relativePath] = contentHash;
      contentHashVersions[relativePath] = contentHashVersion as int?;
      if (contentHashVersion == 3) {
        hashes[relativePath] = contentHash;
      } else {
        containsLegacyContentHashes = true;
        hashes[relativePath] = 'legacy:$contentHash';
      }
    }
    final state = PersistedEntityBundle.decode(
      entities,
      knownExerciseIds: knownExerciseIds,
    );
    final canonicalEntities = PersistedEntityBundle.encode(state);
    for (final entry in contentHashVersions.entries) {
      if (entry.value != 3) {
        continue;
      }
      final canonicalPayload = canonicalEntities[entry.key];
      final storedHash = storedContentHashes[entry.key];
      if (canonicalPayload == null || storedHash == null) {
        throw FormatException(
          'Entity users/$userId/${entry.key} could not be canonicalized.',
        );
      }
      final calculatedHash = PersistedEntityBundle.hashJson(canonicalPayload);
      if (calculatedHash != storedHash) {
        throw FormatException(
          'Entity users/$userId/${entry.key} hash is invalid.',
        );
      }
    }
    _activeLeaseOwners[userId] = activeLeaseOwner;
    _activeLeaseExpirations[userId] = activeLeaseExpiration;
    _knownEntityHashes[userId] = Map.unmodifiable(hashes);
    return RemoteSnapshot(
      state: state,
      updatedAt: latestUpdatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      snapshotHash: PersistedEntityBundle.snapshotHash(state),
      isLegacy: containsLegacyContentHashes,
      entityHashes: Map.unmodifiable(hashes),
      activeWorkoutLeaseOwnerId: activeLeaseOwner,
      activeWorkoutLeaseExpiresAt: activeLeaseExpiration,
    );
  }

  bool _hasForeignActiveLease(String userId, String writerId) {
    final owner = _activeLeaseOwners[userId];
    final expiration = _activeLeaseExpirations[userId];
    return owner != null &&
        owner != writerId &&
        expiration != null &&
        expiration.isAfter(DateTime.now().toUtc());
  }

  Future<void> _deleteEntityState(
    EntityRemoteSnapshotStore entityBackend,
    String userId,
  ) async {
    for (final collection in <String>{
      ...PersistedEntityBundle.collections,
      'sync',
    }) {
      await entityBackend.deleteCollection('users/$userId/$collection');
    }
    await entityBackend.delete(_documentPath(userId));
  }

  static String _manifestPath(String userId) => 'users/$userId/sync/manifest';

  static int _readInt(Map<String, Object?> document, String key) {
    final value = document[key];
    if (value is int) {
      return value;
    }

    throw FormatException('Remote snapshot $key must be an int.');
  }

  static String _readString(Map<String, Object?> document, String key) {
    final value = document[key];
    if (value is String) {
      return value;
    }

    throw FormatException('Remote snapshot $key must be a string.');
  }

  static DateTime _readDateTime(Map<String, Object?> document, String key) {
    final value = document[key];
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }

    throw FormatException('Remote snapshot $key must be a timestamp.');
  }
}

abstract class RemoteSnapshotStore {
  Future<Map<String, Object?>?> fetch(String path);

  Future<void> set(String path, Map<String, Object?> data);

  Future<void> delete(String path);
}

class RemoteEntityRecord {
  const RemoteEntityRecord({required this.path, required this.data});

  final String path;
  final Map<String, Object?> data;
}

abstract interface class EntityRemoteSnapshotStore
    implements RemoteSnapshotStore {
  Future<List<RemoteEntityRecord>> fetchCollection(String path);

  Stream<List<RemoteEntityRecord>> watchCollection(String path);

  Future<void> setAll(Map<String, Map<String, Object?>> documents);

  Future<bool> acquireMigrationLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
  });

  Future<void> deleteCollection(String path);

  Future<bool> claimActiveWorkoutLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
    required bool force,
  });
}

class FirestoreRemoteSnapshotStore implements EntityRemoteSnapshotStore {
  FirestoreRemoteSnapshotStore(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<Map<String, Object?>?> fetch(String path) async {
    final snapshot = await firestore.doc(path).get();
    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return Map<String, Object?>.from(data);
  }

  @override
  Future<void> set(String path, Map<String, Object?> data) {
    return firestore.doc(path).set(data);
  }

  @override
  Future<void> delete(String path) {
    return firestore.doc(path).delete();
  }

  @override
  Future<List<RemoteEntityRecord>> fetchCollection(String path) async {
    final snapshot = await firestore.collection(path).get();
    return snapshot.docs
        .map(
          (document) => RemoteEntityRecord(
            path: document.reference.path,
            data: Map<String, Object?>.from(document.data()),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<List<RemoteEntityRecord>> watchCollection(String path) {
    return firestore
        .collection(path)
        .snapshots()
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
        .map((snapshot) {
          return snapshot.docs
              .map(
                (document) => RemoteEntityRecord(
                  path: document.reference.path,
                  data: Map<String, Object?>.from(document.data()),
                ),
              )
              .toList(growable: false);
        });
  }

  @override
  Future<void> setAll(Map<String, Map<String, Object?>> documents) async {
    final entries = documents.entries.toList(growable: false);
    for (var offset = 0; offset < entries.length; offset += 450) {
      final batch = firestore.batch();
      final end = offset + 450 < entries.length ? offset + 450 : entries.length;
      for (final entry in entries.sublist(offset, end)) {
        batch.set(firestore.doc(entry.key), entry.value);
      }
      await batch.commit();
    }
  }

  @override
  Future<bool> acquireMigrationLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
  }) {
    final reference = firestore.doc(path);
    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data?['committed'] == true && data?['schemaVersion'] == 2) {
        return true;
      }
      final currentWriter = data?['writerId'];
      final leaseValue = data?['leaseExpiresAt'];
      final leaseExpiresAt = leaseValue is Timestamp
          ? leaseValue.toDate().toUtc()
          : null;
      if (currentWriter != null &&
          currentWriter != writerId &&
          leaseExpiresAt != null &&
          leaseExpiresAt.isAfter(DateTime.now().toUtc())) {
        return false;
      }
      transaction.set(reference, <String, Object?>{
        'schemaVersion': 2,
        'committed': false,
        'writerId': writerId,
        'leaseExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  @override
  Future<void> deleteCollection(String path) async {
    while (true) {
      final snapshot = await firestore.collection(path).limit(450).get();
      if (snapshot.docs.isEmpty) {
        return;
      }
      final batch = firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  @override
  Future<bool> claimActiveWorkoutLease(
    String path, {
    required String writerId,
    required DateTime expiresAt,
    required bool force,
  }) {
    final reference = firestore.doc(path);
    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (!snapshot.exists || data?['deletedAt'] != null) {
        return false;
      }
      final currentOwner = data?['leaseOwnerId'];
      final currentLease = data?['leaseExpiresAt'];
      final currentExpiration = currentLease is Timestamp
          ? currentLease.toDate().toUtc()
          : null;
      final hasLiveForeignLease =
          currentOwner != null &&
          currentOwner != writerId &&
          currentExpiration != null &&
          currentExpiration.isAfter(DateTime.now().toUtc());
      if (hasLiveForeignLease && !force) {
        return false;
      }
      transaction.update(reference, <String, Object?>{
        'leaseOwnerId': writerId,
        'leaseExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}

extension FirebaseEntitySyncCapabilities on FirebaseAppStoreSyncService {
  bool get usesEntityStorage => backend is EntityRemoteSnapshotStore;

  Future<bool> hasCommittedEntityState(String userId) async {
    final entityBackend = backend;
    if (entityBackend is! EntityRemoteSnapshotStore) {
      return false;
    }
    final manifest = await entityBackend.fetch(
      FirebaseAppStoreSyncService._manifestPath(userId),
    );
    return manifest?['schemaVersion'] == 2 && manifest?['committed'] == true;
  }

  Stream<RemoteSnapshot> watchUserState(String userId) {
    final entityBackend = backend;
    if (entityBackend is! EntityRemoteSnapshotStore) {
      return const Stream<RemoteSnapshot>.empty();
    }
    return Stream<RemoteSnapshot>.multi((controller) {
      final subscriptions = <StreamSubscription<List<RemoteEntityRecord>>>[];
      final initializedCollections = <String>{};
      for (final collection in PersistedEntityBundle.collections) {
        subscriptions.add(
          entityBackend.watchCollection('users/$userId/$collection').listen((
            records,
          ) {
            final documents = _entityDocuments.putIfAbsent(
              userId,
              () => <String, RemoteEntityRecord>{},
            );
            final prefix = 'users/$userId/$collection/';
            documents.removeWhere((path, _) => path.startsWith(prefix));
            for (final record in records) {
              documents[record.path] = record;
            }
            initializedCollections.add(collection);
            if (initializedCollections.length !=
                PersistedEntityBundle.collections.length) {
              return;
            }
            try {
              controller.add(_decodeEntityRecords(userId, documents.values));
            } catch (error, stackTrace) {
              controller.addError(error, stackTrace);
            }
          }, onError: controller.addError),
        );
      }
      controller.onCancel = () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Future<bool> activeWorkoutLeaseIsOwnedByThisDevice(
    RemoteSnapshot snapshot,
  ) async {
    if (snapshot.state.activeWorkoutSession == null ||
        snapshot.activeWorkoutLeaseOwnerId == null) {
      return true;
    }
    final writerId = await _writerIdStore.loadOrCreate();
    return snapshot.activeWorkoutLeaseOwnerId == writerId;
  }

  Future<bool> claimActiveWorkoutLease(
    String userId, {
    required bool force,
  }) async {
    final entityBackend = backend;
    if (entityBackend is! EntityRemoteSnapshotStore) {
      return true;
    }
    final writerId = await _writerIdStore.loadOrCreate();
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 4));
    final claimed = await entityBackend.claimActiveWorkoutLease(
      'users/$userId/runtime/activeWorkout',
      writerId: writerId,
      expiresAt: expiresAt,
      force: force,
    );
    if (claimed) {
      _activeLeaseOwners[userId] = writerId;
      _activeLeaseExpirations[userId] = expiresAt;
    }
    return claimed;
  }
}
