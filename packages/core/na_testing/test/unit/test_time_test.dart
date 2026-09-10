@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

void main() {
  group('TestTime with fakes', () {
    test('advancing fires due actions in order and moves the clock', () {
      final time = TestTime.copenhagen(startAt: anInstant(hour: 10));
      final scheduler = FakeScheduler(time: time);
      final clock = FakeClock(time: time);
      final log = <String>[];
      scheduler
        ..after(delay: const Duration(seconds: 5), action: () => log.add('b'))
        ..after(delay: const Duration(seconds: 1), action: () => log.add('a'));
      time.advance(by: const Duration(seconds: 10));
      expect(log, ['a', 'b']);
      expect(clock.now(), anInstant(hour: 10, second: 10));
    });

    test('periodic actions repeat until cancelled', () {
      final time = TestTime.copenhagen(startAt: anInstant());
      var count = 0;
      final cancellation = FakeScheduler(time: time).periodic(
        period: const Duration(seconds: 1),
        action: () => count++,
      );
      time.advance(by: const Duration(milliseconds: 3500));
      cancellation.cancel();
      time.advance(by: const Duration(seconds: 10));
      expect(count, 3);
    });

    test('debounce keeps only the last action inside the window', () {
      final time = TestTime.copenhagen(startAt: anInstant());
      final debouncer = FakeScheduler(
        time: time,
      ).debounce(window: const Duration(milliseconds: 300));
      final log = <String>[];
      debouncer(action: () => log.add('first'));
      time.advance(by: const Duration(milliseconds: 100));
      debouncer(action: () => log.add('second'));
      time.advance(by: const Duration(seconds: 1));
      expect(log, ['second']);
    });

    test('ticker emits the current instant each period', () async {
      final time = TestTime.copenhagen(startAt: anInstant());
      final ticks = <Instant>[];
      final subscription = FakeTicker(
        time: time,
      ).every(period: const Duration(seconds: 1)).listen(ticks.add);
      time.advance(by: const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      expect(ticks, [anInstant(second: 1), anInstant(second: 2)]);
    });

    test('today follows the local offset', () {
      final time = TestTime.copenhagen(startAt: anInstant(hour: 23));
      expect(FakeClock(time: time).today(), aLocalDate(day: 11));
    });
  });

  group('TestContainer', () {
    test('binds every core port to a fake', () async {
      final harness = TestContainer.build();
      addTearDown(harness.dispose);
      harness
          .read(eventBusProvider)
          .publish(
            event: const LanguageChanged(language: Language.english),
          );
      expect(harness.events.recordedOf<LanguageChanged>(), hasLength(1));
      expect(
        await harness
            .read(keyValueStorePortProvider)
            .read(
              key: const StorageKey('missing'),
            ),
        const NothingStored(),
      );
    });
  });
}
