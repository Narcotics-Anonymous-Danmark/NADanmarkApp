@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  const translator = LegacySettingsTranslator();

  test('valid settings are copied', () {
    final result = translator.translate(
      entries: {
        'language': 'en',
        'firstday': 'su',
        'searchRange': 30,
        'cleanTimeUnitSort': 'dmy',
      },
    );
    expect(
      result.settings,
      const Settings(
        language: Language.english,
        firstDayOfWeek: FirstDayOfWeek.sunday,
        cleanTimeUnitOrder: CleanTimeUnitOrder.daysMonthsYears,
        searchRadius: Km(30),
      ),
    );
    expect(result.importedKeys, [
      'language',
      'firstday',
      'searchRange',
      'cleanTimeUnitSort',
    ]);
    expect(result.skippedKeys, isEmpty);
  });

  test('one bad value does not block the rest', () {
    final result = translator.translate(
      entries: {'language': 'en', 'searchRange': 'oops', 'firstday': 42},
    );
    expect(result.settings.language, Language.english);
    expect(result.settings.searchRadius, const Km(15));
    expect(result.settings.firstDayOfWeek, FirstDayOfWeek.monday);
    expect(result.importedKeys, ['language']);
    expect(result.skippedKeys, ['firstday', 'searchRange']);
  });

  test('theme is dropped and counted as skipped, unknown keys are ignored', () {
    final result = translator.translate(
      entries: {'theme': 'dark', 'cleanDateProfiles': <Object>[], 'x': 1},
    );
    expect(result.settings, Settings.defaults);
    expect(result.importedKeys, isEmpty);
    expect(result.skippedKeys, ['theme']);
  });

  test('numeric strings and integral doubles count as search ranges', () {
    expect(
      translator
          .translate(entries: {'searchRange': '25'})
          .settings
          .searchRadius,
      const Km(25),
    );
    expect(
      translator
          .translate(entries: {'searchRange': 40.0})
          .settings
          .searchRadius,
      const Km(40),
    );
    expect(
      translator.translate(entries: {'searchRange': 60}).skippedKeys,
      ['searchRange'],
    );
  });

  test('translation is a pure function', () {
    const entries = {'language': 'da', 'firstday': 'mo', 'theme': 'x'};
    expect(
      translator.translate(entries: entries),
      translator.translate(entries: entries),
    );
  });
}
