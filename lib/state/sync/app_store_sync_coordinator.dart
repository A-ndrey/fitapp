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
import 'persisted_entity_bundle.dart';
import 'remote_snapshot.dart';

typedef LocalSnapshotLoader = Future<PersistedAppState?> Function();
typedef RemoteSnapshotApplier =
    Future<void> Function(
      PersistedAppState state, {
      required bool notifyPersistedStateObserver,
    });
typedef PersistedStateObserverBinder =
    void Function(void Function(PersistedAppState state) observer);
typedef UserIdProvider = Future<String?> Function();

class AppStoreSyncCoordinator extends ChangeNotifier {
  AppStoreSyncCoordinator({
    InstallationIdStore? installationIdStore,
    UserIdProvider? userIdProvider,
    SharedPreferencesSyncMetadataStore? metadataStore,
    FirebaseAppStoreSyncService? syncService,
    PersistedStateObserverBinder? bindPersistedStateObserver,
    required LocalSnapshotLoader loadLocalSnapshot,
    required RemoteSnapshotApplier applyRemoteSnapshot,
  }) : _installationIdStore = installationIdStore,
       _userIdProvider = userIdProvider,
       _metadataStore = metadataStore ?? SharedPreferencesSyncMetadataStore(),
       _syncService = syncService ?? FirebaseAppStoreSyncService(),
       _loadLocalSnapshot = loadLocalSnapshot,
       _applyRemoteSnapshot = applyRemoteSnapshot {
    bindPersistedStateObserver?.call(persistedStateObserver);
  }

  final InstallationIdStore? _installationIdStore;
  final UserIdProvider? _userIdProvider;
  final SharedPreferencesSyncMetadataStore _metadataStore;
  final FirebaseAppStoreSyncService _syncService;
  final LocalSnapshotLoader _loadLocalSnapshot;
  final RemoteSnapshotApplier _applyRemoteSnapshot;

  AppStoreSyncStatus _status = const AppStoreSyncStatus();
  String? _installationId;
  SyncMetadata? _metadata;
  Future<void>? _startupFuture;
  Future<void> _syncOperationTail = Future<void>.value();
  PersistedAppState? _pendingUploadSnapshot;
  Completer<void>? _uploadDrainCompleter;
  bool _isUploadDrainScheduled = false;
  bool _isStopped = false;
  StreamSubscription<RemoteSnapshot>? _remoteSubscription;
  bool _isStartingRemoteWatch = false;
  RemoteSnapshot? _pendingRemoteSnapshot;
  Timer? _remoteRefreshDebounce;
  Timer? _leaseHeartbeat;
  bool _isActiveWorkoutReadOnly = false;

  AppStoreSyncStatus get status => _status;
  bool get isActiveWorkoutReadOnly => _isActiveWorkoutReadOnly;
  void Function(PersistedAppState) get persistedStateObserver =>
      _handlePersistedStateSaved;

  Future<void> start() {
    if (_isStopped) {
      return Future<void>.value();
    }
    return _startupFuture ??= _runSerialized(
      _runStartupReconciliation,
    ).then((_) => _startRemoteWatch());
  }

  void _handlePersistedStateSaved(PersistedAppState state) {
    if (_isStopped) {
      return;
    }
    _pendingUploadSnapshot = state;
    unawaited(_scheduleUploadDrain());
  }

  Future<void> syncNow() async {
    if (_isStopped) {
      return;
    }
    try {
      final snapshot = await _loadSnapshotOrEmpty();
      if (_isStopped) {
        return;
      }
      _pendingUploadSnapshot = snapshot;
      await _scheduleUploadDrain();
      await _startRemoteWatch();
    } catch (error, stackTrace) {
      await _handleSyncFailure(error, stackTrace);
    }
  }

  Future<void> stop() async {
    _isStopped = true;
    _pendingUploadSnapshot = null;
    _pendingRemoteSnapshot = null;
    _remoteRefreshDebounce?.cancel();
    _leaseHeartbeat?.cancel();
    await _remoteSubscription?.cancel();
    await _syncOperationTail.catchError((Object _, StackTrace _) {});
  }

  Future<void> _runStartupReconciliation() async {
    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.syncing,
        lastErrorMessage: null,
      ),
    );

    try {
      final didInitialize = await _ensureInitialized();
      if (_isStopped) {
        return;
      }
      if (!didInitialize) {
        _setStatus(const AppStoreSyncStatus());
        return;
      }
      final localSnapshot = await _loadSnapshotOrEmpty();
      if (_isStopped) {
        return;
      }
      final remoteSnapshot = await _syncService.fetch(_installationId!);
      if (_isStopped) {
        return;
      }

      if (remoteSnapshot == null) {
        await _pushSnapshot(
          _takePendingUploadSnapshot(localSnapshot),
          force: true,
        );
        return;
      }

      if (_syncService.usesEntityStorage) {
        await _reconcileEntityState(localSnapshot, remoteSnapshot);
        return;
      }

      final localSnapshotHash = _snapshotHash(localSnapshot);
      final lastSyncedSnapshotHash = _metadata?.lastSyncedSnapshotHash;
      final acceptedRemoteTimestamp = _metadata?.lastKnownRemoteUpdatedAt;
      final localIsBlank =
          localSnapshotHash == _snapshotHash(const PersistedAppState.empty());

      if (_isStopped) {
        return;
      }
      if (remoteSnapshot.snapshotHash == localSnapshotHash) {
        await _persistSyncMetadata(
          lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
          lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
          lastSyncError: null,
        );
        if (_isStopped) {
          return;
        }
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
          (lastSyncedSnapshotHash == null
              ? !localIsBlank
              : lastSyncedSnapshotHash != localSnapshotHash);
      final remoteIsNewerThanAccepted =
          acceptedRemoteTimestamp == null ||
          remoteSnapshot.updatedAt.isAfter(acceptedRemoteTimestamp);

      if (remoteIsNewerThanAccepted && !localHasUnsyncedChanges) {
        if (_isStopped) {
          return;
        }
        await _applyRemoteSnapshot(
          remoteSnapshot.state,
          notifyPersistedStateObserver: false,
        );
        if (_isStopped) {
          return;
        }
        await _persistSyncMetadata(
          lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
          lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
          lastSyncError: null,
        );
        if (_isStopped) {
          return;
        }
        _setStatus(
          _status.copyWith(
            phase: AppStoreSyncPhase.synced,
            lastSyncedAt: remoteSnapshot.updatedAt,
            lastErrorMessage: null,
          ),
        );
        return;
      }

      if (_isStopped) {
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

  Future<void> _reconcileEntityState(
    PersistedAppState localSnapshot,
    RemoteSnapshot remoteSnapshot,
  ) async {
    final ownsActiveWorkoutLease = await _updateActiveWorkoutLeaseState(
      remoteSnapshot,
    );
    final localHash = _snapshotHash(localSnapshot);
    final localIsBlank =
        localHash == _snapshotHash(const PersistedAppState.empty());
    final localHasUnsyncedChanges =
        _pendingUploadSnapshot != null ||
        (_metadata?.lastSyncedSnapshotHash == null
            ? !localIsBlank
            : _metadata!.lastSyncedSnapshotHash != localHash);
    final localEntityHashes = PersistedEntityBundle.hashes(localSnapshot);
    final localDeletedKeys = localHasUnsyncedChanges
        ? _metadata?.lastSyncedEntityHashes.keys
                  .where(
                    (key) =>
                        !localEntityHashes.containsKey(key) &&
                        _metadata!.lastSyncedEntityHashes[key] != 'deleted',
                  )
                  .toSet() ??
              const <String>{}
        : const <String>{};
    final preferRemote =
        remoteSnapshot.isLegacy ||
        !localHasUnsyncedChanges ||
        _metadata?.lastSyncedSnapshotHash == null;
    final mergedPreferences = PersistedEntityBundle.mergePreferences(
      localSnapshot.preferences,
      remoteSnapshot.state.preferences,
      previouslySyncedHashes:
          _metadata?.lastSyncedPreferenceGroupHashes ?? const {},
      preferRemote: preferRemote,
    );
    final merged = PersistedEntityBundle.merge(
      localSnapshot,
      remoteSnapshot.state,
      preferRemote: preferRemote,
      preferRemoteActiveWorkout: !ownsActiveWorkoutLease,
      remoteEntityHashes: remoteSnapshot.entityHashes,
      localDeletedKeys: localDeletedKeys,
      mergedPreferences: mergedPreferences,
    );
    final mergedHash = _snapshotHash(merged);

    if (mergedHash != localHash) {
      await _applyRemoteSnapshot(merged, notifyPersistedStateObserver: false);
    }
    if (_isStopped) {
      return;
    }
    if (remoteSnapshot.isLegacy || mergedHash != remoteSnapshot.snapshotHash) {
      await _pushSnapshot(merged, force: true);
      return;
    }
    await _persistSyncMetadata(
      lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
      lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
      lastSyncError: null,
      entityHashes: remoteSnapshot.entityHashes,
      preferenceGroupHashes: PersistedEntityBundle.preferenceGroupHashes(
        merged.preferences,
      ),
    );
    _setStatus(
      _status.copyWith(
        phase: AppStoreSyncPhase.synced,
        lastSyncedAt: remoteSnapshot.updatedAt,
        lastErrorMessage: null,
      ),
    );
  }

  Future<void> _startRemoteWatch() async {
    if (_isStopped ||
        !_syncService.usesEntityStorage ||
        _installationId == null ||
        _remoteSubscription != null ||
        _isStartingRemoteWatch) {
      return;
    }
    _isStartingRemoteWatch = true;
    try {
      final hasCommittedEntityState = await _syncService
          .hasCommittedEntityState(_installationId!);
      if (_isStopped || !hasCommittedEntityState) {
        return;
      }
      _remoteSubscription = _syncService
          .watchUserState(_installationId!)
          .listen(
            (snapshot) {
              _pendingRemoteSnapshot = snapshot;
              _remoteRefreshDebounce?.cancel();
              _remoteRefreshDebounce = Timer(
                const Duration(milliseconds: 250),
                () => unawaited(_runSerialized(_applyWatchedRemoteSnapshot)),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              unawaited(_handleSyncFailure(error, stackTrace));
            },
          );
      _leaseHeartbeat ??= Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(_renewActiveWorkoutLease()),
      );
    } catch (error, stackTrace) {
      await _handleSyncFailure(error, stackTrace);
    } finally {
      _isStartingRemoteWatch = false;
    }
  }

  Future<bool> takeOverActiveWorkout() async {
    if (_isStopped ||
        !_syncService.usesEntityStorage ||
        _installationId == null) {
      return false;
    }
    final claimed = await _syncService.claimActiveWorkoutLease(
      _installationId!,
      force: true,
    );
    if (claimed) {
      _setActiveWorkoutReadOnly(false);
      await syncNow();
    }
    return claimed;
  }

  Future<void> _renewActiveWorkoutLease() async {
    if (_isStopped || _installationId == null || _isActiveWorkoutReadOnly) {
      return;
    }
    final local = await _loadSnapshotOrEmpty();
    if (local.activeWorkoutSession == null) {
      return;
    }
    final claimed = await _syncService.claimActiveWorkoutLease(
      _installationId!,
      force: false,
    );
    if (!claimed) {
      _setActiveWorkoutReadOnly(true);
    }
  }

  Future<bool> _updateActiveWorkoutLeaseState(RemoteSnapshot snapshot) async {
    if (snapshot.state.activeWorkoutSession == null) {
      _setActiveWorkoutReadOnly(false);
      return true;
    }
    final ownsLease = await _syncService.activeWorkoutLeaseIsOwnedByThisDevice(
      snapshot,
    );
    _setActiveWorkoutReadOnly(!ownsLease);
    return ownsLease;
  }

  void _setActiveWorkoutReadOnly(bool value) {
    if (_isActiveWorkoutReadOnly == value) {
      return;
    }
    _isActiveWorkoutReadOnly = value;
    notifyListeners();
  }

  Future<void> _applyWatchedRemoteSnapshot() async {
    if (_isStopped) {
      return;
    }
    try {
      final remote = _pendingRemoteSnapshot;
      _pendingRemoteSnapshot = null;
      if (remote == null || remote.isLegacy || _isStopped) {
        return;
      }
      final local = await _loadSnapshotOrEmpty();
      await _reconcileEntityState(local, remote);
    } catch (error, stackTrace) {
      await _handleSyncFailure(error, stackTrace);
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_installationId != null) {
      return true;
    }

    final installationId = await _loadIdentityId();
    if (installationId == null) {
      return false;
    }

    final loadedMetadata = await loadSyncMetadataFor(
      _metadataStore,
      installationId,
    );

    _installationId = installationId;
    if (loadedMetadata != null &&
        loadedMetadata.installationId == installationId) {
      _metadata = loadedMetadata;
      return true;
    }

    _metadata = SyncMetadata(installationId: installationId);
    return true;
  }

  Future<String?> _loadIdentityId() async {
    final userIdProvider = _userIdProvider;
    if (userIdProvider != null) {
      return userIdProvider();
    }

    return (_installationIdStore ?? InstallationIdStore()).loadOrCreate();
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
    if (_isStopped) {
      return;
    }
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
      if (_isStopped) {
        _pendingUploadSnapshot = null;
        return;
      }
      final didInitialize = await _ensureInitialized();
      if (_isStopped || !didInitialize) {
        _pendingUploadSnapshot = null;
        _setStatus(const AppStoreSyncStatus());
        return;
      }
      while (!_isStopped && _pendingUploadSnapshot != null) {
        final snapshot = _pendingUploadSnapshot!;
        _pendingUploadSnapshot = null;
        await _pushSnapshot(snapshot);
      }
    } catch (error, stackTrace) {
      _pendingUploadSnapshot = null;
      await _handleSyncFailure(error, stackTrace);
    } finally {
      final shouldReschedule = !_isStopped && _pendingUploadSnapshot != null;
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
    if (_isStopped) {
      return;
    }
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

    if (_isStopped) {
      return;
    }
    final remoteSnapshot = await _syncService.push(
      _installationId!,
      snapshot,
      snapshotHash,
    );
    if (_isStopped) {
      return;
    }
    if (_syncService.usesEntityStorage) {
      await _updateActiveWorkoutLeaseState(remoteSnapshot);
    }
    await _persistSyncMetadata(
      lastKnownRemoteUpdatedAt: remoteSnapshot.updatedAt,
      lastSyncedSnapshotHash: remoteSnapshot.snapshotHash,
      lastSyncError: null,
      entityHashes: remoteSnapshot.entityHashes,
      preferenceGroupHashes: PersistedEntityBundle.preferenceGroupHashes(
        remoteSnapshot.state.preferences,
      ),
    );
    if (_isStopped) {
      return;
    }
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
    Map<String, String>? entityHashes,
    Map<String, String>? preferenceGroupHashes,
  }) async {
    final metadata = SyncMetadata(
      installationId: _installationId!,
      lastKnownRemoteUpdatedAt: lastKnownRemoteUpdatedAt,
      lastSyncedSnapshotHash: lastSyncedSnapshotHash,
      lastSyncError: lastSyncError,
      lastSyncedEntityHashes:
          entityHashes ??
          _metadata?.lastSyncedEntityHashes ??
          const <String, String>{},
      lastSyncedPreferenceGroupHashes:
          preferenceGroupHashes ??
          _metadata?.lastSyncedPreferenceGroupHashes ??
          const <String, String>{},
    );
    await saveSyncMetadataFor(_metadataStore, metadata);
    _metadata = metadata;
  }

  Future<void> _handleSyncFailure(Object error, StackTrace stackTrace) async {
    if (_isStopped) {
      return;
    }
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

  String _snapshotHash(PersistedAppState state) {
    if (_syncService.usesEntityStorage) {
      return PersistedEntityBundle.snapshotHash(state);
    }
    final bytes = utf8.encode(jsonEncode(PersistedAppStateCodec.encode(state)));
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
