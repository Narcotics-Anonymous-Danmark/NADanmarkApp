@Tags(['unit'])
library;

import 'dart:async';

import 'package:adapter_clock/adapter_clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  group('SystemClock', () {
    test('reports a consistent now, today, local time and zone', () {
      const clock = SystemClock(zoneName: TimeZoneId.copenhagen);
      final before = DateTime.now().toUtc();
      final now = clock.now();
      expect(
        now.utc.isBefore(before.subtract(const Duration(seconds: 5))),
        isFalse,
      );
      expect(clock.today().year, DateTime.now().year);
      expect(clock.localTimeNow().hour, inInclusiveRange(0, 23));
      expect(clock.zone(), TimeZoneId.copenhagen);
    });
  });

  group('DartTicker', () {
    test('emits the clock instant every period', () {
      fakeAsync((async) {
        final ticks = <Instant>[];
        const ticker = DartTicker(clock: SystemClock(zoneName: TimeZoneId.utc));
        final subscription = ticker
            .every(period: const Duration(seconds: 1))
            .listen(ticks.add);
        async.elapse(const Duration(milliseconds: 2500));
        unawaited(subscription.cancel());
        expect(ticks, hasLength(2));
      });
    });
  });

  group('clockOverrides', () {
    test('binds clock, ticker and scheduler', () {
      final container = ProviderContainer(
        overrides: clockOverrides(zone: TimeZoneId.copenhagen),
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider).zone(), TimeZoneId.copenhagen);
      expect(container.read(tickerProvider), isA<DartTicker>());
      expect(container.read(schedulerProvider), isA<DartScheduler>());
    });
  });
}
