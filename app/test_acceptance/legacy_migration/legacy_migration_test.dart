@Tags(['acceptance'])
library;

import 'package:feature_legacy_migration/feature_legacy_migration.dart';
import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';

import '../support/cleantime.dart';
import '../support/meetings.dart';
import '../support/pump_app.dart';

const WireObject anna2020 = {
  'name': 'Anna',
  'cleandate': '2020-05-03T00:00:00.000+02:00',
};
const WireObject bo2019 = {
  'name': 'Bo',
  'cleandate': '2019-11-30T00:00:00.000+01:00',
};

Future<AppHarness> pumpMigratedProfiles({
  required WidgetTester tester,
  required List<WireObject> profiles,
  Language language = Language.english,
  WireObject active = const {'activeProfile': '0'},
  RoutePath location = homePath,
}) => pumpApp(
  tester: tester,
  initialLocation: location.value,
  container: realJftContainer(
    legacyStore: LegacyStoreFound(
      dump: LegacyStoreDumpDto.fromJson({
        'language': language.code,
        'cleanDateProfiles': profiles,
        ...active,
      }),
    ),
  ),
);

void main() {
  group('Requirement: Run once, before first render', () {
    testWidgets('Marker prevents a second run', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          storedValues: {
            'legacyMigration.completed': aStoredMigrationMarker(),
          },
          legacyStore: LegacyStoreFound(dump: aLegacyStoreDump()),
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
          legacyStore: LegacyStoreFound(
            dump: LegacyStoreDumpDto.fromJson(const {
              'language': 'en',
              'firstday': 'su',
              'searchRange': 30,
              'cleanTimeUnitSort': 'dmy',
            }),
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

    testWidgets('Meeting formats cache is copied', (tester) async {
      final bmlt = bmltServing(
        meetings: [aBmltMeetingDto(id: 1, weekday: 2, municipality: 'Aarhus')],
      );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
        time: TestTime.copenhagen(
          startAt: Instant(DateTime.utc(2025, 9, 12, 12)),
        ),
        legacyStore: LegacyStoreFound(
          dump: aLegacyDumpWithFormats(formats: [aBmltFormatDto()]),
        ),
      );
      addTearDown(app.dispose);
      final cached = const FormatsCacheCodec().decode(
        text: app.storage.snapshot['meetingFormatsCache'] ?? '',
      );
      final snapshot = (cached as Ok<FormatsSnapshot, DecodeFailure>).value;
      expect(snapshot.fetchedAt.epochMilliseconds, 1757500000000);
      expect(snapshot.rows.single.key, const FormatKey('ÅM'));
      await toggleDay(tester, 'monday');
      expect(bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish), isEmpty);
      expect(bmlt.requestsTo(endpoint: BmltEndpoint.formatsEnglish), isEmpty);
    });

    testWidgets('Empty meeting formats cache is dropped', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          legacyStore: LegacyStoreFound(
            dump: LegacyStoreDumpDto.fromJson(const {
              'meeting_formats_v1': {
                'fetchedAt': 1757500000000,
                'formats': <Object?>[],
              },
            }),
          ),
        ),
      );
      addTearDown(app.dispose);
      expect(app.storage.snapshot.containsKey('meetingFormatsCache'), isFalse);
      final marker = const MigrationMarkerCodec().decode(
        text: app.storage.snapshot['legacyMigration.completed'] ?? '',
      );
      expect(
        (marker as Ok<LegacyMigrationMarker, DecodeFailure>).value.skippedKeys,
        const KeyCount(1),
      );
    });

    testWidgets('Cleantime profiles keep their calendar date', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: [anna2020],
      );
      addTearDown(app.dispose);
      expect(savedProfiles(app), [aCleantimeProfile()]);
    });

    testWidgets('Picker-written clean date', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: const [
          {'name': 'Bo', 'cleandate': '2019-11-30T23:30:00.000Z'},
        ],
      );
      addTearDown(app.dispose);
      expect(savedProfiles(app), [
        aCleantimeProfile(
          name: bo,
          cleanDate: const LocalDate(year: 2019, month: 11, day: 30),
        ),
      ]);
    });

    testWidgets('Unparseable entries are dropped', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: const [
          anna2020,
          {'name': 'X', 'cleandate': 'soon'},
          {'name': 'Y'},
        ],
      );
      addTearDown(app.dispose);
      expect(savedProfiles(app), [aCleantimeProfile()]);
    });

    testWidgets('Unnamed profile keeps its date', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        language: Language.danish,
        profiles: const [
          anna2020,
          {'name': ' ', 'cleandate': '2021-01-02T00:00:00.000+01:00'},
        ],
      );
      addTearDown(app.dispose);
      expect(savedProfiles(app), [
        aCleantimeProfile(),
        aCleantimeProfile(
          name: const ProfileName('Profil 2'),
          cleanDate: const LocalDate(year: 2021, month: 1, day: 2),
        ),
      ]);
    });

    testWidgets('Active index is clamped', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: const [anna2020, bo2019],
        active: const {'activeProfile': '5'},
      );
      addTearDown(app.dispose);
      expect(savedActive(app), '1');
    });

    testWidgets('Numeric active index', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: const [anna2020, bo2019],
        active: const {'activeProfile': 1},
      );
      addTearDown(app.dispose);
      expect(savedActive(app), '1');
    });

    testWidgets('Imported profiles appear in the calculator', (tester) async {
      final app = await pumpMigratedProfiles(
        tester: tester,
        profiles: const [anna2020, bo2019],
        active: const {'activeProfile': '1'},
        location: cleantimePath,
      );
      addTearDown(app.dispose);
      expect(selectedProfileName(tester), 'Bo');
      expect(find.text('30 Nov 2019'), findsOneWidget);
      await openMenu(tester);
      await tester.tap(inMenu(find.text('Home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-cleantime-card-0')), findsOneWidget);
      await tester.fling(find.byKey(homeCarousel), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-cleantime-card-1')), findsOneWidget);
    });
  });

  group('Requirement: Failure tolerance', () {
    testWidgets('One bad value does not block the rest', (tester) async {
      final app = await pumpApp(
        tester: tester,
        container: realJftContainer(
          legacyStore: LegacyStoreFound(
            dump: LegacyStoreDumpDto.fromJson(const {
              'cleanDateProfiles': 'oops',
              'language': 'en',
            }),
          ),
        ),
      );
      addTearDown(app.dispose);
      expect(app.storage.snapshot['language'], 'en');
      expect(find.text('Narcotics Anonymous Denmark'), findsOneWidget);
      expect(app.storage.snapshot.containsKey('cleantimeProfiles'), isFalse);
      expect(
        app.events.recordedOf<LegacyMigrationCompleted>().single.skippedKeys,
        const KeyCount(1),
      );
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
      final dump = aLegacyStoreDump();
      expect(
        translator.translate(dump: dump),
        translator.translate(dump: dump),
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
          legacyStore: LegacyStoreFound(dump: aLegacyStoreDump()),
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
