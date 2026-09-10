@Tags(['unit'])
library;

import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  group('port providers', () {
    test('every core port throws with its own name until bound', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final expectations = <ProviderListenable<Object>, String>{
        tickerProvider: 'Ticker',
        schedulerProvider: 'Scheduler',
        eventBusProvider: 'EventBus',
        keyValueStorePortProvider: 'KeyValueStorePort',
      };
      for (final entry in expectations.entries) {
        expect(
          () => container.read(entry.key),
          throwsA(
            isA<ProviderException>().having(
              (wrapped) => wrapped.exception.toString(),
              'message',
              contains('${entry.value} is not bound'),
            ),
          ),
        );
      }
    });
  });

  group('StoredValue', () {
    test('compares by value and describes itself', () {
      expect(const StoredString(value: 'a'), const StoredString(value: 'a'));
      expect(
        const StoredString(value: 'a').hashCode,
        const StoredString(value: 'a').hashCode,
      );
      expect(const StoredString(value: 'a').toString(), 'StoredString(a)');
      expect(const NothingStored(), const NothingStored());
      expect(const NothingStored().hashCode, const NothingStored().hashCode);
      expect(const NothingStored().toString(), 'NothingStored');
      expect(const StoredString(value: 'a'), isNot(const NothingStored()));
    });
  });
}
