@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Settings', () {
    test('defaults are Danish, Monday, ymd and 15 km', () {
      expect(Settings.defaults.language, Language.danish);
      expect(Settings.defaults.firstDayOfWeek, FirstDayOfWeek.monday);
      expect(
        Settings.defaults.cleanTimeUnitOrder,
        CleanTimeUnitOrder.yearsMonthsDays,
      );
      expect(Settings.defaults.searchRadius, const Km(15));
    });

    test('with-methods replace one field and keep the rest', () {
      final changed = Settings.defaults
          .withLanguage(language: Language.english)
          .withFirstDayOfWeek(firstDayOfWeek: FirstDayOfWeek.sunday)
          .withCleanTimeUnitOrder(
            cleanTimeUnitOrder: CleanTimeUnitOrder.daysMonthsYears,
          )
          .withSearchRadius(searchRadius: const Km(30));
      expect(changed.stored, {
        SettingKeys.language: 'en',
        SettingKeys.firstDayOfWeek: 'su',
        SettingKeys.cleanTimeUnitOrder: 'dmy',
        SettingKeys.searchRadius: '30',
      });
      expect(changed, isNot(Settings.defaults));
      expect(changed.toString(), contains('30 km'));
    });

    test('search radius is clamped to 5..50', () {
      expect(
        Settings.defaults
            .withSearchRadius(searchRadius: const Km(2))
            .searchRadius,
        const Km(5),
      );
      expect(
        Settings.defaults
            .withSearchRadius(searchRadius: const Km(99))
            .searchRadius,
        const Km(50),
      );
    });
  });

  group('codes', () {
    test('language, first day and unit order parse their codes', () {
      expect(
        Language.parse(code: 'en'),
        const Ok<Language, DecodeFailure>(value: Language.english),
      );
      expect(Language.parse(code: 'xx'), isA<Err<Language, DecodeFailure>>());
      expect(
        FirstDayOfWeek.parse(code: 'su'),
        const Ok<FirstDayOfWeek, DecodeFailure>(value: FirstDayOfWeek.sunday),
      );
      expect(
        FirstDayOfWeek.parse(code: 'tu'),
        isA<Err<FirstDayOfWeek, DecodeFailure>>(),
      );
      expect(
        CleanTimeUnitOrder.parse(code: 'dmy'),
        const Ok<CleanTimeUnitOrder, DecodeFailure>(
          value: CleanTimeUnitOrder.daysMonthsYears,
        ),
      );
      expect(
        CleanTimeUnitOrder.parse(code: 'mdy'),
        isA<Err<CleanTimeUnitOrder, DecodeFailure>>(),
      );
    });

    test('search radius parses integers inside the range only', () {
      expect(
        Km.parseSearchRadius(text: '30'),
        const Ok<Km, DecodeFailure>(value: Km(30)),
      );
      expect(
        Km.parseSearchRadius(text: ' 5 '),
        const Ok<Km, DecodeFailure>(value: Km(5)),
      );
      expect(Km.parseSearchRadius(text: '51'), isA<Err<Km, DecodeFailure>>());
      expect(Km.parseSearchRadius(text: 'abc'), isA<Err<Km, DecodeFailure>>());
      expect(Km.parseSearchRadius(text: '4.5'), isA<Err<Km, DecodeFailure>>());
    });
  });

  group('LegacyMigrationMarker', () {
    test('round-trips through its JSON encoding', () {
      final marker = LegacyMigrationMarker(
        appVersion: '2.0.0',
        completedAt: Instant(DateTime.utc(2026, 9, 10, 12)),
        importedKeys: 3,
        skippedKeys: 1,
      );
      expect(
        LegacyMigrationMarker.decode(text: marker.encoded),
        Ok<LegacyMigrationMarker, DecodeFailure>(value: marker),
      );
      expect(marker.toString(), contains('imported: 3'));
    });

    test('rejects malformed text', () {
      expect(
        LegacyMigrationMarker.decode(text: 'nope'),
        isA<Err<LegacyMigrationMarker, DecodeFailure>>(),
      );
      expect(
        LegacyMigrationMarker.decode(text: '[]'),
        isA<Err<LegacyMigrationMarker, DecodeFailure>>(),
      );
      expect(
        LegacyMigrationMarker.decode(
          text:
              '{"version":"2.0.0","completedAt":"x","imported":1,"skipped":0}',
        ),
        isA<Err<LegacyMigrationMarker, DecodeFailure>>(),
      );
    });
  });
}
