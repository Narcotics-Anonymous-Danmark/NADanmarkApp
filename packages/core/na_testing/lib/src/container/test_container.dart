import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/domain_builders.dart';
import 'package:na_testing/src/builders/time_builders.dart';
import 'package:na_testing/src/events/recording_event_bus.dart';
import 'package:na_testing/src/jft/jft_mimic.dart';
import 'package:na_testing/src/legacy/legacy_store_mimic.dart';
import 'package:na_testing/src/links/external_links_mimic.dart';
import 'package:na_testing/src/settings/settings_store_mimic.dart';
import 'package:na_testing/src/storage/key_value_store_mimic.dart';
import 'package:na_testing/src/time/fake_clock.dart';
import 'package:na_testing/src/time/fake_scheduler.dart';
import 'package:na_testing/src/time/fake_ticker.dart';
import 'package:na_testing/src/time/test_time.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

final class TestContainer {
  TestContainer._({
    required this.container,
    required this.time,
    required this.events,
    required this.storage,
    required this.legacyStore,
    required this.jft,
    required this.links,
    required this.appInfo,
  });

  factory TestContainer.build({
    List<Override> extra = const [],
    Map<String, String> storedValues = const {},
    LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
    AppInfo appInfo = testAppInfo,
  }) => TestContainer.buildAt(
    time: TestTime.copenhagen(startAt: anInstant()),
    extra: extra,
    storedValues: storedValues,
    legacyStore: legacyStore,
    appInfo: appInfo,
  );

  factory TestContainer.buildAt({
    required TestTime time,
    List<Override> extra = const [],
    Map<String, String> storedValues = const {},
    LegacyStoreRead legacyStore = const LegacyStoreAbsent(),
    AppInfo appInfo = testAppInfo,
  }) {
    final testTime = time;
    final events = RecordingEventBus();
    final storage = KeyValueStoreMimic(seeded: storedValues);
    final legacy = LegacyStoreMimic(read: legacyStore);
    final jft = JftMimic.calendar(calendar: aJftCalendar());
    final links = ExternalLinksMimic.opening();
    final info = appInfo;
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FakeClock(time: testTime)),
        tickerProvider.overrideWithValue(FakeTicker(time: testTime)),
        schedulerProvider.overrideWithValue(FakeScheduler(time: testTime)),
        eventBusProvider.overrideWithValue(events),
        keyValueStorePortProvider.overrideWithValue(storage),
        settingsPortProvider.overrideWithValue(
          SettingsStoreMimic(storage: storage),
        ),
        legacyStorePortProvider.overrideWithValue(legacy),
        jftPortProvider.overrideWithValue(jft),
        externalLinksPortProvider.overrideWithValue(links),
        appInfoProvider.overrideWithValue(info),
        ...extra,
      ],
    );
    return TestContainer._(
      container: container,
      time: testTime,
      events: events,
      storage: storage,
      legacyStore: legacy,
      jft: jft,
      links: links,
      appInfo: info,
    );
  }

  final ProviderContainer container;
  final TestTime time;
  final RecordingEventBus events;
  final KeyValueStoreMimic storage;
  final LegacyStoreMimic legacyStore;
  final JftMimic jft;
  final ExternalLinksMimic links;
  final AppInfo appInfo;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  Future<void> dispose() async {
    container.dispose();
    await events.dispose();
  }
}
