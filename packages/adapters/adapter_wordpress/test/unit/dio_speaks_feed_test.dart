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

({WordPressMimic mimic, DioSpeaksFeed feed}) adapter({
  WordPressEndpoints using = endpoints,
}) {
  final mimic = WordPressMimic();
  return (
    mimic: mimic,
    feed: DioSpeaksFeed(
      dio: Dio()..httpClientAdapter = mimic,
      endpoints: using,
    ),
  );
}

List<FeedGroup> groupsOf(Outcome<List<FeedGroup>, Failure> outcome) =>
    switch (outcome) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('$error'),
    };

void main() {
  group('Requirement: Feed', () {
    test('each language asks for its excerpt with Basic auth', () async {
      final subject = adapter();
      final danish = groupsOf(
        await subject.feed.feed(language: SpeakLanguage.danish),
      );
      final english = groupsOf(
        await subject.feed.feed(language: SpeakLanguage.english),
      );
      expect(danish.first.title, const FeedText('KOKNA - København'));
      expect(
        danish.every((group) => group.language == SpeakLanguage.danish),
        isTrue,
      );
      expect(english.first.language, SpeakLanguage.english);
      final requests = subject.mimic.requests;
      expect(requests.map((request) => request.uri.path), [
        '/wp-json/wp/v2/speaks',
        '/wp-json/wp/v2/speaks',
      ]);
      expect(
        requests.map((request) => request.uri.queryParameters['excerpt[]']),
        ['NA-SPEAKS-DK', 'NA-SPEAKS-EN'],
      );
      expect(
        requests.map((request) => request.authorisation),
        everyElement(Authorisation.accepted),
      );
    });

    test('the URL keeps excerpt[] literally', () {
      expect(
        endpoints.speaks(language: SpeakLanguage.english),
        'https://wp.test/wp-json/wp/v2/speaks?excerpt[]=NA-SPEAKS-EN',
      );
      expect(
        const WordPressEndpoints(
          base: WordPressBaseUrl('https://wp.test'),
          credentials: NoCredentials(),
        ).speaks(language: SpeakLanguage.danish),
        'https://wp.test/wp-json/wp/v2/speaks?excerpt[]=NA-SPEAKS-DK',
      );
    });

    test('empty credentials send no Authorization header', () async {
      final subject = adapter(
        using: WordPressEndpoints(
          base: const WordPressBaseUrl('https://wp.test'),
          credentials: WordPressCredentials.of(
            credentials: const BasicCredentials(' '),
          ),
        ),
      );
      final outcome = await subject.feed.feed(language: SpeakLanguage.danish);
      expect(outcome, isA<Err<List<FeedGroup>, Failure>>());
      expect(
        subject.mimic.requests.single.authorisation,
        Authorisation.missing,
      );
      expect(
        WordPressCredentials.of(credentials: const BasicCredentials('a:b')),
        isA<BasicAuth>(),
      );
    });

    test(
      'server errors and unreachable servers are network failures',
      () async {
        final subject = adapter();
        subject.mimic
          ..serve(
            language: SpeakLanguage.danish,
            reply: const WordPressError(status: HttpStatus(500)),
          )
          ..serve(
            language: SpeakLanguage.english,
            reply: const WordPressUnreachable(),
          );
        expect(
          await subject.feed.feed(language: SpeakLanguage.danish),
          isA<Err<List<FeedGroup>, Failure>>().having(
            (err) => err.error,
            'error',
            isA<NetworkFailure>().having(
              (failure) => failure.detail,
              'detail',
              endsWith('badResponse 500'),
            ),
          ),
        );
        expect(
          await subject.feed.feed(language: SpeakLanguage.english),
          isA<Err<List<FeedGroup>, Failure>>().having(
            (err) => err.error,
            'error',
            isA<NetworkFailure>(),
          ),
        );
      },
    );

    test('malformed bodies are decode failures', () async {
      final subject = adapter();
      subject.mimic.serve(
        language: SpeakLanguage.danish,
        reply: const WordPressMalformed(),
      );
      expect(
        await subject.feed.feed(language: SpeakLanguage.danish),
        isA<Err<List<FeedGroup>, Failure>>().having(
          (err) => err.error,
          'error',
          isA<DecodeFailure>(),
        ),
      );
    });

    test('an empty object is an empty feed', () async {
      final subject = adapter();
      subject.mimic.serveBoth(reply: const WordPressEmptyObject());
      expect(
        groupsOf(await subject.feed.feed(language: SpeakLanguage.english)),
        isEmpty,
      );
    });

    test('the overrides bind the port', () {
      final container = ProviderContainer(
        overrides: wordpressOverrides(dio: Dio(), endpoints: endpoints),
      );
      addTearDown(container.dispose);
      expect(container.read(speaksFeedPortProvider), isA<DioSpeaksFeed>());
    });
  });
}
