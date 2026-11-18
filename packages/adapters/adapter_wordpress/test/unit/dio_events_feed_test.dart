@Tags(['unit'])
library;

import 'package:adapter_wordpress/adapter_wordpress.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/riverpod.dart';

const WordPressEndpoints endpoints = WordPressEndpoints(
  base: WordPressBaseUrl('https://wp.test/'),
  credentials: BasicAuth(credentials: BasicCredentials('test:test')),
);

({WordPressMimic mimic, DioEventsFeed feed}) adapter({
  WordPressEndpoints using = endpoints,
  MimicCredentials credentials = testWordPressCredentials,
}) {
  final mimic = WordPressMimic(credentials: credentials);
  return (
    mimic: mimic,
    feed: DioEventsFeed(
      dio: Dio()..httpClientAdapter = mimic,
      endpoints: using,
    ),
  );
}

Future<Outcome<List<CalendarEvent>, Failure>> load(DioEventsFeed feed) =>
    feed.events(category: EventCategory.recovery);

List<CalendarEvent> eventsOf(Outcome<List<CalendarEvent>, Failure> outcome) =>
    switch (outcome) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('$error'),
    };

void main() {
  group('Requirement: Calendar feed', () {
    test('Request carries basic auth', () async {
      final subject = adapter(
        using: const WordPressEndpoints(
          base: WordPressBaseUrl('https://www.nadanmark.dk'),
          credentials: BasicAuth(credentials: BasicCredentials('user:pass')),
        ),
        credentials: const MimicCredentials('user:pass'),
      );
      final outcome = await load(subject.feed);
      expect(outcome, isA<Ok<List<CalendarEvent>, Failure>>());
      final request = subject.mimic.calendarRequests.single;
      expect(
        request.uri.toString(),
        'https://www.nadanmark.dk/wp-json/wp/v2/calendar'
        '?category-slug=bedringsarrangement',
      );
      expect(request.authorisation, Authorisation.accepted);
      expect(const MimicCredentials('user:pass').header, 'Basic dXNlcjpwYXNz');
      expect(request.contentType, const MimicContentType('application/json'));
    });

    test('maps the sample calendar in feed order', () async {
      expect(
        eventsOf(await load(adapter().feed)),
        calendarEventsOf(dtos: sampleCalendar),
      );
    });

    test('empty credentials send no Authorization header', () async {
      final subject = adapter(
        using: const WordPressEndpoints(
          base: WordPressBaseUrl('https://wp.test'),
          credentials: NoCredentials(),
        ),
      );
      final outcome = await load(subject.feed);
      expect(outcome, isA<Err<List<CalendarEvent>, Failure>>());
      expect(
        subject.mimic.calendarRequests.single.authorisation,
        Authorisation.missing,
      );
    });

    test(
      'server errors and unreachable servers are network failures',
      () async {
        final subject = adapter();
        subject.mimic.calendar = const WordPressError(status: HttpStatus(500));
        expect(
          await load(subject.feed),
          isA<Err<List<CalendarEvent>, Failure>>().having(
            (err) => err.error,
            'error',
            isA<NetworkFailure>(),
          ),
        );
        subject.mimic.calendar = const WordPressUnreachable();
        expect(
          await load(subject.feed),
          isA<Err<List<CalendarEvent>, Failure>>().having(
            (err) => err.error,
            'error',
            isA<NetworkFailure>(),
          ),
        );
      },
    );

    test('malformed bodies are decode failures, {} is empty', () async {
      final subject = adapter();
      subject.mimic.calendar = const WordPressMalformed();
      expect(
        await load(subject.feed),
        isA<Err<List<CalendarEvent>, Failure>>().having(
          (err) => err.error,
          'error',
          isA<DecodeFailure>(),
        ),
      );
      subject.mimic.calendar = const WordPressEmptyObject();
      expect(eventsOf(await load(subject.feed)), isEmpty);
    });

    test('wordpressOverrides binds the events feed', () {
      final container = ProviderContainer(
        overrides: wordpressOverrides(dio: Dio(), endpoints: endpoints),
      );
      addTearDown(container.dispose);
      expect(container.read(eventsFeedPortProvider), isA<DioEventsFeed>());
    });
  });
}
