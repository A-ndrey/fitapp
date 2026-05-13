import 'package:cloud_firestore/cloud_firestore.dart';

import '../persistence/persisted_app_state.dart';
import '../persistence/persisted_app_state_codec.dart';
import 'remote_snapshot.dart';

class FirebaseAppStoreSyncService {
  FirebaseAppStoreSyncService({
    FirebaseFirestore? firestore,
    RemoteSnapshotStore? backend,
    Set<String> knownExerciseIds = const {},
  }) : backend =
           backend ??
           FirestoreRemoteSnapshotStore(
             firestore ?? FirebaseFirestore.instance,
           ),
       knownExerciseIds = Set.unmodifiable(knownExerciseIds);

  static const int schemaVersion = 1;

  final RemoteSnapshotStore backend;
  final Set<String> knownExerciseIds;

  Future<RemoteSnapshot?> fetch(String installationId) async {
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

  static String _documentPath(String installationId) =>
      'installations/$installationId/state/current';

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
    );
  }

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
}

class FirestoreRemoteSnapshotStore implements RemoteSnapshotStore {
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
}
