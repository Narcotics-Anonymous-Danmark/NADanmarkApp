@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

const translator = LegacySettingsTranslator();

LegacySettingsTranslation translated({required WireObject dump}) =>
    translator.translate(dump: LegacyStoreDumpDto.fromJson(dump));

void main() {
  test('valid settings are copied', () {
    final result = translated(
      dump: {
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
      SettingKeys.language,
      SettingKeys.firstDayOfWeek,
      SettingKeys.searchRadius,
      SettingKeys.cleanTimeUnitOrder,
    ]);
    expect(result.skippedKeys, isEmpty);
  });

  test('one bad value does not block the rest', () {
    final result = translated(
      dump: {'language': 'en', 'searchRange': 'oops', 'firstday': 42},
    );
    expect(result.settings.language, Language.english);
    expect(result.settings.searchRadius, const Km(15));
    expect(result.settings.firstDayOfWeek, FirstDayOfWeek.monday);
    expect(result.importedKeys, [SettingKeys.language]);
    expect(result.skippedKeys, [
      SettingKeys.firstDayOfWeek,
      SettingKeys.searchRadius,
    ]);
  });

  test('theme is dropped and counted as skipped, unknown keys are ignored', () {
    final result = translated(
      dump: {'theme': 'dark', 'cleanDateProfiles': <String>[], 'x': 1},
    );
    expect(result.settings, Settings.defaults);
    expect(result.importedKeys, isEmpty);
    expect(result.skippedKeys, [LegacySettingsTranslator.legacyThemeKey]);
  });

  test('numeric strings and integral doubles count as search ranges', () {
    expect(
      translated(dump: {'searchRange': '25'}).settings.searchRadius,
      const Km(25),
    );
    expect(
      translated(dump: {'searchRange': 40.0}).settings.searchRadius,
      const Km(40),
    );
    expect(translated(dump: {'searchRange': 60}).skippedKeys, [
      SettingKeys.searchRadius,
    ]);
  });

  test('translation is a pure function', () {
    final dump = LegacyStoreDumpDto.fromJson(const {
      'language': 'da',
      'firstday': 'mo',
      'theme': 'x',
    });
    expect(translator.translate(dump: dump), translator.translate(dump: dump));
  });
}
