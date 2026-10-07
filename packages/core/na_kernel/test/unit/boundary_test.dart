@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
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
        event: const LegacyMigrationCompleted(
          importedKeys: KeyCount(1),
          skippedKeys: KeyCount(0),
        ),
      );
      expect(await first, isA<LegacyMigrationCompleted>());
    });
  });
}
