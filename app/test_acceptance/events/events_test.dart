@Tags(['acceptance'])
library;

import 'package:adapter_wordpress/adapter_wordpress.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/cleantime.dart';
import '../support/events.dart';
import '../support/media.dart';
import '../support/pump_app.dart';

const EventSlug eventX = EventSlug('x');

void main() {
  group('Requirement: Calendar feed', () {
    testWidgets('Request carries basic auth', (tester) async {
      final page = await pumpEventsApp(
        tester: tester,
        wordpress: WordPressMimic(
          credentials: const MimicCredentials('user:pass'),
        ),
        endpoints: const WordPressEndpoints(
          base: WordPressBaseUrl('https://www.nadanmark.dk'),
          credentials: BasicAuth(credentials: BasicCredentials('user:pass')),
        ),
      );
      final request = page.wordpress.calendarRequests.single;
      expect(
        request.uri.toString(),
        'https://www.nadanmark.dk/wp-json/wp/v2/calendar'
        '?category-slug=bedringsarrangement',
      );
      expect(
        const MimicCredentials('user:pass').header,
        'Basic dXNlcjpwYXNz',
      );
      expect(request.authorisation, Authorisation.accepted);
      expect(request.contentType, const MimicContentType('application/json'));
    });

    testWidgets('Second page visit uses the cached list', (tester) async {
      final page = await pumpEventsApp(tester: tester);
      await openMenu(tester);
      await tester.tap(inMenu(find.text('Settings')));
      await settle(tester);
      await openMenu(tester);
      await tester.tap(inMenu(find.text('Events')));
      await drain(tester);
      await settle(tester);
      expect(pageText('KOKNA 31'), findsOneWidget);
      expect(page.wordpress.calendarRequests, hasLength(1));
    });

    testWidgets('Malformed events are skipped', (tester) async {
      await pumpEventsApp(
        tester: tester,
        wordpress: calendarOf([
          aCalendarEventDto(
            slug: const EventSlug('first'),
            name: const WireText('First'),
          ),
          aCalendarEventDto(
            slug: const EventSlug('second'),
            name: const WireText('Second'),
            date: const WireText('soon'),
          ),
          aCalendarEventDto(
            slug: const EventSlug('third'),
            name: const WireText('Third'),
          ),
        ]),
      );
      expect(pageText('First'), findsOneWidget);
      expect(pageText('Second'), findsNothing);
      expect(pageText('Third'), findsOneWidget);
    });
  });

  group('Requirement: Events page list', () {
    testWidgets('Row with time', (tester) async {
      await pumpEventsApp(
        tester: tester,
        storedValues: inDanish,
        wordpress: calendarOf([
          aCalendarEventDto(
            slug: eventX,
            date: const WireText('2026-10-03'),
            time: const WireText('19:30:00'),
          ),
        ]),
      );
      expect(
        find.descendant(
          of: eventRow(eventX),
          matching: find.text('03. okt. 2026 19:30'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Row without time or thumbnail', (tester) async {
      await pumpEventsApp(
        tester: tester,
        wordpress: calendarOf([
          aCalendarEventDto(
            slug: eventX,
            date: const WireText('2026-10-03'),
            time: const WireText(''),
          ),
        ]),
      );
      final row = eventRow(eventX);
      expect(
        find.descendant(of: row, matching: find.text('03. Oct 2026')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const Key('thumbnail-fallback')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.byKey(const Key('thumbnail-remote')),
        ),
        findsNothing,
      );
    });

    testWidgets('Loading bar while fetching', (tester) async {
      final wordpress = WordPressMimic();
      final held = wordpress.holdCalendar();
      await pumpEventsApp(
        tester: tester,
        wordpress: wordpress,
        settleWith: AppSettle.frames,
      );
      expect(
        tester
            .widget<NaIndeterminateBar>(
              find.byKey(const Key('global-loading-bar')),
            )
            .statusText,
        'Loading events…',
      );
      expect(find.byKey(const Key('events-loading')), findsOneWidget);
      held.release();
      await drain(tester);
      await settle(tester);
      expect(find.byKey(const Key('global-loading-bar')), findsNothing);
      expect(pageText('KOKNA 31'), findsOneWidget);
    });

    testWidgets('Empty feed', (tester) async {
      await pumpEventsApp(tester: tester, wordpress: calendarOf(const []));
      expect(pageText('No upcoming events'), findsOneWidget);
    });
  });

  group('Requirement: Open event', () {
    testWidgets('Tap opens the event page', (tester) async {
      final page = await pumpEventsApp(
        tester: tester,
        wordpress: WordPressMimic()
          ..calendar = const CalendarEvents(
            events: [
              CalendarEventDto(
                eventName: 'X',
                eventStartDate: '2026-10-03',
                url: 'https://nadanmark.dk/event/x',
              ),
            ],
          ),
      );
      await tester.tap(pageText('X'));
      await tester.pump();
      expect(page.app.links.openedInApp, [
        Uri.parse('https://nadanmark.dk/event/x'),
      ]);
    });
  });

  group('Requirement: Home preview', () {
    testWidgets('First three events', (tester) async {
      await pumpEventsApp(tester: tester, location: eventsHomePath);
      expect(homeEventNames(tester), const [
        EventName('KOKNA 31'),
        EventName('Julemøde i Aarhus'),
        EventName('Nytårsfest'),
      ]);
    });

    testWidgets('Card opens the Events page', (tester) async {
      await pumpEventsApp(tester: tester, location: eventsHomePath);
      await tester.scrollUntilVisible(
        homeEventCard(const CardPosition(0)),
        200,
        scrollable: inPage(find.byType(Scrollable)).first,
      );
      await tester.tap(homeEventCard(const CardPosition(0)));
      await settle(tester);
      expect(
        find.descendant(
          of: find.byType(NaHeaderBar),
          matching: find.text('Events'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('events-list')), findsOneWidget);
    });

    testWidgets('No events on Home', (tester) async {
      await pumpEventsApp(
        tester: tester,
        location: eventsHomePath,
        wordpress: calendarOf(const []),
      );
      expect(find.byKey(const Key('home-events-carousel')), findsNothing);
    });
  });

  group('Requirement: Failure handling', () {
    testWidgets('Offline events page', (tester) async {
      final wordpress = WordPressMimic()
        ..calendar = const WordPressUnreachable();
      await pumpEventsApp(tester: tester, wordpress: wordpress);
      expect(pageText('Could not load the events'), findsOneWidget);
      expect(pageText('TRY AGAIN'), findsOneWidget);
      wordpress.calendar = CalendarEvents(events: [aCalendarEventDto()]);
      await tester.tap(pageText('TRY AGAIN'));
      await drain(tester);
      await settle(tester);
      expect(wordpress.calendarRequests, hasLength(2));
      expect(pageText('Konvent'), findsOneWidget);
    });

    testWidgets('Offline Home', (tester) async {
      final wordpress = WordPressMimic()
        ..calendar = const WordPressError(status: HttpStatus(500));
      await pumpEventsApp(
        tester: tester,
        location: eventsHomePath,
        wordpress: wordpress,
        storedValues: {
          ...inEnglish,
          ...storedProfiles(entries: [aCleantimeProfile()]),
        },
      );
      expect(find.byKey(const Key('welcome-title')), findsOneWidget);
      expect(find.byKey(homeCarousel), findsOneWidget);
      expect(find.byKey(const Key('jft-preview-card')), findsOneWidget);
      expect(find.byKey(const Key('home-events-carousel')), findsNothing);
    });
  });
}
