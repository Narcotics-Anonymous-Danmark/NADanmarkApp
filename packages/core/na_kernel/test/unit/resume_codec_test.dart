@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/media.dart';

const ResumeCodec codec = ResumeCodec();
final Instant importTime = Instant(DateTime.utc(2026, 11, 4, 9));

Outcome<ResumePoint, DecodeFailure> decoded(String text) =>
    codec.decodePoint(text: text, fallbackTime: importTime);

void main() {
  group('ResumeCodec', () {
    test('a point survives an encode and decode round trip', () {
      final point = aPoint(updatedAt: Instant(DateTime.utc(2026, 5, 1, 10)));
      final text = codec.encodePoint(point: point);
      expect(
        text,
        '{"trackId":"https://example.dk/4.mp3","trackIndex":4,"position":120,'
        '"duration":600,"updatedAt":"2026-05-01T10:00:00.000Z"}',
      );
      expect(decoded(text), Ok<ResumePoint, DecodeFailure>(value: point));
    });

    test('an unknown length is not written', () {
      expect(
        codec.encodePoint(
          point: aPoint(
            length: const UnknownLength(),
            updatedAt: Instant(DateTime.utc(2026)),
          ),
        ),
        isNot(contains('duration')),
      );
    });

    test('numbers sent as text or fractions still read', () {
      expect(
        decoded('{"trackIndex":"4","position":120.7,"trackId":"u"}'),
        Ok<ResumePoint, DecodeFailure>(
          value: aPoint(
            trackId: const TrackId('u'),
            length: const UnknownLength(),
            updatedAt: importTime,
          ),
        ),
      );
    });

    test('malformed values are ignored', () {
      expect(
        decoded('{"trackIndex":"x","position":12}'),
        isA<Err<ResumePoint, DecodeFailure>>(),
      );
      expect(
        decoded('{"position":12}'),
        isA<Err<ResumePoint, DecodeFailure>>(),
      );
      expect(
        decoded('{"trackIndex":-1,"position":12}'),
        isA<Err<ResumePoint, DecodeFailure>>(),
      );
      expect(decoded('[1,2]'), isA<Err<ResumePoint, DecodeFailure>>());
      expect(decoded('not json'), isA<Err<ResumePoint, DecodeFailure>>());
      expect(
        decoded('{"trackIndex":1,"position":true}'),
        isA<Err<ResumePoint, DecodeFailure>>(),
      );
    });

    test('an index survives a round trip and drops bad entries', () {
      const book = PlaylistId('basic-text');
      final index = ResumeIndex.empty.withPoint(id: book, point: aPoint());
      final text = codec.encodeIndex(index: index);
      expect(codec.decodeIndex(text: text, fallbackTime: importTime), index);
      expect(
        codec.decodeIndex(
          text:
              '{"basic-text":${codec.encodePoint(point: aPoint())},'
              '"how-and-why":{"trackIndex":"x"},"x":3}',
          fallbackTime: importTime,
        ),
        index,
      );
      expect(
        codec.decodeIndex(text: '[]', fallbackTime: importTime),
        ResumeIndex.empty,
      );
    });
  });

  group('LenientWholeNumber', () {
    test('floors numbers and numeric text', () {
      const converter = LenientWholeNumber();
      expect(converter.fromJson(7), 7);
      expect(converter.fromJson(7.9), 7);
      expect(converter.fromJson(' 8.2 '), 8);
      expect(converter.fromJson(double.nan), isNull);
      expect(converter.fromJson('NaN'), isNull);
      expect(converter.fromJson('x'), isNull);
      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(3), 3);
    });
  });
}
