import 'package:fitapp/state/persistence/shared_preferences_sync_metadata_store.dart';
import 'package:fitapp/state/persistence/sync_metadata.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('SharedPreferencesSyncMetadataStore returns null when empty', () async {
    SharedPreferences.setMockInitialValues(const {});
    final store = SharedPreferencesSyncMetadataStore();

    expect(await store.load(), isNull);
  });

  test(
    'SharedPreferencesSyncMetadataStore saves and reloads metadata',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final store = SharedPreferencesSyncMetadataStore();
      final metadata = SyncMetadata(
        installationId: 'installation-123',
        lastKnownRemoteUpdatedAt: DateTime.parse('2026-05-13T08:30:00.000Z'),
        lastSyncedSnapshotHash: 'hash-abc',
        lastSyncError: 'network timeout',
      );

      await store.save(metadata);
      final reloaded = await store.load();

      expect(reloaded, isNotNull);
      expect(reloaded!.installationId, metadata.installationId);
      expect(
        reloaded.lastKnownRemoteUpdatedAt,
        metadata.lastKnownRemoteUpdatedAt,
      );
      expect(reloaded.lastSyncedSnapshotHash, metadata.lastSyncedSnapshotHash);
      expect(reloaded.lastSyncError, metadata.lastSyncError);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when persisted value is invalid JSON',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSyncMetadataStore.storageKey: '{',
      });
      final store = SharedPreferencesSyncMetadataStore();

      expect(store.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when persisted value is an empty string',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSyncMetadataStore.storageKey: '',
      });
      final store = SharedPreferencesSyncMetadataStore();

      expect(store.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when persisted value is not a JSON object',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSyncMetadataStore.storageKey: '[]',
      });
      final store = SharedPreferencesSyncMetadataStore();

      expect(store.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when installationId is invalid',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSyncMetadataStore.storageKey:
            '{"installationId":1,"lastKnownRemoteUpdatedAt":null,"lastSyncedSnapshotHash":null,"lastSyncError":null}',
      });
      final store = SharedPreferencesSyncMetadataStore();

      expect(store.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when lastKnownRemoteUpdatedAt is invalid',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSyncMetadataStore.storageKey:
            '{"installationId":"installation-123","lastKnownRemoteUpdatedAt":"not-a-date","lastSyncedSnapshotHash":null,"lastSyncError":null}',
      });
      final store = SharedPreferencesSyncMetadataStore();

      expect(store.load, throwsFormatException);
    },
  );

  test(
    'SharedPreferencesSyncMetadataStore throws when SharedPreferences save fails',
    () async {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance =
          _FailingSetValueSharedPreferencesStore();
      final store = SharedPreferencesSyncMetadataStore();

      expect(
        () => store.save(
          SyncMetadata(
            installationId: 'installation-123',
            lastKnownRemoteUpdatedAt: DateTime.parse(
              '2026-05-13T08:30:00.000Z',
            ),
            lastSyncedSnapshotHash: 'hash-abc',
            lastSyncError: 'network timeout',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}

class _FailingSetValueSharedPreferencesStore
    extends SharedPreferencesStorePlatform {
  @override
  Future<bool> clear() async => true;

  @override
  Future<Map<String, Object>> getAll() async => <String, Object>{};

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}
