import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

typedef EventsState = LoadResult<List<CalendarEvent>>;

final NotifierProvider<EventsLoader, EventsState> eventsProvider =
    NotifierProvider(EventsLoader.new);

final class EventsLoader extends Notifier<EventsState> {
  static const int homeCardCount = 3;

  @override
  EventsState build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> retry() async {
    switch (state) {
      case Failed():
        state = const Loading();
        await _load();
      case Loading() || Loaded():
        return;
    }
  }

  Future<void> _load() async {
    final outcome = await BusyTracker(bus: ref.read(eventBusProvider)).track(
      activity: BusyActivity.loadingEvents,
      work: () => ref
          .read(eventsFeedPortProvider)
          .events(category: EventCategory.recovery),
    );
    if (!ref.mounted) {
      return;
    }
    state = LoadResult.fromOutcome(outcome: outcome);
  }
}

final Provider<LoadResult<List<CalendarEvent>>> homeEventsProvider = Provider(
  (ref) => ref
      .watch(eventsProvider)
      .map(
        transform: (events) => List<CalendarEvent>.unmodifiable(
          events.take(EventsLoader.homeCardCount),
        ),
      ),
);
