@Tags(['unit'])
library;

import 'package:feature_legacy_migration/feature_legacy_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  test(
    'imports valid settings, writes the marker and publishes the event',
    () async {
      final harness = TestContainer.build(
        legacyStore: LegacyStoreFound(dump: aLegacyStoreDump()),
      );
      addTearDown(harness.dispose);
      final run = await harness.read(legacyMigrationProvider).runIfNeeded();
      expect(
        run,
        MigrationRan(
          importedKeys: const KeyCount(4),
          skippedKeys: const KeyCount(1),
          source: LegacyStoreFound(dump: aLegacyStoreDump()),
        ),
      );
      expect(harness.storage.snapshot['language'], 'en');
      expect(harness.storage.snapshot['firstday'], 'su');
      expect(harness.storage.snapshot['searchRange'], '30');
      expect(harness.storage.snapshot['cleanTimeUnitSort'], 'dmy');
      final marker = const MigrationMarkerCodec().decode(
        text: harness.storage.snapshot['legacyMigration.completed'] ?? '',
      );
      expect(
        marker,
        Ok<LegacyMigrationMarker, DecodeFailure>(
          value: LegacyMigrationMarker(
            appVersion: const VersionName('2.0.0'),
            completedAt: anInstant(),
            importedKeys: const KeyCount(4),
            skippedKeys: const KeyCount(1),
          ),
        ),
      );
      final events = harness.events.recordedOf<LegacyMigrationCompleted>();
      expect(events.single.importedKeys, const KeyCount(4));
      expect(events.single.skippedKeys, const KeyCount(1));
    },
  );

  test('a present marker prevents a second run', () async {
    final harness = TestContainer.build(
      storedValues: {'legacyMigration.completed': aStoredMigrationMarker()},
      legacyStore: LegacyStoreFound(dump: aLegacyStoreDump()),
    );
    addTearDown(harness.dispose);
    expect(
      await harness.read(legacyMigrationProvider).runIfNeeded(),
      const MigrationAlreadyDone(),
    );
    expect(harness.legacyStore.reads, 0);
    expect(harness.storage.snapshot.containsKey('language'), isFalse);
  });

  test(
    'no database and a corrupt database both end with the marker set',
    () async {
      for (final read in [
        const LegacyStoreAbsent(),
        const LegacyStoreUnreadable(detail: 'corrupt'),
      ]) {
        final harness = TestContainer.build(legacyStore: read);
        final run = await harness.read(legacyMigrationProvider).runIfNeeded();
        expect(
          run,
          MigrationRan(
            importedKeys: const KeyCount(0),
            skippedKeys: const KeyCount(0),
            source: read,
          ),
        );
        expect(harness.storage.snapshot.keys, ['legacyMigration.completed']);
        expect(
          harness.events.recordedOf<LegacyMigrationCompleted>(),
          hasLength(1),
        );
        await harness.dispose();
      }
    },
  );

  test('one bad value does not block the rest', () async {
    final harness = TestContainer.build(
      legacyStore: LegacyStoreFound(
        dump: LegacyStoreDumpDto.fromJson(const {
          'language': 'en',
          'cleanDateProfiles': 'oops',
          'firstday': 7,
        }),
      ),
    );
    addTearDown(harness.dispose);
    final run = await harness.read(legacyMigrationProvider).runIfNeeded();
    expect(run, isA<MigrationRan>());
    expect(harness.storage.snapshot['language'], 'en');
    expect(harness.storage.snapshot.containsKey('firstday'), isFalse);
  });

  test('existing new-format values are never overwritten', () async {
    final harness = TestContainer.build(
      storedValues: {'language': 'da'},
      legacyStore: LegacyStoreFound(dump: aLegacyStoreDump(language: 'en')),
    );
    addTearDown(harness.dispose);
    await harness.read(legacyMigrationProvider).runIfNeeded();
    expect(harness.storage.snapshot['language'], 'da');
    expect(harness.storage.snapshot['firstday'], 'su');
  });

  test('run results compare by value and describe themselves', () {
    expect(
      const MigrationAlreadyDone().hashCode,
      const MigrationAlreadyDone().hashCode,
    );
    const ran = MigrationRan(
      importedKeys: KeyCount(1),
      skippedKeys: KeyCount(2),
      source: LegacyStoreAbsent(),
    );
    expect(
      ran.hashCode,
      const MigrationRan(
        importedKeys: KeyCount(1),
        skippedKeys: KeyCount(2),
        source: LegacyStoreAbsent(),
      ).hashCode,
    );
    expect(ran.toString(), contains('imported: 1'));
    expect(ran, isNot(const MigrationAlreadyDone()));
  });

  group('meeting formats cache', () {
    test('a cache with rows is copied and counted as imported', () async {
      final harness = TestContainer.build(
        legacyStore: LegacyStoreFound(
          dump: aLegacyDumpWithFormats(formats: [aBmltFormatDto()]),
        ),
      );
      addTearDown(harness.dispose);
      final run = await harness.read(legacyMigrationProvider).runIfNeeded();
      expect((run as MigrationRan).importedKeys, const KeyCount(1));
      expect(
        harness.storage.snapshot['meetingFormatsCache'],
        startsWith('{"fetchedAt":1757500000000,"formats":[{'),
      );
    });

    test('an empty cache is dropped and counted as skipped', () async {
      final harness = TestContainer.build(
        legacyStore: LegacyStoreFound(dump: aLegacyDumpWithFormats()),
      );
      addTearDown(harness.dispose);
      final run = await harness.read(legacyMigrationProvider).runIfNeeded();
      expect((run as MigrationRan).skippedKeys, const KeyCount(1));
      expect(
        harness.storage.snapshot.containsKey('meetingFormatsCache'),
        isFalse,
      );
    });

    test('an existing cache is never overwritten', () async {
      final harness = TestContainer.build(
        storedValues: {'meetingFormatsCache': 'already here'},
        legacyStore: LegacyStoreFound(
          dump: aLegacyDumpWithFormats(formats: [aBmltFormatDto()]),
        ),
      );
      addTearDown(harness.dispose);
      await harness.read(legacyMigrationProvider).runIfNeeded();
      expect(harness.storage.snapshot['meetingFormatsCache'], 'already here');
    });
  });
}
