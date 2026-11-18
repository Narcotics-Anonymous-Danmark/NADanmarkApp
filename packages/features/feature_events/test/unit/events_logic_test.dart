@Tags(['unit'])
library;

import 'package:feature_events/feature_events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import '../support/harness.dart';

void main() {
  group('EventsLoader', () {
    test('starts loading and maps the feed in order', () async {
      final harness = eventsHarness();
      expect(
        harness.read(eventsProvider),
        const Loading<List<CalendarEvent>>(),
      );
      expect(
        eventsIn(await loadedEvents(harness)),
        calendarEventsOf(dtos: sampleCalendar),
      );
      expect(harness.eventsFeed.categories, [EventCategory.recovery]);
    });

    test('the feed is fetched once per session', () async {
      final harness = eventsHarness();
      await loadedEvents(harness);
      await loadedEvents(harness);
      harness.read(homeEventsProvider);
      await flush();
      expect(harness.eventsFeed.loads, const CallCount(1));
    });

    test('the fetch runs inside a loading-events busy span', () async {
      final harness = eventsHarness();
      await loadedEvents(harness);
      expect(
        harness.events.recordedOf<BusyStarted>().map((e) => e.activity),
        [BusyActivity.loadingEvents],
      );
      expect(
        harness.events.recordedOf<BusyEnded>().map((e) => e.activity),
        [BusyActivity.loadingEvents],
      );
    });

    test('a failure is kept and retry fetches again', () async {
      final harness = eventsHarness();
      harness.eventsFeed.outcome = const Err(error: offline);
      expect(
        await loadedEvents(harness),
        const Failed<List<CalendarEvent>>(failure: offline),
      );
      harness.eventsFeed.outcome = Ok(value: [aCalendarEvent()]);
      final retry = harness.read(eventsProvider.notifier).retry();
      expect(
        harness.read(eventsProvider),
        const Loading<List<CalendarEvent>>(),
      );
      await retry;
      expect(eventsIn(harness.read(eventsProvider)), [aCalendarEvent()]);
      expect(harness.eventsFeed.loads, const CallCount(2));
    });

    test('retry does nothing while loading or loaded', () async {
      final harness = eventsHarness();
      final hold = harness.eventsFeed.hold();
      harness.read(eventsProvider);
      await harness.read(eventsProvider.notifier).retry();
      hold.release();
      await flush();
      await harness.read(eventsProvider.notifier).retry();
      expect(harness.eventsFeed.loads, const CallCount(1));
    });

    test('home takes the first three events', () async {
      final harness = eventsHarness();
      await loadedEvents(harness);
      expect(
        eventsIn(harness.read(homeEventsProvider)).map((e) => e.name),
        const [
          EventName('KOKNA 31'),
          EventName('Julemøde i Aarhus'),
          EventName('Nytårsfest'),
        ],
      );
    });
  });

  group('EventTexts', () {
    final timed = aCalendarEvent(
      date: const WireText('2026-10-03'),
      time: const WireText('19:30:00'),
    );
    final untimed = aCalendarEvent(
      date: const WireText('2026-10-03'),
      time: const WireText(''),
    );

    test('Row with time', () {
      expect(
        EventTexts(language: Language.danish).calendar(event: timed),
        const EventLine('03. okt. 2026 19:30'),
      );
      expect(
        EventTexts(language: Language.english).calendar(event: timed),
        const EventLine('03. Oct 2026 19:30'),
      );
    });

    test('Row without time', () {
      expect(
        EventTexts(language: Language.danish).calendar(event: untimed),
        const EventLine('03. okt. 2026'),
      );
    });
  });
}
