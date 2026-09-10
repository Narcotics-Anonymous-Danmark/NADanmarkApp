@Tags(['unit'])
library;

import 'package:feature_jft/feature_jft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  test('loads the entry for the clock date', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    await harness.read(jftControllerProvider.notifier).load();
    final state = harness.read(jftControllerProvider);
    expect(state, isA<Loaded<JftLookup>>());
    final lookup = (state as Loaded<JftLookup>).value as JftFound;
    expect(lookup.entry.day, 10);
    expect(lookup.entry.month, DanishMonth.september);
  });

  test('a failing port becomes Failed', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    harness.jft.outcome = const Err(error: UnavailableFailure(what: 'asset'));
    await harness.read(jftControllerProvider.notifier).load();
    expect(harness.read(jftControllerProvider), isA<Failed<JftLookup>>());
  });
}
