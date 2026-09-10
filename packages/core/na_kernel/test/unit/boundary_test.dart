@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

JsonReader aReader({required JsonMap json}) =>
    JsonReader(json: json, context: 'root');

void main() {
  group('JsonReader extras', () {
    test('reads whole doubles as integers and rejects fractions', () {
      expect(
        aReader(json: const {'n': 4.0}).integer(key: 'n'),
        const Ok<int, DecodeFailure>(value: 4),
      );
      expect(
        aReader(json: const {'n': 4.5}).integer(key: 'n'),
        isA<Err<int, DecodeFailure>>(),
      );
      expect(
        aReader(json: const {'n': 'x'}).integer(key: 'n'),
        isA<Err<int, DecodeFailure>>(),
      );
      expect(
        aReader(json: const {'n': 7}).string(key: 'n'),
        const Ok<String, DecodeFailure>(value: '7'),
      );
    });

    test('reads decimals from numbers and strings', () {
      expect(
        aReader(json: const {'d': 1}).decimal(key: 'd'),
        const Ok<double, DecodeFailure>(value: 1),
      );
      expect(
        aReader(json: const {'d': '2.5'}).decimal(key: 'd'),
        const Ok<double, DecodeFailure>(value: 2.5),
      );
      expect(
        aReader(json: const {'d': 'x'}).decimal(key: 'd'),
        isA<Err<double, DecodeFailure>>(),
      );
      expect(
        aReader(json: const {}).decimal(key: 'd'),
        isA<Err<double, DecodeFailure>>(),
      );
    });

    test('reads nested objects with an extended context', () {
      final nested = aReader(
        json: const {
          'meta': {'id': 1},
        },
      ).object(key: 'meta');
      expect(
        nested.map(transform: (reader) => reader.context),
        const Ok<String, DecodeFailure>(value: 'root.meta'),
      );
      expect(
        aReader(json: const {'meta': 1}).object(key: 'meta'),
        isA<Err<JsonReader, DecodeFailure>>(),
      );
    });

    test('reports present strings and non-list values', () {
      expect(
        aReader(json: const {'k': 'v'}).stringOr(
          key: 'k',
          whenPresent: (value) => value,
          whenAbsent: () => 'none',
        ),
        'v',
      );
      expect(
        aReader(json: const {'items': 'nope'}).listOf(
          key: 'items',
          decode: (item) => item.integer(key: 'id'),
        ),
        isA<Err<List<int>, DecodeFailure>>(),
      );
      expect(
        aReader(
          json: const {
            'items': [1],
          },
        ).listOf(
          key: 'items',
          decode: (item) => item.integer(key: 'id'),
        ),
        const Err<List<int>, DecodeFailure>(
          error: DecodeFailure(detail: 'root.items[0] is not an object'),
        ),
      );
      expect(
        aReader(
              json: const {
                'items': [
                  {'id': 3},
                ],
              },
            )
            .listOf(
              key: 'items',
              decode: (item) => item.integer(key: 'id'),
            )
            .map(transform: (items) => items.join(',')),
        const Ok<String, DecodeFailure>(value: '3'),
      );
    });
  });

  group('bridgeNullable', () {
    test('routes present and absent values', () {
      expect(
        bridgeNullable<int, String>(
          value: 1,
          whenPresent: (value) => 'has $value',
          whenAbsent: () => 'none',
        ),
        'has 1',
      );
      expect(
        bridgeNullable<int, String>(
          value: null,
          whenPresent: (value) => 'has $value',
          whenAbsent: () => 'none',
        ),
        'none',
      );
    });
  });

  group('BroadcastEventBus all', () {
    test('exposes every event', () async {
      final bus = BroadcastEventBus();
      addTearDown(bus.dispose);
      final first = bus.all.first;
      bus.publish(
        event: const LegacyMigrationCompleted(importedKeys: 1, skippedKeys: 0),
      );
      expect(await first, isA<LegacyMigrationCompleted>());
    });
  });
}
