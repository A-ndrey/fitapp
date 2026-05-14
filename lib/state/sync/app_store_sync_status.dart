import 'package:flutter/foundation.dart';

enum AppStoreSyncPhase { idle, syncing, synced, error }

@immutable
class AppStoreSyncStatus {
  const AppStoreSyncStatus({
    this.phase = AppStoreSyncPhase.idle,
    this.lastSyncedAt,
    this.lastErrorMessage,
  });

  final AppStoreSyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? lastErrorMessage;

  AppStoreSyncStatus copyWith({
    AppStoreSyncPhase? phase,
    Object? lastSyncedAt = _noChange,
    Object? lastErrorMessage = _noChange,
  }) {
    return AppStoreSyncStatus(
      phase: phase ?? this.phase,
      lastSyncedAt: identical(lastSyncedAt, _noChange)
          ? this.lastSyncedAt
          : lastSyncedAt as DateTime?,
      lastErrorMessage: identical(lastErrorMessage, _noChange)
          ? this.lastErrorMessage
          : lastErrorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppStoreSyncStatus &&
        other.phase == phase &&
        other.lastSyncedAt == lastSyncedAt &&
        other.lastErrorMessage == lastErrorMessage;
  }

  @override
  int get hashCode => Object.hash(phase, lastSyncedAt, lastErrorMessage);

  @override
  String toString() {
    return 'AppStoreSyncStatus('
        'phase: $phase, '
        'lastSyncedAt: $lastSyncedAt, '
        'lastErrorMessage: $lastErrorMessage'
        ')';
  }
}

const Object _noChange = Object();
