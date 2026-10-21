@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

const CleantimeProfilesCodec codec = CleantimeProfilesCodec();

List<CleantimeProfile> decoded({required String text}) =>
    switch (codec.decodeProfiles(text: text)) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('$error'),
    };

void main() {
  group('CleantimeProfilesCodec', () {
    test('profiles survive an encode and decode round trip', () {
      final profiles = [
        CleantimeProfile(
          name: const ProfileName('Anna'),
          cleanDate: aDate(year: 2020, month: 5, day: 3),
        ),
        CleantimeProfile(
          name: const ProfileName('Bo'),
          cleanDate: aDate(year: 2024, month: 2, day: 29),
        ),
      ];
      final text = codec.encodeProfiles(profiles: profiles);
      expect(
        text,
        '[{"name":"Anna","cleanDate":"2020-05-03"},'
        '{"name":"Bo","cleanDate":"2024-02-29"}]',
      );
      expect(decoded(text: text), profiles);
    });

    test('text that is not a list of profiles is a decode failure', () {
      expect(
        codec.decodeProfiles(text: '"oops"'),
        isA<Err<List<CleantimeProfile>, DecodeFailure>>(),
      );
      expect(
        codec.decodeProfiles(text: 'not json'),
        isA<Err<List<CleantimeProfile>, DecodeFailure>>(),
      );
    });

    test('entries with a blank name or a bad date are dropped', () {
      expect(
        decoded(
          text:
              '[{"name":" Anna ","cleanDate":"2020-05-03"}, '
              '{"name":"  ","cleanDate":"2020-05-03"}, '
              '{"name":"Bo","cleanDate":"2020-02-30"}, '
              '{"name":"Carl"}, 7]',
        ),
        [
          CleantimeProfile(
            name: const ProfileName('Anna'),
            cleanDate: aDate(year: 2020, month: 5, day: 3),
          ),
        ],
      );
    });

    test('the active index round trips and rejects text', () {
      expect(codec.encodeActive(index: const ProfileIndex(1)), '1');
      expect(
        codec.decodeActive(text: ' 1 '),
        const Ok<ProfileIndex, DecodeFailure>(value: ProfileIndex(1)),
      );
      expect(
        codec.decodeActive(text: 'one'),
        isA<Err<ProfileIndex, DecodeFailure>>(),
      );
    });
  });
}
