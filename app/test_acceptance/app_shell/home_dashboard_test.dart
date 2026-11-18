@Tags(['acceptance'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_testing/na_testing.dart';

import '../support/cleantime.dart';
import '../support/events.dart';
import '../support/media.dart';

const Key welcome = Key('welcome-title');
const Key jftCard = Key('jft-preview-card');
const Key eventsCarousel = Key('home-events-carousel');

void main() {
  group('Requirement: Home dashboard', () {
    testWidgets('Dashboard order', (tester) async {
      await pumpEventsApp(
        tester: tester,
        location: eventsHomePath,
        wordpress: calendarOf(sampleCalendar.take(3).toList()),
        storedValues: {
          ...inEnglish,
          ...storedProfiles(entries: [aCleantimeProfile()]),
        },
      );
      final tops = [
        find.byKey(welcome),
        find.byKey(homeCarousel),
        find.byKey(jftCard),
        find.byKey(eventsCarousel),
      ].map((finder) => topOf(tester, finder).value).toList();
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.text('Narcotics Anonymous Denmark'), findsOneWidget);
      expect(find.text('Helpline: 70 20 01 85'), findsOneWidget);
    });

    testWidgets('Dashboard without profiles or events', (tester) async {
      await pumpEventsApp(
        tester: tester,
        location: eventsHomePath,
        wordpress: calendarOf(const []),
      );
      expect(find.byKey(welcome), findsOneWidget);
      expect(find.byKey(jftCard), findsOneWidget);
      expect(find.byKey(homeCarousel), findsNothing);
      expect(find.byKey(eventsCarousel), findsNothing);
    });
  });
}
