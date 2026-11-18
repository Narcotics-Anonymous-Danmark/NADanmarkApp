import 'package:adapter_wordpress/adapter_wordpress.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

import 'media.dart';
import 'pump_app.dart';

typedef EventsApp = ({AppHarness app, WordPressMimic wordpress});

const RoutePath eventsPath = RoutePath('/events');
const RoutePath eventsHomePath = RoutePath('/home');

Future<EventsApp> pumpEventsApp({
  required WidgetTester tester,
  WordPressMimic? wordpress,
  RoutePath location = eventsPath,
  Map<String, String> storedValues = inEnglish,
  WordPressEndpoints endpoints = testWordPressEndpoints,
  AppSettle settleWith = AppSettle.idle,
}) async {
  final mimic = wordpress ?? WordPressMimic();
  final app = await pumpApp(
    tester: tester,
    initialLocation: location.value,
    settleWith: settleWith,
    container: realJftContainer(
      storedValues: storedValues,
      wordpress: mimic,
      wordpressEndpoints: endpoints,
    ),
  );
  addTearDown(app.dispose);
  switch (settleWith) {
    case AppSettle.idle:
      await drain(tester);
      await settle(tester);
    case AppSettle.frames:
      break;
  }
  return (app: app, wordpress: mimic);
}

WordPressMimic calendarOf(List<CalendarEventDto> events) =>
    WordPressMimic()..calendar = CalendarEvents(events: events);

Finder eventRow(EventSlug slug) => find.byKey(Key('event-row-${slug.page}'));

extension type const CardPosition(int index) {}

Finder homeEventCard(CardPosition position) =>
    find.byKey(Key('home-event-card-${position.index}'));

List<EventName> homeEventNames(WidgetTester tester) => List.unmodifiable(
  tester
      .widget<NaCarousel>(find.byKey(const Key('home-events-carousel')))
      .pages
      .whereType<HomeEventCard>()
      .map((card) => card.event.name),
);

extension type const ScreenY(double value) {}

ScreenY topOf(WidgetTester tester, Finder finder) =>
    ScreenY(tester.getTopLeft(finder).dy);
