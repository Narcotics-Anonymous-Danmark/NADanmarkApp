@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  const codec = SettingsCodec();

  test('decodes stored codes and falls back per malformed key', () {
    final settings = codec.decode(
      stored: const {
        SettingKeys.language: 'en',
        SettingKeys.firstDayOfWeek: 'xx',
        SettingKeys.searchRadius: 'abc',
      },
    );
    expect(settings.language, Language.english);
    expect(settings.firstDayOfWeek, FirstDayOfWeek.monday);
    expect(settings.searchRadius, const Km(15));
    expect(settings.cleanTimeUnitOrder, CleanTimeUnitOrder.yearsMonthsDays);
  });

  test('encode and decode round-trip', () {
    const settings = Settings(
      language: Language.english,
      firstDayOfWeek: FirstDayOfWeek.sunday,
      cleanTimeUnitOrder: CleanTimeUnitOrder.daysMonthsYears,
      searchRadius: Km(42),
    );
    expect(codec.decode(stored: codec.encode(settings: settings)), settings);
  });

  test('app info compares by value', () {
    const info = AppInfo(
      version: VersionName('2.0.0'),
      buildType: BuildType('release'),
      approval: BuildApproval.approved,
    );
    expect(
      info,
      const AppInfo(
        version: VersionName('2.0.0'),
        buildType: BuildType('release'),
        approval: BuildApproval.approved,
      ),
    );
    expect(info.toString(), contains('release'));
  });
}
