import 'package:flutter/foundation.dart';

enum AppStoreSyncConflictReason { differentAccount, unownedLocalAndRemoteData }

@immutable
class AppStoreSyncConflict {
  const AppStoreSyncConflict({required this.reason});

  final AppStoreSyncConflictReason reason;
}
