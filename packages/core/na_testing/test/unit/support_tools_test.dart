@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

void main() {
  group('Gen', () {
    test('is reproducible for the same seed', () {
      final first = Gen(seed: 7);
      final second = Gen(seed: 7);
      expect(
        List.generate(5, (_) => first.integer(min: 1, max: 100)),
        List.generate(5, (_) => second.integer(min: 1, max: 100)),
      );
    });

    test('stays within bounds and picks from lists', () {
      final gen = Gen(seed: 1);
      final values = List.generate(200, (_) => gen.integer(min: 3, max: 5));
      expect(values.every((value) => value >= 3 && value <= 5), isTrue);
      expect(gen.decimal(min: 0, max: 1), inInclusiveRange(0, 1));
      expect(['a', 'b'], contains(gen.pick(from: ['a', 'b'])));
      expect(gen.word(length: 6), hasLength(6));
      expect(gen.describe(), 'Gen(seed: 1)');
    });

    test('reads its seed from the environment or falls back', () {
      expect(Gen.fromEnvironment().seed, isA<int>());
    });
  });

  group('KeyValueStoreMimic', () {
    test('records writes and removals', () async {
      final mimic = KeyValueStoreMimic.empty();
      await mimic.write(key: const StorageKey('language'), value: 'en');
      await mimic.remove(key: const StorageKey('language'));
      expect(mimic.writes, [const StorageKey('language')]);
      expect(mimic.removals, [const StorageKey('language')]);
      expect(mimic.snapshot, isEmpty);
    });

    test('lists keys by prefix from the seed', () async {
      final mimic = KeyValueStoreMimic(
        seeded: const {'mediaResume.book.a': '1', 'other': '2'},
      );
      expect(
        await mimic.keysWithPrefix(prefix: 'mediaResume.'),
        [const StorageKey('mediaResume.book.a')],
      );
      expect(
        await mimic.read(key: const StorageKey('other')),
        const StoredString(value: '2'),
      );
    });

    test('can be told to refuse writes', () async {
      final mimic = KeyValueStoreMimic.empty()..behaviour = WriteBehaviour.fail;
      final outcome = await mimic.write(
        key: const StorageKey('k'),
        value: 'v',
      );
      expect(outcome, isA<Err<StorageKey, StorageFailure>>());
    });
  });

  group('RecordingEventBus', () {
    test('records and forwards events', () async {
      final bus = RecordingEventBus();
      addTearDown(bus.dispose);
      final forwarded = bus.all.first;
      bus.publish(
        event: const LegacyMigrationCompleted(
          importedKeys: KeyCount(2),
          skippedKeys: KeyCount(0),
        ),
      );
      expect(bus.recordedOf<LegacyMigrationCompleted>(), hasLength(1));
      expect(bus.recordedOf<LanguageChanged>(), isEmpty);
      expect(await forwarded, isA<LegacyMigrationCompleted>());
    });
  });

  group('FakeClock', () {
    test('reports local time and zone from the test time', () {
      final time = TestTime.copenhagen(startAt: anInstant(hour: 8, minute: 30));
      final clock = FakeClock(time: time);
      expect(
        clock.localTimeNow(),
        aLocalTime(hour: HourOfDay(10), minute: MinuteOfHour(30)),
      );
      expect(clock.zone(), TimeZoneId.copenhagen);
    });
  });

  group('TestTime', () {
    test('notifies tick listeners and can forget them', () {
      final time = TestTime.copenhagen(startAt: anInstant());
      final seen = <Instant>[];
      void listener(Instant now) => seen.add(now);
      time
        ..addTickListener(listener: listener)
        ..advance(by: const Duration(seconds: 1))
        ..removeTickListener(listener: listener)
        ..advance(by: const Duration(seconds: 1));
      expect(seen, [anInstant(second: 1)]);
      expect(time.pendingActions, 0);
    });

    test('builds versions and dates through builders', () {
      expect(anAppVersion().versionCode, 1120000001);
      expect(aLocalDate().iso8601, '2026-09-10');
    });
  });

  group('TestContainer', () {
    test('accepts explicit time and seeded storage', () async {
      final harness = TestContainer.buildAt(
        time: TestTime.copenhagen(startAt: anInstant(hour: 6)),
        storedValues: const {'language': 'en'},
      );
      addTearDown(harness.dispose);
      expect(harness.read(clockProvider).now(), anInstant(hour: 6));
      expect(
        await harness.storage.read(key: const StorageKey('language')),
        const StoredString(value: 'en'),
      );
    });
  });
}
