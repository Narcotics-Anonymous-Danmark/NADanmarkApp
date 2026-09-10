@Tags(['unit'])
library;

import 'package:feature_legacy_migration/feature_legacy_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  test(
    'imports valid settings, writes the marker and publishes the event',
    () async {
      final harness = TestContainer.build(
        legacyStore: LegacyStoreFound(entries: aLegacyStoreDump()),
      );
      addTearDown(harness.dispose);
      final run = await harness.read(legacyMigrationProvider).runIfNeeded();
      expect(
        run,
        MigrationRan(
          importedKeys: 4,
          skippedKeys: 1,
          source: LegacyStoreFound(entries: aLegacyStoreDump()),
        ),
      );
      expect(harness.storage.snapshot['language'], 'en');
      expect(harness.storage.snapshot['firstday'], 'su');
      expect(harness.storage.snapshot['searchRange'], '30');
      expect(harness.storage.snapshot['cleanTimeUnitSort'], 'dmy');
      final marker = LegacyMigrationMarker.decode(
        text: harness.storage.snapshot['legacyMigration.completed'] ?? '',
      );
      expect(
        marker,
        Ok<LegacyMigrationMarker, DecodeFailure>(
          value: LegacyMigrationMarker(
            appVersion: '2.0.0',
            completedAt: anInstant(),
            importedKeys: 4,
            skippedKeys: 1,
          ),
        ),
      );
      final events = harness.events.recordedOf<LegacyMigrationCompleted>();
      expect(events.single.importedKeys, 4);
      expect(events.single.skippedKeys, 1);
    },
  );

  test('a present marker prevents a second run', () async {
    final harness = TestContainer.build(
      storedValues: {'legacyMigration.completed': aMigrationMarker().encoded},
      legacyStore: LegacyStoreFound(entries: aLegacyStoreDump()),
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
          MigrationRan(importedKeys: 0, skippedKeys: 0, source: read),
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
      legacyStore: const LegacyStoreFound(
        entries: {'language': 'en', 'cleanDateProfiles': 'oops', 'firstday': 7},
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
      legacyStore: LegacyStoreFound(entries: aLegacyStoreDump(language: 'en')),
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
      importedKeys: 1,
      skippedKeys: 2,
      source: LegacyStoreAbsent(),
    );
    expect(
      ran.hashCode,
      const MigrationRan(
        importedKeys: 1,
        skippedKeys: 2,
        source: LegacyStoreAbsent(),
      ).hashCode,
    );
    expect(ran.toString(), contains('imported: 1'));
    expect(ran, isNot(const MigrationAlreadyDone()));
  });
}
