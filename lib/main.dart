import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase/firebase_initializer.dart';
import 'l10n/app_localizations.dart';
import 'models/app_preferences.dart';
import 'screens/library_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/more_screen.dart';
import 'screens/today_screen.dart';
import 'screens/workout_screen.dart';
import 'state/app_store.dart';
import 'state/auth/app_auth_service.dart';
import 'state/auth/firebase_app_auth_service.dart';
import 'state/persistence/app_store_persistence.dart';
import 'state/persistence/persisted_app_state.dart';
import 'state/persistence/shared_preferences_app_store_persistence.dart';
import 'state/persistence/shared_preferences_sync_metadata_store.dart';
import 'ui/core/layout/app_breakpoints.dart';
import 'ui/core/theme/app_theme.dart';
import 'state/sync/app_store_sync_coordinator.dart';
import 'state/sync/app_store_sync_status.dart';
import 'state/sync/firebase_app_store_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startup = await prepareFitAppStartup();
  await launchFitApp(startup: startup);
}

typedef AppRunner = FutureOr<void> Function(Widget app);
typedef AppStorePersistenceFactory =
    AppStorePersistence Function(Set<String> knownExerciseIds);
typedef AppStoreHydrator =
    Future<AppStore> Function({
      required AppStorePersistence persistence,
      required PersistedAppStateObserver onPersistedStateSaved,
    });
typedef SyncMetadataStoreFactory =
    SharedPreferencesSyncMetadataStore Function();
typedef SyncServiceFactory =
    FirebaseAppStoreSyncService Function(Set<String> knownExerciseIds);
typedef AuthServiceFactory =
    AppAuthService Function(FirebaseInitializer firebaseInitializer);
typedef SyncCoordinatorFactory =
    AppStoreSyncCoordinator Function({
      required SharedPreferencesSyncMetadataStore metadataStore,
      required FirebaseAppStoreSyncService syncService,
      required UserIdProvider userIdProvider,
      required PersistedStateObserverBinder bindPersistedStateObserver,
      required LocalSnapshotLoader loadLocalSnapshot,
      required RemoteSnapshotApplier applyRemoteSnapshot,
    });

Future<FitAppStartup> prepareFitAppStartup({
  FirebaseInitializer? firebaseInitializer,
  AppStorePersistenceFactory? appStorePersistenceFactory,
  AppStoreHydrator? appStoreHydrator,
  SyncMetadataStoreFactory? syncMetadataStoreFactory,
  SyncServiceFactory? syncServiceFactory,
  AuthServiceFactory? authServiceFactory,
  SyncCoordinatorFactory? syncCoordinatorFactory,
  FitAppSyncAccess? syncAccess,
}) async {
  final resolvedFirebaseInitializer =
      firebaseInitializer ?? DefaultFirebaseInitializer();
  final bootstrapStore = AppStore();
  final knownExerciseIds = bootstrapStore.exercises
      .map((exercise) => exercise.id)
      .toSet();
  bootstrapStore.dispose();

  final persistence =
      (appStorePersistenceFactory ?? _defaultAppStorePersistenceFactory)(
        knownExerciseIds,
      );
  final persistedStateObserverRelay = _PersistedStateObserverRelay();
  final store = await (appStoreHydrator ?? _defaultAppStoreHydrator)(
    persistence: persistence,
    onPersistedStateSaved: persistedStateObserverRelay.call,
  );

  final authService = (authServiceFactory ?? _defaultAuthServiceFactory)(
    resolvedFirebaseInitializer,
  );
  final startup = FitAppStartup._(
    store: store,
    authService: authService,
    syncAccess: syncAccess ?? FitAppSyncAccess(),
    firebaseInitializer: resolvedFirebaseInitializer,
    persistence: persistence,
    metadataStore:
        (syncMetadataStoreFactory ?? SharedPreferencesSyncMetadataStore.new)(),
    syncServiceFactory: syncServiceFactory ?? _defaultSyncServiceFactory,
    syncCoordinatorFactory:
        syncCoordinatorFactory ?? _defaultSyncCoordinatorFactory,
    persistedStateObserverRelay: persistedStateObserverRelay,
    knownExerciseIds: knownExerciseIds,
  );
  startup.syncAccess._bindStartupRetry(startup.startBackgroundSync);
  authService.addListener(startup.handleAuthStateChanged);
  return startup;
}

Future<void> launchFitApp({
  required FitAppStartup startup,
  AppRunner appRunner = _runApp,
}) async {
  await appRunner(
    FitApp(
      store: startup.store,
      syncAccess: startup.syncAccess,
      authService: startup.authService,
      deleteAccountData: startup.deleteAccountData,
    ),
  );
  unawaited(startup.startBackgroundSync());
}

class FitAppStartup {
  FitAppStartup._({
    required this.store,
    required this.authService,
    required this.syncAccess,
    required FirebaseInitializer firebaseInitializer,
    required AppStorePersistence persistence,
    required SharedPreferencesSyncMetadataStore metadataStore,
    required SyncServiceFactory syncServiceFactory,
    required SyncCoordinatorFactory syncCoordinatorFactory,
    required _PersistedStateObserverRelay persistedStateObserverRelay,
    required Set<String> knownExerciseIds,
  }) : _firebaseInitializer = firebaseInitializer,
       _persistence = persistence,
       _metadataStore = metadataStore,
       _syncServiceFactory = syncServiceFactory,
       _syncCoordinatorFactory = syncCoordinatorFactory,
       _persistedStateObserverRelay = persistedStateObserverRelay,
       _knownExerciseIds = Set.unmodifiable(knownExerciseIds);

  final AppStore store;
  final AppAuthService authService;
  final FitAppSyncAccess syncAccess;
  final FirebaseInitializer _firebaseInitializer;
  final AppStorePersistence _persistence;
  final SharedPreferencesSyncMetadataStore _metadataStore;
  final SyncServiceFactory _syncServiceFactory;
  final SyncCoordinatorFactory _syncCoordinatorFactory;
  final _PersistedStateObserverRelay _persistedStateObserverRelay;
  final Set<String> _knownExerciseIds;

  Future<void>? _backgroundSyncFuture;
  bool _isDeletingAccount = false;
  String? _remoteDeletedUserId;

  Future<void> startBackgroundSync() {
    if (_shouldSuppressSyncForCurrentUser) {
      return Future<void>.value();
    }
    if (syncAccess.coordinator != null) {
      return Future<void>.value();
    }

    return _backgroundSyncFuture ??= _runBackgroundSync().whenComplete(() {
      _backgroundSyncFuture = null;
    });
  }

  Future<void> _runBackgroundSync() async {
    try {
      if (_shouldSuppressSyncForCurrentUser) {
        return;
      }
      final didInitialize = await _firebaseInitializer.initialize();
      if (_shouldSuppressSyncForCurrentUser ||
          !didInitialize ||
          !authService.state.isSignedIn) {
        return;
      }
      if (_shouldSuppressSyncForCurrentUser) {
        return;
      }

      final coordinator = _syncCoordinatorFactory(
        metadataStore: _metadataStore,
        syncService: _syncServiceFactory(_knownExerciseIds),
        userIdProvider: () async => authService.state.uid,
        bindPersistedStateObserver: _persistedStateObserverRelay.bind,
        loadLocalSnapshot: _persistence.load,
        applyRemoteSnapshot:
            (state, {required notifyPersistedStateObserver}) async {
              await store.applyExternalPersistedState(
                state,
                notifyPersistedStateObserver: notifyPersistedStateObserver,
              );
            },
      );
      syncAccess.bindCoordinator(coordinator);
      await coordinator.start();
    } catch (error) {
      if (!_isDeletingAccount) {
        syncAccess.reportError(error);
      }
    }
  }

  Future<void> deleteAccountData({required String password}) async {
    final userId = authService.state.uid;
    if (userId == null) {
      throw const AuthFailure('No account is signed in.');
    }
    await authService.reauthenticate(password: password);

    _isDeletingAccount = true;
    _persistedStateObserverRelay.clear();
    await syncAccess.stopCoordinator();

    try {
      final didInitialize = await _firebaseInitializer.initialize();
      if (!didInitialize) {
        throw const AuthFailure('Firebase Auth is only available on web.');
      }

      await _syncServiceFactory(_knownExerciseIds).deleteUserState(userId);
      _remoteDeletedUserId = userId;
    } catch (_) {
      _isDeletingAccount = false;
      rethrow;
    }

    try {
      await authService.deleteAccount();
      _remoteDeletedUserId = null;
      _isDeletingAccount = false;
    } catch (_) {
      _isDeletingAccount = false;
      rethrow;
    }
  }

  void handleAuthStateChanged() {
    if (authService.state.isSignedIn) {
      if (!_shouldSuppressSyncForCurrentUser) {
        unawaited(startBackgroundSync());
      }
    } else {
      _isDeletingAccount = false;
      unawaited(syncAccess.stopCoordinator());
    }
  }

  bool get _shouldSuppressSyncForCurrentUser {
    final deletedUserId = _remoteDeletedUserId;
    return _isDeletingAccount ||
        (deletedUserId != null && authService.state.uid == deletedUserId);
  }
}

class FitAppSyncAccess extends ChangeNotifier {
  AppStoreSyncCoordinator? get coordinator => _coordinator;
  AppStoreSyncStatus get status => _status;

  AppStoreSyncCoordinator? _coordinator;
  Future<void> Function()? _startupRetry;
  VoidCallback? _coordinatorListener;
  AppStoreSyncStatus _status = const AppStoreSyncStatus();

  Future<void> syncNow() async {
    final coordinator = _coordinator;
    if (coordinator != null) {
      await coordinator.syncNow();
      return;
    }

    final startupRetry = _startupRetry;
    if (startupRetry != null) {
      await startupRetry();
    }
  }

  void bindCoordinator(AppStoreSyncCoordinator coordinator) {
    if (identical(_coordinator, coordinator)) {
      return;
    }

    _detachCoordinator();
    _coordinator = coordinator;
    _coordinatorListener = _handleCoordinatorChanged;
    coordinator.addListener(_coordinatorListener!);
    _setStatus(coordinator.status);
  }

  void clearCoordinator() {
    _detachCoordinator();
    _setStatus(const AppStoreSyncStatus());
  }

  Future<void> stopCoordinator() async {
    final coordinator = _coordinator;
    _detachCoordinator();
    _setStatus(const AppStoreSyncStatus());
    await coordinator?.stop();
  }

  void reportError(Object error) {
    _setStatus(
      AppStoreSyncStatus(
        phase: AppStoreSyncPhase.error,
        lastErrorMessage: error.toString(),
      ),
    );
  }

  void _handleCoordinatorChanged() {
    final coordinator = _coordinator;
    if (coordinator == null) {
      return;
    }

    _setStatus(coordinator.status);
  }

  void _setStatus(AppStoreSyncStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }

    _status = nextStatus;
    notifyListeners();
  }

  void _bindStartupRetry(Future<void> Function() startupRetry) {
    _startupRetry = startupRetry;
  }

  void _detachCoordinator() {
    final coordinator = _coordinator;
    final coordinatorListener = _coordinatorListener;
    if (coordinator != null && coordinatorListener != null) {
      coordinator.removeListener(coordinatorListener);
    }
    _coordinator = null;
    _coordinatorListener = null;
  }

  @override
  void dispose() {
    _detachCoordinator();
    super.dispose();
  }
}

class _PersistedStateObserverRelay {
  void Function(PersistedAppState state)? _observer;

  void call(PersistedAppState state) {
    final observer = _observer;
    if (observer == null) {
      return;
    }

    observer(state);
  }

  void bind(void Function(PersistedAppState state) observer) {
    _observer = observer;
  }

  void clear() {
    _observer = null;
  }
}

class FitApp extends StatefulWidget {
  const FitApp({
    super.key,
    this.store,
    this.syncAccess,
    this.authService,
    this.deleteAccountData,
  });

  final AppStore? store;
  final FitAppSyncAccess? syncAccess;
  final AppAuthService? authService;
  final Future<void> Function({required String password})? deleteAccountData;

  @override
  State<FitApp> createState() => _FitAppState();
}

class _FitAppState extends State<FitApp> {
  late final AppStore _store;
  late final AppAuthService _authService;
  late final bool _ownsStore;
  late final bool _ownsAuthService;

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? AppStore();
    _ownsAuthService = widget.authService == null;
    _authService = widget.authService ?? FirebaseAppAuthService();
  }

  @override
  void dispose() {
    if (_ownsStore) {
      _store.dispose();
    }
    if (_ownsAuthService) {
      final authService = _authService;
      if (authService is ChangeNotifier) {
        (authService as ChangeNotifier).dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: _themeModeFor(_store.appearancePreference),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: FitHome(
            store: _store,
            syncAccess: widget.syncAccess,
            authService: _authService,
            deleteAccountData: widget.deleteAccountData,
          ),
        );
      },
    );
  }
}

ThemeMode _themeModeFor(AppearancePreference preference) {
  return switch (preference) {
    AppearancePreference.system => ThemeMode.system,
    AppearancePreference.light => ThemeMode.light,
    AppearancePreference.dark => ThemeMode.dark,
  };
}

class FitHome extends StatefulWidget {
  const FitHome({
    super.key,
    required this.store,
    required this.authService,
    this.syncAccess,
    this.deleteAccountData,
  });

  final AppStore store;
  final AppAuthService authService;
  final FitAppSyncAccess? syncAccess;
  final Future<void> Function({required String password})? deleteAccountData;

  @override
  State<FitHome> createState() => _FitHomeState();
}

class _FitHomeState extends State<FitHome> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _isWorkoutTabCurrent = ValueNotifier<bool>(false);
  final GlobalKey<NavigatorState> _workoutNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<LibraryScreenState> _libraryScreenKey =
      GlobalKey<LibraryScreenState>();

  @override
  void dispose() {
    _isWorkoutTabCurrent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = <_AppDestination>[
      _AppDestination(
        label: l10n?.destinationToday ?? 'Today',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
        screen: TodayScreen(
          store: widget.store,
          onOpenTrain: () => _selectDestination(1),
          onOpenNutrition: () => _selectDestination(2),
          onOpenLibrary: () => _selectDestination(3),
        ),
      ),
      _AppDestination(
        label: l10n?.destinationTrain ?? 'Train',
        icon: Icons.timer_outlined,
        selectedIcon: Icons.timer,
        screen: _WorkoutTabNavigator(
          navigatorKey: _workoutNavigatorKey,
          store: widget.store,
          isCurrentTabListenable: _isWorkoutTabCurrent,
        ),
      ),
      _AppDestination(
        label: l10n?.destinationNutrition ?? 'Nutrition',
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        screen: MealScreen(store: widget.store),
      ),
      _AppDestination(
        label: l10n?.destinationLibrary ?? 'Library',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        screen: LibraryScreen(key: _libraryScreenKey, store: widget.store),
      ),
      _AppDestination(
        label: l10n?.destinationMore ?? 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        screen: MoreScreen(
          store: widget.store,
          syncStatusListenable: widget.syncAccess,
          readSyncStatus: () => widget.syncAccess?.status,
          authListenable: widget.authService,
          readAuthState: () => widget.authService.state,
          onSignIn: widget.authService.signIn,
          onSignUp: widget.authService.signUp,
          onSignOut: widget.authService.signOut,
          onDeleteAccount: widget.deleteAccountData,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = IndexedStack(
          index: _selectedIndex,
          children: [
            for (final destination in destinations) destination.screen,
          ],
        );

        if (constraints.maxWidth < AppBreakpoints.mediumMin) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                    tooltip: destination.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDestination,
                  extended: constraints.maxWidth >= AppBreakpoints.largeMin,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.icon),
                        ),
                        selectedIcon: Tooltip(
                          message: destination.label,
                          child: Icon(destination.selectedIcon),
                        ),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  void _selectDestination(int index) {
    _isWorkoutTabCurrent.value = index == 1;
    if (index == _selectedIndex) {
      if (index == 1) {
        _workoutNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (index == 3) {
        _libraryScreenKey.currentState?.resetToRoot();
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }
}

class _AppDestination {
  const _AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}

class _WorkoutTabNavigator extends StatelessWidget {
  const _WorkoutTabNavigator({
    required this.navigatorKey,
    required this.store,
    required this.isCurrentTabListenable,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final AppStore store;
  final ValueListenable<bool> isCurrentTabListenable;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (context) {
            return WorkoutScreen(
              store: store,
              isCurrentTabListenable: isCurrentTabListenable,
            );
          },
        );
      },
    );
  }
}

AppStorePersistence _defaultAppStorePersistenceFactory(
  Set<String> knownExerciseIds,
) {
  return SharedPreferencesAppStorePersistence(
    knownExerciseIds: knownExerciseIds,
  );
}

Future<AppStore> _defaultAppStoreHydrator({
  required AppStorePersistence persistence,
  required PersistedAppStateObserver onPersistedStateSaved,
}) {
  return AppStore.hydrated(
    persistence: persistence,
    onPersistedStateSaved: onPersistedStateSaved,
  );
}

FirebaseAppStoreSyncService _defaultSyncServiceFactory(
  Set<String> knownExerciseIds,
) {
  return FirebaseAppStoreSyncService(knownExerciseIds: knownExerciseIds);
}

AppAuthService _defaultAuthServiceFactory(
  FirebaseInitializer firebaseInitializer,
) {
  return FirebaseAppAuthService(firebaseInitializer: firebaseInitializer);
}

AppStoreSyncCoordinator _defaultSyncCoordinatorFactory({
  required SharedPreferencesSyncMetadataStore metadataStore,
  required FirebaseAppStoreSyncService syncService,
  required UserIdProvider userIdProvider,
  required PersistedStateObserverBinder bindPersistedStateObserver,
  required LocalSnapshotLoader loadLocalSnapshot,
  required RemoteSnapshotApplier applyRemoteSnapshot,
}) {
  return AppStoreSyncCoordinator(
    metadataStore: metadataStore,
    syncService: syncService,
    userIdProvider: userIdProvider,
    bindPersistedStateObserver: bindPersistedStateObserver,
    loadLocalSnapshot: loadLocalSnapshot,
    applyRemoteSnapshot: applyRemoteSnapshot,
  );
}

void _runApp(Widget app) {
  runApp(app);
}
