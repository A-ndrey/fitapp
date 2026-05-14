import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../persistence/persisted_app_state.dart';
import '../persistence/persisted_app_state_codec.dart';
import '../persistence/shared_preferences_sync_metadata_store.dart';
import '../persistence/sync_metadata.dart';
import 'app_store_sync_status.dart';
import 'firebase_app_store_sync_service.dart';
import 'installation_id_store.dart';

typedef LocalSnapshotLoader = Future<PersistedAppState?> Function();
typedef RemoteSnapshotApplier =
    Future<void> Function(
      PersistedAppState state, {
      required bool notifyPersistedStateObserver,
    });
typedef PersistedStateObserverBinder =
    void Function(void Function(PersistedAppState state) observer);

class AppStoreSyncCoordinator extends ChangeNotifier {
  AppStoreSyncCoordinator({
    InstallationIdStore? installationIdStore,
    SharedPreferencesSyncMetadataStore? metadataStore,
    FirebaseAppStoreSyncService? syncService,
    PersistedStateObserverBinder? bindPersistedStateObserver,
    required LocalSnapshotLoader loadLocalSnapshot,
    required RemoteSnapshotApplier applyRemoteSnapshot,
  }) : _installationIdStore = installationIdStore ?? InstallationIdStore(),
       _metadataStore = metadataStore ?? SharedPreferencesSyncMetadataStore(),
       _syncService = syncService ?? FirebaseAppStoreSyncService(),
       _loadLocalSnapshot = loadLocalSnapshot,
       _applyRemoteSnapshot = applyRemoteSnapshot {
    bindPersistedStateObserver?.call(persistedStateObserver);
  }

  final InstallationIdStore _installationIdStore;
  final SharedPreferencesSyncMetadataStore _metadataStore;
  final FirebaseAppStoreSyncService _syncService;
  final LocalSnapshotLoader _loadLocalSnapshot;
  final RemoteSnapshotApplier _applyRemoteSnapshot;

  AppStoreSyncStatus _status = const AppStoreSyncStatus();
  String? _installationId;
  SyncMetadata? _metadata;
  Future<void>? _initializationFuture;
  Future<void>? _startupFuture;
  Future<void> _syncOperationTail = Future<void>.value();
  PersistedAppState? _pendingUploadSnapshot;
  Completer<void>? _uploadDrainCompleter;
  bool _isUploadDrainScheduled = false;

  AppStoreSyncStatus get status => _status;
  void Function(PersistedAppState) get persistedStateObserver =>
      _handlePersistedStateSaved;

  Future<void> start() {
    return _startupFuture ??= _runSerialized(_runStartupReconciliation);
  }

  void _handlePersistedStateSaved(PersistedAppState state) {
    _pendingUploadSnapshot = state;
    unawaited(_scheduleUploadDrain());
  }

  Future<void> syncNow() async {
    try {
      final snapshot = await _loadSnapshotOrEmpty();
      _pendingUploadSnapshot = snapshot;
      await _scheduleUploadDrain();
    } catch (error, stackTrace) {
      await _handleSyncFailure(error, stackTrace);
    }
  }

  Future<void> _runStartupReconciliation() async {
    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.syncing,
        lastErrorMessage: null,
      ),
    );

    try {
      await _ensureInitialized();
      final localSnapshot = await _loadSnapshotOrEmpty();
      final remoteSnapshot = await _syncService.fetch(_installationId!);

      if (remoteSnapshot == null) {
        await _pushSnapshot(
          _takePendingUploadSnapshot(localSnapshot),
          force: true,
        );
        return;
      }

      final localSnapshotHash = _snapshotHash(localSnapshot);
      final lastSyncedSnapshotHash = _metadata?.lastSyncedSnapshotHash;
      final acceptedRemoteTimestamp = _metadata?.lastKnownRemoteUpdatedAt;

      if (remoteSnapshot.snapshotHash == localSnapshotHash) {
        await _persistSyncMetadata(
          lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
          lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
          lastSyncError: null,
        );
        _setStatus(
          _status.copyWith(
            phase: AppStoreSyncPhase.synced,
            lastSyncedAt: remoteSnapshot.updatedAt,
            lastErrorMessage: null,
          ),
        );
        return;
      }

      final localHasUnsyncedChanges =
          _pendingUploadSnapshot != null ||
          lastSyncedSnapshotHash == null ||
          lastSyncedSnapshotHash != localSnapshotHash;
      final remoteIsNewerThanAccepted =
          acceptedRemoteTimestamp != null &&
          remoteSnapshot.updatedAt.isAfter(acceptedRemoteTimestamp);

      if (remoteIsNewerThanAccepted && !localHasUnsyncedChanges) {
        await _applyRemoteSnapshot(
          remoteSnapshot.state,
          notifyPersistedStateObserver: false,
        );
        await _persistSyncMetadata(
          lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
          lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
          lastSyncError: null,
        );
        _setStatus(
          _status.copyWith(
            phase: AppStoreSyncPhase.synced,
            lastSyncedAt: remoteSnapshot.updatedAt,
            lastErrorMessage: null,
          ),
        );
        return;
      }

      await _pushSnapshot(
        _takePendingUploadSnapshot(localSnapshot),
        force: true,
      );
    } catch (error, stackTrace) {
      await _handleSyncFailure(error, stackTrace);
    }
  }

  Future<void> _ensureInitialized() {
    return _initializationFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    final installationId = await _installationIdStore.loadOrCreate();
    final loadedMetadata = await _metadataStore.load();

    _installationId = installationId;
    if (loadedMetadata != null &&
        loadedMetadata.installationId == installationId) {
      _metadata = loadedMetadata;
      return;
    }

    _metadata = SyncMetadata(installationId: installationId);
  }

  Future<PersistedAppState> _loadSnapshotOrEmpty() async {
    return await _loadLocalSnapshot() ?? const PersistedAppState.empty();
  }

  PersistedAppState _takePendingUploadSnapshot(PersistedAppState fallback) {
    final pendingSnapshot = _pendingUploadSnapshot;
    if (pendingSnapshot == null) {
      return fallback;
    }
    _pendingUploadSnapshot = null;
    return pendingSnapshot;
  }

  Future<void> _scheduleUploadDrain() async {
    _uploadDrainCompleter ??= Completer<void>();
    if (_isUploadDrainScheduled) {
      await _uploadDrainCompleter!.future;
      return;
    }

    _isUploadDrainScheduled = true;
    unawaited(_runSerialized(_drainUploadQueue));
    await _uploadDrainCompleter!.future;
  }

  Future<void> _drainUploadQueue() async {
    try {
      await _ensureInitialized();
      while (_pendingUploadSnapshot != null) {
        final snapshot = _pendingUploadSnapshot!;
        _pendingUploadSnapshot = null;
        await _pushSnapshot(snapshot);
      }
    } catch (error, stackTrace) {
      _pendingUploadSnapshot = null;
      await _handleSyncFailure(error, stackTrace);
    } finally {
      final shouldReschedule = _pendingUploadSnapshot != null;
      _isUploadDrainScheduled = false;
      _uploadDrainCompleter?.complete();
      _uploadDrainCompleter = null;
      if (shouldReschedule) {
        unawaited(_scheduleUploadDrain());
      }
    }
  }

  Future<void> _runSerialized(Future<void> Function() operation) {
    final scheduled = _syncOperationTail
        .catchError((Object _, StackTrace _) {})
        .then((_) => operation());
    _syncOperationTail = scheduled.catchError((Object _, StackTrace _) {});
    return scheduled;
  }

  Future<void> _pushSnapshot(
    PersistedAppState snapshot, {
    bool force = false,
  }) async {
    final snapshotHash = _snapshotHash(snapshot);
    if (!force && _metadata?.lastSyncedSnapshotHash == snapshotHash) {
      _setStatus(
        _status.copyWith(
          phase: AppStoreSyncPhase.synced,
          lastErrorMessage: null,
        ),
      );
      return;
    }

    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.syncing,
        lastErrorMessage: null,
      ),
    );

    final remoteSnapshot = await _syncService.push(
      _installationId!,
      snapshot,
      snapshotHash,
    );
    await _persistSyncMetadata(
      lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
      lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
      lastSyncError: null,
    );
    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.synced,
        lastSyncedAt: remoteSnapshot.updatedAt,
        lastErrorMessage: null,
      ),
    );
  }

  Future<void> _persistSyncMetadata({
    required DateTime? lastKnownRemoteUpdatedAt,
    required String? lastSyncedSnapshotHash,
    required String? lastSyncError,
  }) async {
    final metadata = SyncMetadata(
      installationId: _installationId!,
      lastKnownRemoteUpdatedAt: lastKnownRemoteUpdatedAt,
      lastSyncedSnapshotHash: lastSyncedSnapshotHash,
      lastSyncError: lastSyncError,
    );
    await _metadataStore.save(metadata);
    _metadata = metadata;
  }

  Future<void> _handleSyncFailure(Object error, StackTrace stackTrace) async {
    final errorMessage = error.toString();

    if (_installationId != null) {
      try {
        await _persistSyncMetadata(
          lastKnownRemoteUpdatedAt: _metadata?.lastKnownRemoteUpdatedAt,
          lastSyncedSnapshotHash: _metadata?.lastSyncedSnapshotHash,
          lastSyncError: errorMessage,
        );
      } catch (_) {
        // Keep the app usable even if sync metadata persistence also fails.
      }
    }

    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.error,
        lastErrorMessage: errorMessage,
      ),
    );

    try {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'fitapp',
          context: ErrorDescription('while syncing AppStore state'),
        ),
      );
    } catch (_) {
      // Error reporting must not surface as an additional sync failure.
    }
  }

  void _setStatus(AppStoreSyncStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }

    _status = nextStatus;
    notifyListeners();
  }

  static String _snapshotHash(PersistedAppState state) {
    final bytes = utf8.encode(jsonEncode(PersistedAppStateCodec.encode(state)));
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
