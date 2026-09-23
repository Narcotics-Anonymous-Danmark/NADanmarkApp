@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_testing/na_testing.dart';

import '../support/meetings.dart';
import '../support/pump_app.dart';

const denmark = 'https://denmark.test/main_server/client_interface/json/';
const openDescription =
    'This meeting is open to addicts and non-addicts alike. All are welcome.';

void main() {
  group('Requirement: BMLT endpoints', () {
    testWidgets('Empty object means no meetings', (tester) async {
      final bmlt = bmltServing(municipalities: ['Aarhus'])
        ..serve(endpoint: BmltEndpoint.meetings, reply: const BmltNoResults());
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
      );
      addTearDown(app.dispose);
      expect(pageText('Nothing found'), findsOneWidget);
      expect(pageText('The meetings could not be loaded'), findsNothing);
    });

    testWidgets('Formats are fetched in both languages', (tester) async {
      final bmlt = bmltServing(
        meetings: [aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus')],
      );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(
        bmlt
            .requestsTo(endpoint: BmltEndpoint.formatsDanish)
            .map((uri) => uri.toString()),
        ['$denmark?switcher=GetFormats&lang_enum=da'],
      );
      expect(
        bmlt
            .requestsTo(endpoint: BmltEndpoint.formatsEnglish)
            .map((uri) => uri.toString()),
        ['$denmark?switcher=GetFormats&lang_enum=en'],
      );
    });
  });

  group('Requirement: Full meeting list by municipality', () {
    testWidgets('Municipalities are unique and Online is last', (
      tester,
    ) async {
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmltServing(
          municipalities: [
            'Aarhus',
            'Aarhus',
            'København',
            '',
            'Online møde',
            'Viborg.',
          ],
        ),
      );
      addTearDown(app.dispose);
      final rows = ['Aarhus', 'København', 'Online'];
      final tops = rows
          .map(
            (name) =>
                tester.getTopLeft(find.byKey(Key('municipality-row-$name'))).dy,
          )
          .toList();
      expect(tops, List.of(tops)..sort());
      expect(
        find.byKey(const Key('municipality-row-Online møde')),
        findsNothing,
      );
      expect(find.byKey(const Key('municipality-row-Viborg.')), findsNothing);
      expect(pageText('Meetings'), findsOneWidget);
    });

    testWidgets('Municipality meetings are filtered', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmltServing(
          municipalities: ['Aarhus', 'København'],
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
            aBmltMeetingJson(id: 2, weekday: 2, municipality: 'København'),
          ],
        ),
      );
      addTearDown(app.dispose);
      await openMunicipality(tester, 'Aarhus');
      expect(pageText('Aarhus'), findsWidgets);
      expect(find.byKey(const Key('back-button')), findsOneWidget);
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
      await toggleDay(tester, 'monday');
      expect(card(1), findsOneWidget);
      expect(card(2), findsNothing);
    });

    testWidgets('Online groups all blank-like municipalities', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmltServing(
          municipalities: ['Aarhus', ''],
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: ''),
            aBmltMeetingJson(id: 2, weekday: 2, municipality: 'Online møde'),
            aBmltMeetingJson(id: 3, weekday: 2, municipality: 'Viborg online'),
            aBmltMeetingJson(id: 4, weekday: 2, municipality: 'Viborg.'),
            aBmltMeetingJson(id: 5, weekday: 2, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      await openMunicipality(tester, 'Online');
      expect(sectionLabel(tester, 'monday'), 'Monday (4)');
      await toggleDay(tester, 'monday');
      expect([1, 2, 3, 4].map((id) => card(id).evaluate().length), [
        1,
        1,
        1,
        1,
      ]);
      expect(card(5), findsNothing);
    });

    testWidgets('Back returns to the municipality list', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmltServing(
          municipalities: ['Aarhus'],
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      await openMunicipality(tester, 'Aarhus');
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      expect(pageText('Meetings'), findsOneWidget);
      expect(find.byKey(const Key('municipality-row-Aarhus')), findsOneWidget);
    });

    testWidgets('No municipalities', (tester) async {
      final bmlt = BmltServerMimic()
        ..serve(
          endpoint: BmltEndpoint.municipalities,
          reply: const BmltNoResults(),
        );
      final app = await pumpMeetings(tester: tester, bmlt: bmlt);
      addTearDown(app.dispose);
      expect(pageText('Nothing found'), findsOneWidget);
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    });

    testWidgets('Failed request can be retried', (tester) async {
      final bmlt = BmltServerMimic()
        ..serve(
          endpoint: BmltEndpoint.municipalities,
          reply: const BmltUnreachable(),
        );
      final app = await pumpMeetings(tester: tester, bmlt: bmlt);
      addTearDown(app.dispose);
      expect(pageText('The meetings could not be loaded'), findsOneWidget);
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
      bmlt.serve(
        endpoint: BmltEndpoint.municipalities,
        reply: BmltRows(rows: [aBmltMunicipalityJson(municipality: 'Aarhus')]),
      );
      await tester.tap(find.byKey(const Key('meetings-retry')));
      await tester.pumpAndSettle();
      expect(pageText('The meetings could not be loaded'), findsNothing);
      expect(find.byKey(const Key('municipality-row-Aarhus')), findsOneWidget);
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    });

    testWidgets('Previous municipality is not shown while loading', (
      tester,
    ) async {
      final bmlt = bmltServing(
        municipalities: ['Aarhus', 'København'],
        meetings: [
          aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
          aBmltMeetingJson(id: 2, weekday: 3, municipality: 'København'),
        ],
      );
      final app = await pumpMeetings(tester: tester, bmlt: bmlt);
      addTearDown(app.dispose);
      await openMunicipality(tester, 'Aarhus');
      expect(sectionHeader('monday'), findsOneWidget);
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      final held = bmlt.hold(endpoint: BmltEndpoint.meetings);
      await tester.tap(find.byKey(const Key('municipality-row-København')));
      await tester.pump();
      await tester.pump();
      expect(sectionHeader('monday'), findsNothing);
      expect(card(1), findsNothing);
      held.release();
      await tester.pumpAndSettle();
      expect(sectionHeader('tuesday'), findsOneWidget);
    });
  });

  group('Requirement: Weekday grouping and ordering', () {
    testWidgets('Monday first moves Sunday to the end', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 1, municipality: 'Aarhus'),
            aBmltMeetingJson(id: 2, weekday: 2, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(
        tester.getTopLeft(sectionHeader('monday')).dy,
        lessThan(tester.getTopLeft(sectionHeader('sunday')).dy),
      );
    });

    testWidgets("Today's header is highlighted", (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        time: TestTime.copenhagen(startAt: anInstant(day: 9)),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 3, municipality: 'Aarhus'),
            aBmltMeetingJson(id: 2, weekday: 4, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(sectionLabel(tester, 'wednesday'), 'Wednesday (1)');
      expect(sectionColour(tester, 'wednesday'), NaColors.light.secondary);
      expect(sectionColour(tester, 'tuesday'), NaColors.light.primary);
    });

    testWidgets('One section open at a time', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(id: 1, weekday: 2, municipality: 'Aarhus'),
            aBmltMeetingJson(id: 2, weekday: 3, municipality: 'Aarhus'),
          ],
        ),
      );
      addTearDown(app.dispose);
      expect(card(1), findsNothing);
      await toggleDay(tester, 'monday');
      expect(card(1), findsOneWidget);
      await toggleDay(tester, 'tuesday');
      expect(card(2), findsOneWidget);
      expect(card(1), findsNothing);
    });
  });

  group('Requirement: Day and hour filters', () {
    List<Map<String, String>> fridayAndMonday() => [
      aBmltMeetingJson(
        id: 1,
        weekday: 6,
        startTime: '17:30:00',
        municipality: 'Aarhus',
      ),
      aBmltMeetingJson(
        id: 2,
        weekday: 6,
        startTime: '18:00:00',
        municipality: 'Aarhus',
      ),
      aBmltMeetingJson(
        id: 3,
        weekday: 6,
        startTime: '20:59:00',
        municipality: 'Aarhus',
      ),
      aBmltMeetingJson(
        id: 4,
        weekday: 2,
        startTime: '19:00:00',
        municipality: 'Aarhus',
      ),
    ];

    testWidgets('Day filter keeps one section', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(meetings: fridayAndMonday()),
      );
      addTearDown(app.dispose);
      expect(
        tester
            .widget<NaListRow>(find.byKey(const Key('meeting-day-filter')))
            .value,
        'All days',
      );
      await chooseOption(
        tester: tester,
        row: const Key('meeting-day-filter'),
        option: 'Friday',
      );
      expect(sectionLabel(tester, 'friday'), 'Friday (3)');
      expect(sectionHeader('monday'), findsNothing);
    });

    testWidgets('Hour range filters by start hour', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(meetings: fridayAndMonday()),
      );
      addTearDown(app.dispose);
      await nudgeThumb(
        tester: tester,
        label: 'Earliest start hour',
        direction: NudgeDirection.up,
        times: 18,
      );
      await nudgeThumb(
        tester: tester,
        label: 'Latest start hour',
        direction: NudgeDirection.down,
        times: 3,
      );
      app.container.time.advance(by: const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(sectionLabel(tester, 'friday'), 'Friday (2)');
      expect(sectionLabel(tester, 'monday'), 'Monday (1)');
      await toggleDay(tester, 'friday');
      expect(card(1), findsNothing);
      expect(card(2), findsOneWidget);
      expect(card(3), findsOneWidget);
    });
  });

  group('Requirement: Meeting times', () {
    testWidgets('End time is start plus duration', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              startTime: '19:00:00',
              duration: '01:30:00',
              municipality: 'Aarhus',
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(
        tester.widget<Text>(find.byKey(const Key('meeting-badge-1'))).data,
        'Monday 19:00 - 20:30',
      );
    });
  });

  group('Requirement: Meeting card', () {
    Future<AppHarness> pumpOne(
      WidgetTester tester,
      Map<String, String> meeting,
    ) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(meetings: [meeting]),
      );
      await toggleDay(tester, 'monday');
      return app;
    }

    testWidgets('Only present fields are rendered', (tester) async {
      final app = await pumpOne(
        tester,
        aBmltMeetingJson(
          id: 1,
          weekday: 2,
          municipality: 'Aarhus',
          locationText: '',
          street: 'Gade 1',
          postalCode: '',
          comments: '',
        ),
      );
      addTearDown(app.dispose);
      expect(textsIn(tester, find.byKey(const Key('meeting-location-1'))), [
        'Gade 1',
        'Aarhus',
      ]);
    });

    testWidgets('Transit prefix is stripped', (tester) async {
      final app = await pumpOne(
        tester,
        aBmltMeetingJson(
          id: 1,
          weekday: 2,
          municipality: 'Aarhus',
          busLines: 'Bus Lines#@-@#2A, 5C',
        ),
      );
      addTearDown(app.dispose);
      expect(inCard(1, find.text('Bus: 2A, 5C')), findsOneWidget);
    });

    testWidgets('Postal code is shown', (tester) async {
      final app = await pumpOne(
        tester,
        aBmltMeetingJson(
          id: 1,
          weekday: 2,
          municipality: 'Aarhus',
          postalCode: '8000',
        ),
      );
      addTearDown(app.dispose);
      expect(
        textsIn(tester, find.byKey(const Key('meeting-location-1'))),
        contains('8000'),
      );
    });
  });

  group('Requirement: Temporarily closed rule', () {
    Future<AppHarness> pumpClosed(
      WidgetTester tester, {
      required String formats,
      required String virtualLink,
    }) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: formats,
              sharedIds: '',
              virtualLink: virtualLink,
            ),
          ],
        ),
      );
      await toggleDay(tester, 'monday');
      return app;
    }

    testWidgets('TC without virtual link is closed', (tester) async {
      final app = await pumpClosed(tester, formats: 'O,TC', virtualLink: '');
      addTearDown(app.dispose);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('meeting-closed-1')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Temporarily closed',
      );
    });

    testWidgets('TC with a virtual link is not closed', (tester) async {
      final app = await pumpClosed(
        tester,
        formats: 'O,TC',
        virtualLink: 'https://zoom.example/j/1',
      );
      addTearDown(app.dispose);
      expect(find.byKey(const Key('meeting-closed-1')), findsNothing);
    });

    testWidgets('A key that only contains TC is not closed', (tester) async {
      final app = await pumpClosed(tester, formats: 'O,ATC', virtualLink: '');
      addTearDown(app.dispose);
      expect(find.byKey(const Key('meeting-closed-1')), findsNothing);
    });
  });

  group('Requirement: Meeting card actions', () {
    Future<AppHarness> pumpActions(
      WidgetTester tester, {
      String formats = 'BT',
      String virtualLink = '',
      String phoneMeeting = '',
    }) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: formats,
              sharedIds: '',
              virtualLink: virtualLink,
              phoneMeeting: phoneMeeting,
              latitude: '56.15',
              longitude: '10.2',
            ),
          ],
        ),
      );
      await toggleDay(tester, 'monday');
      return app;
    }

    testWidgets('In-person meeting shows directions only', (tester) async {
      final app = await pumpActions(tester);
      addTearDown(app.dispose);
      expect(find.byKey(const Key('meeting-virtual-1')), findsNothing);
      expect(find.byKey(const Key('meeting-dial-in-1')), findsNothing);
      await tester.tap(find.byKey(const Key('meeting-directions-1')));
      await tester.pumpAndSettle();
      expect(app.links.opened, [
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=56.15,10.2',
        ),
      ]);
    });

    testWidgets('Hybrid meeting shows directions and virtual link', (
      tester,
    ) async {
      final app = await pumpActions(
        tester,
        formats: 'HY',
        virtualLink: 'https://zoom.example/j/1',
      );
      addTearDown(app.dispose);
      expect(find.byKey(const Key('meeting-directions-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('meeting-virtual-1')));
      await tester.pumpAndSettle();
      expect(app.links.opened, [Uri.parse('https://zoom.example/j/1')]);
    });

    testWidgets('Virtual meeting with phone number', (tester) async {
      final app = await pumpActions(
        tester,
        virtualLink: 'https://zoom.example/j/1',
        phoneMeeting: '+45 11 22 33 44',
      );
      addTearDown(app.dispose);
      expect(find.byKey(const Key('meeting-directions-1')), findsNothing);
      expect(find.byKey(const Key('meeting-virtual-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('meeting-dial-in-1')));
      await tester.pumpAndSettle();
      expect(app.links.opened, [Uri(scheme: 'tel', path: '+45 11 22 33 44')]);
    });
  });

  group('Requirement: Format definitions and cache', () {
    final aarhusMeeting = aBmltMeetingJson(
      id: 1,
      weekday: 2,
      municipality: 'Aarhus',
      formats: 'ÅM',
      sharedIds: '17',
    );

    testWidgets('Fresh cache avoids the network', (tester) async {
      final bmlt = bmltServing(meetings: [aarhusMeeting]);
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
        storedValues: {
          ...inEnglish,
          'meetingFormatsCache': formatsCache(
            fetchedAt: anInstant(day: 7),
          ),
        },
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['Open']);
      expect(bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish), isEmpty);
      expect(bmlt.requestsTo(endpoint: BmltEndpoint.formatsEnglish), isEmpty);
    });

    testWidgets('Stale cache used when offline', (tester) async {
      final bmlt = bmltServing(meetings: [aarhusMeeting])
        ..serve(
          endpoint: BmltEndpoint.formatsDanish,
          reply: const BmltUnreachable(),
        )
        ..serve(
          endpoint: BmltEndpoint.formatsEnglish,
          reply: const BmltUnreachable(),
        );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
        storedValues: {
          ...inEnglish,
          'meetingFormatsCache': formatsCache(fetchedAt: anInstant(day: 2)),
        },
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['Open']);
      expect(bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish), isNotEmpty);
    });

    testWidgets('Failure allows retry after a minute', (tester) async {
      final bmlt =
          bmltServing(
              municipalities: ['Aarhus'],
              meetings: [aarhusMeeting],
            )
            ..serve(
              endpoint: BmltEndpoint.formatsDanish,
              reply: const BmltUnreachable(),
            )
            ..serve(
              endpoint: BmltEndpoint.formatsEnglish,
              reply: const BmltUnreachable(),
            );
      final app = await pumpMeetings(tester: tester, bmlt: bmlt);
      addTearDown(app.dispose);
      await openMunicipality(tester, 'Aarhus');
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['ÅM']);
      expect(
        bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish),
        hasLength(1),
      );
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      await openMunicipality(tester, 'Aarhus');
      await toggleDay(tester, 'monday');
      expect(
        bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish),
        hasLength(1),
      );
      app.container.time.advance(by: const Duration(seconds: 61));
      bmlt
        ..serve(
          endpoint: BmltEndpoint.formatsDanish,
          reply: BmltRows(rows: recordedFormatsDaJson()),
        )
        ..serve(
          endpoint: BmltEndpoint.formatsEnglish,
          reply: BmltRows(rows: recordedFormatsEnJson()),
        );
      await tester.tap(find.byKey(const Key('back-button')));
      await tester.pumpAndSettle();
      await openMunicipality(tester, 'Aarhus');
      await toggleDay(tester, 'monday');
      expect(
        bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish),
        hasLength(2),
      );
      expect(chipLabels(tester, 1), ['Open']);
    });

    testWidgets('Concurrent meetings share one fetch', (tester) async {
      final bmlt = bmltServing(
        meetings: List.generate(
          20,
          (index) => aBmltMeetingJson(
            id: index + 1,
            weekday: 2,
            municipality: 'Aarhus',
            formats: 'ÅM',
            sharedIds: '17',
          ),
        ),
      );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(
        bmlt.requestsTo(endpoint: BmltEndpoint.formatsDanish),
        hasLength(1),
      );
      expect(
        bmlt.requestsTo(endpoint: BmltEndpoint.formatsEnglish),
        hasLength(1),
      );
    });
  });

  group('Requirement: Format category and display language', () {
    Future<AppHarness> pumpFormats(
      WidgetTester tester, {
      required String formats,
      required String sharedIds,
      required Map<String, String> storedValues,
    }) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        storedValues: storedValues,
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: formats,
              sharedIds: sharedIds,
            ),
          ],
        ),
      );
      await tester.tap(find.byKey(const Key('meeting-section-monday')));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('Danish names in Danish', (tester) async {
      final app = await pumpFormats(
        tester,
        formats: 'ÅM',
        sharedIds: '17',
        storedValues: const {},
      );
      addTearDown(app.dispose);
      expect(chipLabels(tester, 1), ['Åben Møde']);
    });

    testWidgets('English names in English', (tester) async {
      final app = await pumpFormats(
        tester,
        formats: 'ÅM',
        sharedIds: '17',
        storedValues: inEnglish,
      );
      addTearDown(app.dispose);
      expect(chipLabels(tester, 1), ['Open']);
    });

    testWidgets('Category mapping', (tester) async {
      final app = await pumpFormats(
        tester,
        formats: 'HV',
        sharedIds: '33',
        storedValues: inEnglish,
      );
      addTearDown(app.dispose);
      expect(chipLabels(tester, 1), ['Wheelchair']);
      expect(chipColour(tester, 'WC'), darkChipColour);
    });
  });

  group("Requirement: Resolving a meeting's formats", () {
    testWidgets('Danish meeting resolves by shared id', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        storedValues: const {},
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: 'O,TC',
              sharedIds: '17,54',
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['Åben Møde', 'Ingen Dyr']);
    });

    testWidgets('Unknown key is shown raw', (tester) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: 'XYZ',
              sharedIds: '',
            ),
          ],
        ),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['XYZ']);
      expect(chipColour(tester, 'XYZ'), darkChipColour);
    });

    testWidgets('Ambiguous lower-case key is not guessed', (tester) async {
      final bmlt =
          bmltServing(
              meetings: [
                aBmltMeetingJson(
                  id: 1,
                  weekday: 2,
                  municipality: 'Aarhus',
                  formats: 'se',
                  sharedIds: '',
                ),
              ],
            )
            ..serve(
              endpoint: BmltEndpoint.formatsDanish,
              reply: BmltRows(
                rows: [
                  aBmltFormatJson(id: 90, key: 'Se', name: 'Seniorer'),
                  aBmltFormatJson(id: 91, key: 'SE', name: 'Svensk'),
                ],
              ),
            )
            ..serve(
              endpoint: BmltEndpoint.formatsEnglish,
              reply: const BmltRows(rows: []),
            );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      expect(chipLabels(tester, 1), ['se']);
    });
  });

  group('Requirement: Formats popover', () {
    testWidgets('Popover lists formats with descriptions', (tester) async {
      final bmlt =
          bmltServing(
            meetings: [
              aBmltMeetingJson(
                id: 1,
                weekday: 2,
                name: 'Håb i Aarhus',
                municipality: 'Aarhus',
                formats: 'O,TC',
                sharedIds: '',
                rootServerUri: 'https://tomato.example/main_server',
              ),
            ],
          )..serve(
            endpoint: BmltEndpoint.formatsEnglish,
            reply: BmltRows(
              rows: [
                ...recordedFormatsEnJson(),
                aBmltFormatJson(
                  id: 99,
                  key: 'TC',
                  name: 'Temporarily Closed',
                  description: 'This meeting is closed for now.',
                  typeEnum: 'ALERT',
                  language: 'en',
                ),
              ],
            ),
          );
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: municipalityPath('Aarhus'),
      );
      addTearDown(app.dispose);
      await toggleDay(tester, 'monday');
      await openFormats(tester, 1);
      expect(inPopover(find.text('Meeting formats')), findsOneWidget);
      expect(inPopover(find.text('Håb i Aarhus')), findsOneWidget);
      expect(textsIn(tester, find.byKey(const Key('format-row-TC'))), [
        'TC',
        'Temporarily Closed',
        'This meeting is closed for now.',
      ]);
      expect(textsIn(tester, find.byKey(const Key('format-row-O'))), [
        'O',
        'Open',
        openDescription,
      ]);
      await tester.tap(find.byKey(const Key('formats-popover-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('formats-popover')), findsNothing);
    });
  });

  group('Requirement: Loading states', () {
    testWidgets('Loader text while searching', (tester) async {
      final bmlt = bmltServing(municipalities: ['Aarhus']);
      final held = bmlt.hold(endpoint: BmltEndpoint.municipalities);
      final app = await pumpMeetings(
        tester: tester,
        bmlt: bmlt,
        location: '/home',
      );
      addTearDown(app.dispose);
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('menu-meetings')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<NaIndeterminateBar>(
              find.byKey(const Key('global-loading-bar')),
            )
            .statusText,
        'Finding meetings…',
      );
      held.release();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
    });
  });

  group('Requirement: Content that stays Danish (localisation)', () {
    Future<AppHarness> pumpEnglishFormats(
      WidgetTester tester, {
      required String formats,
      required String sharedIds,
    }) async {
      final app = await pumpMeetings(
        tester: tester,
        location: municipalityPath('Aarhus'),
        bmlt: bmltServing(
          meetings: [
            aBmltMeetingJson(
              id: 1,
              weekday: 2,
              municipality: 'Aarhus',
              formats: formats,
              sharedIds: sharedIds,
            ),
          ],
        ),
      );
      await toggleDay(tester, 'monday');
      return app;
    }

    testWidgets('Formats follow the UI language', (tester) async {
      final app = await pumpEnglishFormats(
        tester,
        formats: 'BFID',
        sharedIds: '14',
      );
      addTearDown(app.dispose);
      expect(chipLabels(tester, 1), ['Just for Today']);
    });

    testWidgets('Danish-only format in English', (tester) async {
      final app = await pumpEnglishFormats(
        tester,
        formats: 'ST',
        sharedIds: '55',
      );
      addTearDown(app.dispose);
      expect(chipLabels(tester, 1), ['Stempelmøde']);
    });
  });
}
