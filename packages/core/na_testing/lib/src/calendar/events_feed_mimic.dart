import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';
import 'package:na_testing/src/calendar/event_builders.dart';

final class EventsFeedHold {
  EventsFeedHold();

  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();
}

sealed class EventsFeedPause {
  const EventsFeedPause();
}

final class EventsFeedFlowing extends EventsFeedPause {
  const EventsFeedFlowing();
}

final class EventsFeedHeld extends EventsFeedPause {
  const EventsFeedHeld({required this.hold});

  final EventsFeedHold hold;
}

final class EventsFeedMimic implements EventsFeedPort {
  EventsFeedMimic({required this.outcome});

  factory EventsFeedMimic.sample() => EventsFeedMimic(
    outcome: Ok(value: calendarEventsOf(dtos: sampleCalendar)),
  );

  Outcome<List<CalendarEvent>, Failure> outcome;
  EventsFeedPause _pause = const EventsFeedFlowing();
  final List<EventCategory> categories = [];
  CallCount loads = const CallCount(0);

  EventsFeedHold hold() {
    final hold = EventsFeedHold();
    _pause = EventsFeedHeld(hold: hold);
    return hold;
  }

  @override
  Future<Outcome<List<CalendarEvent>, Failure>> events({
    required EventCategory category,
  }) async {
    loads = loads.next;
    categories.add(category);
    switch (_pause) {
      case EventsFeedHeld(:final hold):
        _pause = const EventsFeedFlowing();
        await hold._release.future;
      case EventsFeedFlowing():
        break;
    }
    return outcome;
  }
}
