@Tags(['unit'])
library;

import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';
import 'package:riverpod/misc.dart';

void main() {
  test(
    'load reads the store, persists the resolved values and exposes them',
    () async {
      final harness = TestContainer.build(storedValues: {'language': 'en'});
      addTearDown(harness.dispose);
      expect(
        harness.read(settingsControllerProvider),
        const SettingsNotLoaded(),
      );
      expect(
        () => harness.read(currentLanguageProvider),
        throwsA(isA<ProviderException>()),
      );
      await harness.read(settingsControllerProvider.notifier).load();
      expect(harness.read(currentLanguageProvider), Language.english);
      expect(harness.storage.snapshot['firstday'], 'mo');
      expect(harness.events.recorded, isEmpty);
    },
  );

  test('changing a setting persists it and publishes events', () async {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    final controller = harness.read(settingsControllerProvider.notifier);
    await controller.load();
    await controller.changeLanguage(language: Language.english);
    await controller.changeFirstDayOfWeek(firstDay: FirstDayOfWeek.sunday);
    await controller.changeCleanTimeUnitOrder(
      order: CleanTimeUnitOrder.daysMonthsYears,
    );
    await controller.changeSearchRadius(radius: const Km(30));
    expect(harness.storage.snapshot, {
      'language': 'en',
      'firstday': 'su',
      'cleanTimeUnitSort': 'dmy',
      'searchRange': '30',
    });
    expect(harness.events.recordedOf<SettingsChanged>(), hasLength(4));
    expect(harness.events.recordedOf<LanguageChanged>(), hasLength(1));
    expect(
      harness.read(currentSettingsProvider),
      aSettings(
        language: Language.english,
        firstDayOfWeek: FirstDayOfWeek.sunday,
        cleanTimeUnitOrder: CleanTimeUnitOrder.daysMonthsYears,
        searchRadiusKm: 30,
      ),
    );
  });

  test(
    'a storage failure is surfaced and the stored values stay in use',
    () async {
      final harness = TestContainer.build(storedValues: {'language': 'en'});
      addTearDown(harness.dispose);
      harness.storage.behaviour = WriteBehaviour.fail;
      final controller = harness.read(settingsControllerProvider.notifier);
      await controller.load();
      expect(harness.read(settingsControllerProvider), isA<SettingsUnsaved>());
      expect(harness.read(currentLanguageProvider), Language.english);
      await controller.changeLanguage(language: Language.danish);
      expect(controller.current.language, Language.english);
    },
  );

  test('settings compare by state', () {
    expect(const SettingsNotLoaded(), const SettingsNotLoaded());
    expect(
      const SettingsReady(settings: Settings.defaults),
      const SettingsReady(settings: Settings.defaults),
    );
    expect(
      const SettingsUnsaved(
        settings: Settings.defaults,
        failure: StorageFailure(detail: 'x'),
      ).hashCode,
      const SettingsUnsaved(
        settings: Settings.defaults,
        failure: StorageFailure(detail: 'x'),
      ).hashCode,
    );
  });

  test('the radius draft tracks a drag and clears on release', () {
    final harness = TestContainer.build();
    addTearDown(harness.dispose);
    final draft = harness.read(searchRadiusDraftProvider.notifier);
    expect(harness.read(searchRadiusDraftProvider), const NoDraft());
    draft.drag(radius: const Km(22));
    expect(harness.read(searchRadiusDraftProvider), isA<Dragging>());
    draft.release();
    expect(harness.read(searchRadiusDraftProvider), const NoDraft());
  });
}
