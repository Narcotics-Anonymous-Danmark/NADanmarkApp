@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

JsonReader aReader({JsonMap json = const {'id': '42', 'name': 'Herning'}}) =>
    JsonReader(json: json, context: 'meeting');

void main() {
  group('JsonReader', () {
    test('reads strings and numeric strings as integers', () {
      expect(
        aReader().string(key: 'name'),
        const Ok<String, DecodeFailure>(value: 'Herning'),
      );
      expect(
        aReader().integer(key: 'id'),
        const Ok<int, DecodeFailure>(value: 42),
      );
    });

    test('reports the missing key with its context', () {
      expect(
        aReader().string(key: 'missing'),
        const Err<String, DecodeFailure>(
          error: DecodeFailure(detail: 'meeting.missing: expected string'),
        ),
      );
    });

    test('treats empty strings as absent', () {
      expect(
        aReader(json: const {'link': ''}).stringOr(
          key: 'link',
          whenPresent: (value) => 'present',
          whenAbsent: () => 'absent',
        ),
        'absent',
      );
    });

    test('decodes lists of objects and stops at the first bad item', () {
      final reader = aReader(
        json: const {
          'items': [
            {'id': 1},
            {'id': 'x'},
          ],
        },
      );
      final outcome = reader.listOf(
        key: 'items',
        decode: (item) => item.integer(key: 'id'),
      );
      expect(
        outcome,
        const Err<List<int>, DecodeFailure>(
          error: DecodeFailure(detail: 'meeting.items[1].id: expected integer'),
        ),
      );
    });
  });
}
