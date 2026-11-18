@Tags(['widget'])
library;

import 'package:feature_events/feature_events.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

const Widget page = SizedBox(height: 520, child: EventsBody());

final class Taps {
  CallCount count = const CallCount(0);

  void record() => count = count.next;
}

Finder rowOf(EventSlug slug) => find.byKey(Key('event-row-${slug.page}'));

void main() {
  setUpAll(loadNaFonts);

  group('EventsBody', () {
    testWidgets('lists every event with its calendar and town lines', (
      tester,
    ) async {
      final harness = eventsHarness();
      await pumpEvents(tester: tester, harness: harness, child: page);
      expect(find.text('KOKNA 31'), findsOneWidget);
      expect(find.text('05. dec. 2026 10:00'), findsOneWidget);
      expect(find.text('København'), findsOneWidget);
      expect(find.text('31. dec. 2026'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'events_list');
      await expectAccessible(tester);
    });

    testWidgets('a tapped row opens the event page in the app', (
      tester,
    ) async {
      final harness = eventsHarness();
      await pumpEvents(tester: tester, harness: harness, child: page);
      await tester.tap(rowOf(const EventSlug('julemode-aarhus')));
      await tester.pump();
      expect(harness.links.openedInApp, [
        Uri.parse(const EventSlug('julemode-aarhus').page),
      ]);
      expect(harness.links.opened, isEmpty);
    });

    testWidgets('loading shows placeholder rows', (tester) async {
      final harness = eventsHarness();
      final hold = harness.eventsFeed.hold();
      await pumpEvents(tester: tester, harness: harness, child: page);
      expect(find.byKey(const Key('events-loading')), findsOneWidget);
      hold.release();
      await tester.runAsync(flush);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('events-list')), findsOneWidget);
    });

    testWidgets('a failure offers to try again', (tester) async {
      final harness = eventsHarness();
      harness.eventsFeed.outcome = const Err(error: offline);
      await pumpEvents(tester: tester, harness: harness, child: page);
      expect(find.text('Kunne ikke hente arrangementer'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'events_error');
      await expectAccessible(tester);
      harness.eventsFeed.outcome = Ok(value: [aCalendarEvent()]);
      await tester.tap(find.text('PRØV IGEN'));
      await tester.runAsync(flush);
      await tester.pumpAndSettle();
      expect(find.text('Konvent'), findsOneWidget);
    });

    testWidgets('an empty feed says there are no upcoming events', (
      tester,
    ) async {
      final harness = eventsHarness();
      harness.eventsFeed.outcome = Ok(value: List.unmodifiable([]));
      await pumpEvents(
        tester: tester,
        harness: harness,
        child: page,
        language: Language.english,
      );
      expect(find.text('No upcoming events'), findsOneWidget);
      await expectGolden(finder: goldenTarget, name: 'events_empty');
      await expectAccessible(tester);
    });
  });

  group('EventsHomeCards', () {
    testWidgets('shows the first three events and reports taps', (
      tester,
    ) async {
      final harness = eventsHarness();
      final taps = Taps();
      await pumpEvents(
        tester: tester,
        harness: harness,
        child: EventsHomeCards(onTap: taps.record),
      );
      expect(find.byKey(const Key('home-event-card-0')), findsOneWidget);
      expect(
        tester
            .widget<NaCarousel>(find.byType(NaCarousel))
            .pages
            .whereType<HomeEventCard>()
            .map((card) => card.event.name),
        const [
          EventName('KOKNA 31'),
          EventName('Julemøde i Aarhus'),
          EventName('Nytårsfest'),
        ],
      );
      expect(find.text('Arrangementer'), findsWidgets);
      await expectGolden(finder: goldenTarget, name: 'events_home_card');
      await expectAccessible(tester);
      await tester.tap(find.byKey(const Key('home-event-card-0')));
      expect(taps.count, const CallCount(1));
    });

    for (final outcome in [
      const Err<List<CalendarEvent>, Failure>(error: offline),
      Ok<List<CalendarEvent>, Failure>(value: List.unmodifiable([])),
    ]) {
      testWidgets('renders nothing for $outcome', (tester) async {
        final harness = eventsHarness();
        harness.eventsFeed.outcome = outcome;
        await pumpEvents(
          tester: tester,
          harness: harness,
          child: EventsHomeCards(onTap: Taps().record),
        );
        expect(find.byType(HomeEventCard), findsNothing);
      });
    }
  });
}
