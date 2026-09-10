@Tags(['acceptance'])
library;

import 'package:feature_legacy_migration/feature_legacy_migration.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/pump_app.dart';

void main() {
  group('Requirement: Run once, before first render', () {
    testWidgets('Marker prevents a second run', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          storedValues: {
            'legacyMigration.completed': aMigrationMarker().encoded,
          },
          legacyStore: LegacyStoreFound(entries: aLegacyStoreDump()),
        ),
      );
      addTearDown(app.dispose);
      expect(app.container.legacyStore.reads, 0);
      expect(app.storage.snapshot['language'], 'da');
    });

    testWidgets('No legacy database', (tester) async {
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      expect(
        app.storage.snapshot.containsKey('legacyMigration.completed'),
        isTrue,
      );
      expect(app.storage.snapshot['language'], 'da');
      expect(app.storage.snapshot['searchRange'], '15');
    });
  });

  group('Requirement: Keys and translation rules', () {
    testWidgets('Valid settings are copied', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/settings',
        container: realJftContainer(
          legacyStore: const LegacyStoreFound(
            entries: {
              'language': 'en',
              'firstday': 'su',
              'searchRange': 30,
              'cleanTimeUnitSort': 'dmy',
            },
          ),
        ),
      );
      addTearDown(app.dispose);
      expect(app.storage.snapshot['language'], 'en');
      expect(app.storage.snapshot['firstday'], 'su');
      expect(app.storage.snapshot['searchRange'], '30');
      expect(app.storage.snapshot['cleanTimeUnitSort'], 'dmy');
      expect(pageText('Settings'), findsOneWidget);
      expect(pageText('Default search range = 30 km'), findsOneWidget);
    });
  });

  group('Requirement: Failure tolerance', () {
    testWidgets('One bad value does not block the rest', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          legacyStore: const LegacyStoreFound(
            entries: {'cleanDateProfiles': 'oops', 'language': 'en'},
          ),
        ),
      );
      addTearDown(app.dispose);
      expect(app.storage.snapshot['language'], 'en');
      expect(find.text('Narcotics Anonymous Denmark'), findsOneWidget);
    });

    testWidgets('Corrupt database', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          legacyStore: const LegacyStoreUnreadable(detail: 'corrupt'),
        ),
      );
      addTearDown(app.dispose);
      expect(
        app.storage.snapshot.containsKey('legacyMigration.completed'),
        isTrue,
      );
      expect(find.text('Narcotics Anonymous Danmark'), findsOneWidget);
    });
  });

  group('Requirement: Idempotency and safety', () {
    testWidgets('Translation is a pure function', (tester) async {
      const translator = LegacySettingsTranslator();
      final entries = aLegacyStoreDump();
      expect(
        translator.translate(entries: entries),
        translator.translate(entries: entries),
      );
      final app = await pumpApp(tester: tester);
      addTearDown(app.dispose);
      expect(
        await app.container.read(legacyMigrationProvider).runIfNeeded(),
        const MigrationAlreadyDone(),
      );
    });
  });

  group('Requirement: Observability', () {
    testWidgets('Event after import', (tester) async {
      final app = await pumpApp(
        tester: tester,
        initialLocation: '/contact',
        container: realJftContainer(
          legacyStore: LegacyStoreFound(entries: aLegacyStoreDump()),
        ),
      );
      addTearDown(app.dispose);
      final event = app.events.recordedOf<LegacyMigrationCompleted>().single;
      expect(event.importedKeys, 4);
      expect(event.skippedKeys, 1);
      await scrollPageTo(
        tester,
        find.byKey(const Key('contact-imported-settings')),
      );
      expect(
        find.text('Imported settings from the previous version'),
        findsOneWidget,
      );
    });
  });
}
