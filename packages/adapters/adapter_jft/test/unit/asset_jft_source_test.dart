@Tags(['unit'])
library;

import 'package:adapter_jft/adapter_jft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled asset holds one entry for every day of a leap year',
    () async {
      final outcome = await AssetJftSource(
        bundle: RepoAssetBundle.locate(),
      ).load();
      final calendar = switch (outcome) {
        Ok(:final value) => value,
        Err(:final error) => fail('asset failed to load: $error'),
      };
      expect(calendar.entries, hasLength(JftCalendar.expectedEntryCount));
      expect(calendar.missingDays, isEmpty);
      final first = calendar.entryFor(
        date: const LocalDate(year: 2026, month: 1, day: 1),
      );
      expect(first, isA<JftFound>());
      expect((first as JftFound).entry.title, 'Årvågenhed');
      expect(first.entry.closing, isA<JftClosingWithLead>());
    },
  );

  test('a missing asset is an unavailable failure', () async {
    final outcome = await AssetJftSource(bundle: _EmptyBundle()).load();
    expect(outcome, isA<Err<JftCalendar, Failure>>());
    expect(
      (outcome as Err<JftCalendar, Failure>).error,
      isA<UnavailableFailure>(),
    );
  });

  test('malformed json is a decode failure', () {
    expect(
      AssetJftSource.decode(text: 'nope'),
      isA<Err<JftCalendar, Failure>>(),
    );
    expect(
      AssetJftSource.decode(text: '{}'),
      isA<Err<JftCalendar, Failure>>(),
    );
    expect(
      AssetJftSource.decode(text: '[1]'),
      isA<Err<JftCalendar, Failure>>(),
    );
    expect(
      AssetJftSource.decode(text: '[{"day":"1","month":"may"}]'),
      isA<Err<JftCalendar, Failure>>(),
    );
  });

  test('jftOverrides binds the port', () {
    final container = ProviderContainer(
      overrides: jftOverrides(bundle: rootBundle),
    );
    addTearDown(container.dispose);
    expect(container.read(jftPortProvider), isA<AssetJftSource>());
  });
}

final class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Unable to load asset: $key');
}
