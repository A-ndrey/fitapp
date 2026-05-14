import 'package:fitapp/main.dart';
import 'package:fitapp/models/app_preferences.dart';
import 'package:fitapp/screens/more_screen.dart';
import 'package:fitapp/state/app_store.dart';
import 'package:fitapp/state/sync/app_store_sync_coordinator.dart';
import 'package:fitapp/state/sync/firebase_app_store_sync_service.dart';
import 'package:fitapp/state/sync/app_store_sync_status.dart';
import 'package:fitapp/ui/core/layout/adaptive_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSyncCoordinator extends AppStoreSyncCoordinator {
  _TestSyncCoordinator({AppStoreSyncStatus status = const AppStoreSyncStatus()})
    : _status = status,
      super(
        syncService: FirebaseAppStoreSyncService(
          backend: _NoopRemoteSnapshotStore(),
        ),
        loadLocalSnapshot: () async => null,
        applyRemoteSnapshot:
            (_, {required notifyPersistedStateObserver}) async {},
      );

  AppStoreSyncStatus _status;

  @override
  AppStoreSyncStatus get status => _status;

  void setStatus(AppStoreSyncStatus nextStatus) {
    _status = nextStatus;
    notifyListeners();
  }
}

class _NoopRemoteSnapshotStore implements RemoteSnapshotStore {
  @override
  Future<Map<String, Object?>?> fetch(String path) async => null;

  @override
  Future<void> set(String path, Map<String, Object?> data) async {}
}

class _TrackingSyncAccess extends FitAppSyncAccess {
  int syncNowCallCount = 0;

  @override
  Future<void> syncNow() async {
    syncNowCallCount += 1;
  }
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AppStore store, {
    FitAppSyncAccess? syncAccess,
    Size? size,
  }) async {
    if (size != null) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }
    await tester.pumpWidget(
      MaterialApp(
        home: MoreScreen(
          store: store,
          syncStatusListenable: syncAccess,
          readSyncStatus: () => syncAccess?.status,
          onSyncNow: syncAccess?.syncNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings screen uses redesigned settings surface', (
    tester,
  ) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    expect(find.byType(AdaptivePage), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text('Tune units, appearance, and training-log preferences.'),
      findsOneWidget,
    );
    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('App'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(
      find.text('Sync is ready. Tap below to check for updates.'),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('more screen renders sync error status and retries', (
    tester,
  ) async {
    final syncAccess = _TrackingSyncAccess()
      ..reportError(StateError('Sync failed while reaching the server.'));
    addTearDown(syncAccess.dispose);

    await pumpScreen(tester, AppStore(), syncAccess: syncAccess);

    expect(
      find.text(
        'Sync error: Bad state: Sync failed while reaching the server.',
      ),
      findsOneWidget,
    );
    expect(find.text('Login'), findsNothing);
    expect(find.text('Logout'), findsNothing);

    await tester.tap(find.text('Sync now'));
    await tester.pumpAndSettle();

    expect(syncAccess.syncNowCallCount, 1);
  });

  testWidgets('more screen reflects coordinator sync status updates', (
    tester,
  ) async {
    final syncAccess = FitAppSyncAccess();
    final coordinator = _TestSyncCoordinator();
    addTearDown(syncAccess.dispose);
    addTearDown(coordinator.dispose);

    syncAccess.bindCoordinator(coordinator);
    await pumpScreen(tester, AppStore(), syncAccess: syncAccess);

    expect(
      find.text('Sync is ready. Tap below to check for updates.'),
      findsOneWidget,
    );

    coordinator.setStatus(
      const AppStoreSyncStatus(phase: AppStoreSyncPhase.syncing),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Sync in progress. We will keep your data up to date.'),
      findsOneWidget,
    );
  });

  testWidgets('more screen preference chips update store', (tester) async {
    final store = AppStore();

    await pumpScreen(tester, store);

    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();

    expect(store.preferences.workoutWeightUnit, WorkoutWeightUnit.pounds);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('more screen stacks preference cards below medium layout', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(390, 844));

    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));
    final cardWidth = tester
        .getSize(
          find.ancestor(
            of: find.text('Workout weight'),
            matching: find.byType(Card),
          ),
        )
        .width;

    expect(dishTopLeft.dy, greaterThan(workoutTopLeft.dy));
    expect((dishTopLeft.dx - workoutTopLeft.dx).abs(), lessThan(1));
    expect(cardWidth, greaterThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('more screen places preference cards in two columns when wide', (
    tester,
  ) async {
    await pumpScreen(tester, AppStore(), size: const Size(900, 900));

    final workoutTopLeft = tester.getTopLeft(find.text('Workout weight'));
    final dishTopLeft = tester.getTopLeft(find.text('Dish weight'));

    expect((dishTopLeft.dy - workoutTopLeft.dy).abs(), lessThan(1));
    expect(dishTopLeft.dx, greaterThan(workoutTopLeft.dx));
    expect(tester.takeException(), isNull);
  });
}
