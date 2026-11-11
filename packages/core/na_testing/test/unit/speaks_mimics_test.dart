@Tags(['unit'])
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

const String base = 'https://wp.test/wp-json/wp/v2/speaks';

({WordPressMimic mimic, Dio dio}) wordPress() {
  final mimic = WordPressMimic();
  return (mimic: mimic, dio: Dio()..httpClientAdapter = mimic);
}

Future<Response<String>> getFeed({
  required Dio dio,
  required SpeakLanguage language,
  MimicCredentials credentials = testWordPressCredentials,
}) => dio.get<String>(
  '$base?excerpt[]=${language.excerpt.value}',
  options: Options(
    responseType: ResponseType.plain,
    headers: {'Authorization': credentials.header},
    validateStatus: (status) => true,
  ),
);

void main() {
  group('sample speaks', () {
    test('the sample catalogue has the documented shape', () {
      final catalog = sampleSpeakCatalog();
      expect(catalog.speaks, hasLength(12));
      expect(catalog.conventions.map((convention) => convention.label), const [
        ConventionLabel('KOKNA'),
        ConventionLabel('Konvent-camp Skanderborg'),
        ConventionLabel('Viborg online møder'),
        ConventionLabel('Blandede speak'),
        ConventionLabel('ECCNA'),
      ]);
      expect(
        sampleSpeakAt(slug: const SpeakSlug('kokna-30-hovedspeak-sigi')).title,
        const SpeakerTitle(name: SpeakerName('Sigi')),
      );
    });

    test('many speaks are numbered and spread over thirty years', () {
      final groups = manySpeaks(count: const RowCount(40));
      expect(groups.single.speaks, hasLength(40));
      expect(groups.single.speaks?.first.name, 'Speaker 000');
      expect(groups.single.speaks?.last.year, '1999');
    });

    test('builders default to one speak', () {
      expect(aSpeakGroupDto().speaks, hasLength(1));
      expect(aSpeakEntryDto().audioUrl, 'https://audio.test/speaks/anna.mp3');
    });
  });

  group('SpeaksFeedMimic', () {
    test('serves the sample per language and counts loads', () async {
      final mimic = SpeaksFeedMimic.sample();
      final danish = await mimic.feed(language: SpeakLanguage.danish);
      expect((danish as Ok<List<FeedGroup>, Failure>).value, hasLength(4));
      expect(mimic.loads, const CallCount(1));
    });

    test('fails both feeds and serves replacements', () async {
      final mimic = SpeaksFeedMimic.sample()..failBoth();
      expect(
        await mimic.feed(language: SpeakLanguage.english),
        const Err<List<FeedGroup>, Failure>(
          error: NetworkFailure(detail: 'en'),
        ),
      );
      mimic.serve(
        language: SpeakLanguage.english,
        outcome: const Ok(value: []),
      );
      expect(
        await mimic.feed(language: SpeakLanguage.english),
        const Ok<List<FeedGroup>, Failure>(value: []),
      );
    });

    test('a held feed answers after release', () async {
      final mimic = SpeaksFeedMimic.sample();
      final hold = mimic.hold(language: SpeakLanguage.danish);
      final answered = <SpeakLanguage>[];
      unawaited(
        mimic
            .feed(language: SpeakLanguage.danish)
            .then((_) => answered.add(SpeakLanguage.danish)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(answered, isEmpty);
      hold.release();
      await Future<void>.delayed(Duration.zero);
      expect(answered, [SpeakLanguage.danish]);
    });
  });

  group('WordPressMimic', () {
    test('serves the sample feed to authorised requests', () async {
      final subject = wordPress();
      final reply = await getFeed(
        dio: subject.dio,
        language: SpeakLanguage.english,
      );
      expect(reply.statusCode, 200);
      expect(reply.data, contains('Main speak John'));
      expect(
        subject.mimic.requestsFor(language: SpeakLanguage.english).single,
        isA<WordPressRequest>().having(
          (request) => request.authorisation,
          'authorisation',
          Authorisation.accepted,
        ),
      );
    });

    test('rejects wrong and missing credentials with 401', () async {
      final subject = wordPress();
      final wrong = await getFeed(
        dio: subject.dio,
        language: SpeakLanguage.danish,
        credentials: const MimicCredentials('test:nope'),
      );
      expect(wrong.statusCode, 401);
      final missing = await subject.dio.get<String>(
        '$base?excerpt[]=NA-SPEAKS-DK',
        options: Options(validateStatus: (status) => true),
      );
      expect(missing.statusCode, 401);
      expect(subject.mimic.requests.map((request) => request.authorisation), [
        Authorisation.rejected,
        Authorisation.missing,
      ]);
    });

    test('unknown routes are 404', () async {
      final subject = wordPress();
      final reply = await subject.dio.get<String>(
        'https://wp.test/wp-json/wp/v2/calendar',
        options: Options(validateStatus: (status) => true),
      );
      expect(reply.statusCode, 404);
    });

    test('replies with errors, empty objects and malformed bodies', () async {
      final subject = wordPress();
      subject.mimic
        ..serve(
          language: SpeakLanguage.danish,
          reply: const WordPressError(status: HttpStatus(500)),
        )
        ..serve(
          language: SpeakLanguage.english,
          reply: const WordPressMalformed(),
        );
      expect(
        (await getFeed(
          dio: subject.dio,
          language: SpeakLanguage.danish,
        )).statusCode,
        500,
      );
      expect(
        (await getFeed(dio: subject.dio, language: SpeakLanguage.english)).data,
        '<html>',
      );
      subject.mimic.serveBoth(reply: const WordPressEmptyObject());
      expect(
        (await getFeed(dio: subject.dio, language: SpeakLanguage.danish)).data,
        '{}',
      );
    });

    test('an unreachable server fails the connection', () async {
      final subject = wordPress();
      subject.mimic.serve(
        language: SpeakLanguage.danish,
        reply: const WordPressUnreachable(),
      );
      await expectLater(
        getFeed(dio: subject.dio, language: SpeakLanguage.danish),
        throwsA(isA<DioException>()),
      );
    });

    test('a held reply answers after release', () async {
      final subject = wordPress();
      final held = subject.mimic.hold(language: SpeakLanguage.danish);
      final reply = getFeed(dio: subject.dio, language: SpeakLanguage.danish);
      held.release();
      expect((await reply).data, contains('Hovedspeak Sigi'));
    });
  });
}
