@Tags(['unit'])
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

extension type const CalendarUrl(String value) {}

const CalendarUrl calendarUrl = CalendarUrl(
  'https://wp.test/wp-json/wp/v2/calendar?category-slug=bedringsarrangement',
);

({WordPressMimic mimic, Dio dio}) wordPress() {
  final mimic = WordPressMimic();
  return (mimic: mimic, dio: Dio()..httpClientAdapter = mimic);
}

Future<Response<String>> getCalendar({
  required Dio dio,
  MimicCredentials credentials = testWordPressCredentials,
  CalendarUrl url = calendarUrl,
}) => dio.get<String>(
  url.value,
  options: Options(
    responseType: ResponseType.plain,
    contentType: Headers.jsonContentType,
    headers: {'Authorization': credentials.header},
    validateStatus: (status) => true,
  ),
);

void main() {
  group('sample calendar', () {
    test('has five events in feed order with and without times', () {
      final events = calendarEventsOf(dtos: sampleCalendar);
      expect(events.map((event) => event.name), const [
        EventName('KOKNA 31'),
        EventName('Julemøde i Aarhus'),
        EventName('Nytårsfest'),
        EventName('Servicekonference'),
        EventName('NA Camp 2027'),
      ]);
      expect(events.first.thumbnail, isA<ThumbnailAt>());
      expect(events[2].start, const NoStartTime());
    });

    test('builders default to one timed event', () {
      final event = aCalendarEvent();
      expect(event.name, const EventName('Konvent'));
      expect(event.page, const EventSlug('konvent').pageUrl);
      expect(event.thumbnail, const NoThumbnail());
    });
  });

  group('EventsFeedMimic', () {
    test('serves the sample and records the category', () async {
      final mimic = EventsFeedMimic.sample();
      final outcome = await mimic.events(category: EventCategory.recovery);
      expect(outcome, isA<Ok<List<CalendarEvent>, Failure>>());
      expect(mimic.loads, const CallCount(1));
      expect(mimic.categories, [EventCategory.recovery]);
    });

    test('a held feed answers after release', () async {
      final mimic = EventsFeedMimic.sample();
      final hold = mimic.hold();
      final answers = <Outcome<List<CalendarEvent>, Failure>>[];
      unawaited(
        mimic.events(category: EventCategory.recovery).then(answers.add),
      );
      await Future<void>.delayed(Duration.zero);
      expect(answers, isEmpty);
      hold.release();
      await Future<void>.delayed(Duration.zero);
      expect(answers, hasLength(1));
    });
  });

  group('WordPressMimic calendar', () {
    test('serves the sample calendar with the request recorded', () async {
      final subject = wordPress();
      final response = await getCalendar(dio: subject.dio);
      expect(response.statusCode, 200);
      expect(response.data, contains('"event_name":"KOKNA 31"'));
      final request = subject.mimic.calendarRequests.single;
      expect(request.authorisation, Authorisation.accepted);
      expect(request.contentType, const MimicContentType('application/json'));
    });

    test('rejects missing credentials and unknown categories', () async {
      final subject = wordPress();
      final forbidden = await getCalendar(
        dio: subject.dio,
        credentials: const MimicCredentials('wrong:wrong'),
      );
      expect(forbidden.statusCode, 401);
      final unknown = await getCalendar(
        dio: subject.dio,
        url: const CalendarUrl(
          'https://wp.test/wp-json/wp/v2/calendar?category-slug=other',
        ),
      );
      expect(unknown.statusCode, 404);
    });

    test('serves replacements and holds', () async {
      final subject = wordPress();
      subject.mimic.calendar = CalendarEvents(events: [aCalendarEventDto()]);
      final served = await getCalendar(dio: subject.dio);
      expect(served.data, contains('"event_name":"Konvent"'));
      final held = subject.mimic.holdCalendar();
      final answers = <Response<String>>[];
      unawaited(getCalendar(dio: subject.dio).then(answers.add));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(answers, isEmpty);
      held.release();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(answers.single.data, contains('"event_name":"Konvent"'));
    });
  });
}
