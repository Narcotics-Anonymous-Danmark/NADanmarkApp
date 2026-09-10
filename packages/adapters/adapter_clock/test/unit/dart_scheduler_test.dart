@Tags(['unit'])
library;

import 'package:adapter_clock/adapter_clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('DartScheduler', () {
    test('runs a delayed action once', () {
      fakeAsync((async) {
        final calls = <int>[];
        const DartScheduler().after(
          delay: const Duration(seconds: 1),
          action: () => calls.add(1),
        );
        async.elapse(const Duration(seconds: 2));
        expect(calls, [1]);
      });
    });

    test('debounces to the last call inside the window', () {
      fakeAsync((async) {
        final calls = <String>[];
        final debouncer = const DartScheduler().debounce(
          window: const Duration(milliseconds: 300),
        );
        debouncer(action: () => calls.add('first'));
        async.elapse(const Duration(milliseconds: 100));
        debouncer(action: () => calls.add('second'));
        async.elapse(const Duration(milliseconds: 400));
        expect(calls, ['second']);
        debouncer.dispose();
      });
    });

    test('cancels a periodic action', () {
      fakeAsync((async) {
        final calls = <int>[];
        final cancellation = const DartScheduler().periodic(
          period: const Duration(seconds: 1),
          action: () => calls.add(calls.length),
        );
        async.elapse(const Duration(milliseconds: 2500));
        cancellation.cancel();
        async.elapse(const Duration(seconds: 5));
        expect(calls, [0, 1]);
      });
    });
  });
}
