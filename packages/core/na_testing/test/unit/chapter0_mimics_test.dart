@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/na_testing.dart';
import 'package:test/test.dart';

void main() {
  test('the settings mimic persists through the key-value mimic', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    final port = harness.read(settingsPortProvider);
    expect(await port.read(), Settings.defaults);
    final written = await port.write(
      settings: aSettings(language: Language.english, searchRadiusKm: 30),
    );
    expect(written, isA<Ok<Settings, StorageFailure>>());
    expect(harness.storage.snapshot['language'], 'en');
    expect(harness.storage.snapshot['searchRange'], '30');
    expect((await port.read()).searchRadius, const Km(30));
  });

  test('the settings mimic reports storage failures', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    harness.storage.behaviour = WriteBehaviour.fail;
    expect(
      await harness.read(settingsPortProvider).write(settings: aSettings()),
      isA<Err<Settings, StorageFailure>>(),
    );
  });

  test('legacy, jft and link mimics serve what they are told', () async {
    final harness = TestContainer.build(
      legacyStore: LegacyStoreFound(entries: aLegacyStoreDump()),
    );
    addTearDown(harness.dispose);
    expect(
      await harness.read(legacyStorePortProvider).readAll(),
      isA<LegacyStoreFound>(),
    );
    harness.legacyStore.read = const LegacyStoreAbsent();
    expect(
      await harness.read(legacyStorePortProvider).readAll(),
      const LegacyStoreAbsent(),
    );
    expect(harness.legacyStore.reads, 2);

    final calendar = await harness.read(jftPortProvider).load();
    expect(
      calendar.map(transform: (c) => c.entries.length),
      const Ok<int, Failure>(value: 366),
    );
    harness.jft.outcome = const Err(error: UnavailableFailure(what: 'asset'));
    expect(
      await harness.read(jftPortProvider).load(),
      isA<Err<JftCalendar, Failure>>(),
    );
    expect(harness.jft.loads, 2);

    final uri = Uri.parse('https://nadanmark.dk/');
    expect(
      await harness.read(externalLinksPortProvider).open(uri: uri),
      LinkOpening.opened,
    );
    expect(harness.links.opened, [uri]);
    expect(harness.read(appInfoProvider), anAppInfo());
  });

  test('builders carry realistic defaults', () {
    expect(aJftCalendar().missingDays, isEmpty);
    expect(aJftEntry().closing, isA<JftClosingWithLead>());
    expect(aLegacyStoreDump()['theme'], 'light');
    expect(aMigrationMarker().importedKeys, 4);
    expect(anAppInfo(buildType: 'dev').buildType, const BuildType('dev'));
  });
}
