@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const SpeaksMapper mapper = SpeaksMapper();

Outcome<List<FeedGroup>, DecodeFailure> decoded(String body) => mapper.groups(
  json: jsonDecode(body),
  language: SpeakLanguage.english,
);

List<FeedGroup> groupsOf(String body) => switch (decoded(body)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('$error'),
};

void main() {
  group('SpeaksMapper', () {
    test('groups and entries map to feed values tagged with the language', () {
      final groups = groupsOf('''
        [{"title": "KOKNA - København", "speaks": [
          {"name": "Hovedspeak Sigi", "location": "KOKNA 30",
           "year": "2026", "audioUrl": " https://audio.test/a.mp3 "}
        ]}]''');
      expect(groups, [
        FeedGroup(
          title: const FeedText('KOKNA - København'),
          language: SpeakLanguage.english,
          entries: [
            FeedEntry(
              id: const PlaylistId('https://audio.test/a.mp3'),
              url: AudioUrl(Uri.parse('https://audio.test/a.mp3')),
              name: const FeedText('Hovedspeak Sigi'),
              location: const FeedText('KOKNA 30'),
              year: const FeedText('2026'),
            ),
          ],
        ),
      ]);
    });

    test('a numeric year reads as text and missing fields as empty', () {
      final entry = groupsOf('''
        [{"speaks": [{"year": 2015, "audioUrl": "https://audio.test/a.mp3"}]}]
      ''').single;
      expect(entry.title, const FeedText(''));
      expect(entry.entries.single.year, const FeedText('2015'));
      expect(entry.entries.single.name, const FeedText(''));
      expect(entry.entries.single.location, const FeedText(''));
    });

    test('a URL with spaces keeps its raw id and plays encoded', () {
      final entry = groupsOf('''
        [{"speaks": [{"audioUrl": "https://audio.test/KOKNA 30.wav"}]}]
      ''').single.entries.single;
      expect(entry.id, const PlaylistId('https://audio.test/KOKNA 30.wav'));
      expect(entry.url.uri.toString(), 'https://audio.test/KOKNA%2030.wav');
    });

    test('entries without an absolute audio URL are dropped', () {
      final entries = groupsOf('''
        [{"speaks": [
          {"audioUrl": ""}, {"name": "no url"}, {"audioUrl": "/relative.mp3"},
          {"audioUrl": "ftp://audio.test/a.mp3"},
          {"audioUrl": "http://audio.test/ok.mp3"}
        ]}]''').single.entries;
      expect(entries.map((entry) => entry.id), const [
        PlaylistId('http://audio.test/ok.mp3'),
      ]);
    });

    test('a group that does not decode is dropped', () {
      final groups = groupsOf('''
        ["text", {"title": "Bad", "speaks": "nope"}, {"title": "Good"}]
      ''');
      expect(groups.map((group) => group.title), const [FeedText('Good')]);
      expect(groups.single.entries, isEmpty);
    });

    test('an empty object is an empty feed', () {
      expect(groupsOf('{}'), isEmpty);
    });

    test('anything else is a decode failure', () {
      expect(decoded('"text"'), isA<Err<List<FeedGroup>, DecodeFailure>>());
      expect(
        decoded('{"code": "rest_forbidden"}'),
        isA<Err<List<FeedGroup>, DecodeFailure>>(),
      );
    });

    test('dtos round trip through toJson', () {
      const dto = SpeakGroupDto(
        title: 'KOKNA',
        speaks: [SpeakEntryDto(name: 'Anna', audioUrl: 'https://a.test/a')],
      );
      final again = SpeakGroupDto.fromJson(
        jsonDecode(jsonEncode(dto.toJson())) as WireObject,
      );
      expect(again.title, 'KOKNA');
      expect(again.speaks?.single.name, 'Anna');
      expect(again.speaks?.single.audioUrl, 'https://a.test/a');
    });
  });
}
