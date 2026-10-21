@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

const translator = LegacyCleantimeTranslator();

LegacyCleantimeTranslation translated({required WireObject dump}) =>
    translator.translate(
      dump: LegacyStoreDumpDto.fromJson(dump),
      unnamed: (index) => ProfileName('Profil ${index.position + 1}'),
    );

CleantimeProfile profile({
  required ProfileName name,
  required LocalDate cleanDate,
}) => CleantimeProfile(name: name, cleanDate: cleanDate);

List<CleantimeProfile> importedProfiles({
  required LegacyCleantimeTranslation translation,
}) => switch (translation.import) {
  ImportCleantime(:final profiles) => profiles.entries,
  SkipCleantime() => const [],
};

ProfileIndex importedActive({
  required LegacyCleantimeTranslation translation,
}) => switch (translation.import) {
  ImportCleantime(:final profiles) => profiles.active,
  SkipCleantime() => const ProfileIndex(-1),
};

const WireObject anna = {
  'name': 'Anna',
  'cleandate': '2020-05-03T00:00:00.000+02:00',
};
const WireObject bo = {'name': 'Bo', 'cleandate': '2019-11-30T23:30:00.000Z'};

void main() {
  test('cleantime profiles keep their calendar date', () {
    final result = translated(
      dump: {
        'cleanDateProfiles': [anna],
      },
    );
    expect(importedProfiles(translation: result), [
      profile(
        name: const ProfileName('Anna'),
        cleanDate: aDate(year: 2020, month: 5, day: 3),
      ),
    ]);
    expect(result.importedKeys, [LegacyCleantimeTranslator.legacyProfilesKey]);
    expect(result.skippedKeys, isEmpty);
  });

  test('picker-written clean date', () {
    expect(
      importedProfiles(
        translation: translated(
          dump: {
            'cleanDateProfiles': [bo],
          },
        ),
      ),
      [
        profile(
          name: const ProfileName('Bo'),
          cleanDate: aDate(year: 2019, month: 11, day: 30),
        ),
      ],
    );
  });

  test('unparseable entries are dropped', () {
    expect(
      importedProfiles(
        translation: translated(
          dump: {
            'cleanDateProfiles': [
              anna,
              {'name': 'X', 'cleandate': 'soon'},
              {'name': 'Y'},
              {'name': 'Z', 'cleandate': '2020-02-30T00:00:00.000Z'},
              'text',
            ],
          },
        ),
      ).map((entry) => entry.name),
      [const ProfileName('Anna')],
    );
  });

  test('unnamed profile keeps its date', () {
    expect(
      importedProfiles(
        translation: translated(
          dump: {
            'cleanDateProfiles': [
              anna,
              {'name': ' ', 'cleandate': '2021-01-02T00:00:00.000+01:00'},
            ],
          },
        ),
      ),
      [
        profile(
          name: const ProfileName('Anna'),
          cleanDate: aDate(year: 2020, month: 5, day: 3),
        ),
        profile(
          name: const ProfileName('Profil 2'),
          cleanDate: aDate(year: 2021, month: 1, day: 2),
        ),
      ],
    );
  });

  test('active index is clamped', () {
    final result = translated(
      dump: {
        'cleanDateProfiles': [anna, bo],
        'activeProfile': '5',
      },
    );
    expect(importedActive(translation: result), const ProfileIndex(1));
    expect(result.importedKeys, [
      LegacyCleantimeTranslator.legacyProfilesKey,
      LegacyCleantimeTranslator.legacyActiveKey,
    ]);
  });

  test('numeric active index', () {
    expect(
      importedActive(
        translation: translated(
          dump: {
            'cleanDateProfiles': [anna, bo],
            'activeProfile': 1,
          },
        ),
      ),
      const ProfileIndex(1),
    );
  });

  test(
    'an unparseable active index selects the first and counts as skipped',
    () {
      final result = translated(
        dump: {
          'cleanDateProfiles': [anna, bo],
          'activeProfile': 'x',
        },
      );
      expect(importedActive(translation: result), const ProfileIndex(0));
      expect(result.skippedKeys, [LegacyCleantimeTranslator.legacyActiveKey]);
    },
  );

  test('one bad value skips the profiles and their index', () {
    final result = translated(
      dump: {'cleanDateProfiles': 'oops', 'activeProfile': '0'},
    );
    expect(result.import, const SkipCleantime());
    expect(result.importedKeys, isEmpty);
    expect(result.skippedKeys, [
      LegacyCleantimeTranslator.legacyProfilesKey,
      LegacyCleantimeTranslator.legacyActiveKey,
    ]);
  });

  test('profiles stored as JSON text are read', () {
    expect(
      importedProfiles(
        translation: translated(
          dump: {
            'cleanDateProfiles':
                '[{"name":"Anna","cleandate":"2020-05-03T00:00:00.000+02:00"}]',
          },
        ),
      ),
      hasLength(1),
    );
  });

  test('no legacy cleantime keys means nothing to count', () {
    final result = translated(dump: {'language': 'en'});
    expect(result.import, const SkipCleantime());
    expect(result.importedKeys, isEmpty);
    expect(result.skippedKeys, isEmpty);
  });

  test('translation is a pure function', () {
    const dump = <String, Object?>{
      'cleanDateProfiles': [anna, bo],
      'activeProfile': '1',
    };
    expect(translated(dump: dump), translated(dump: dump));
    expect(translated(dump: dump).hashCode, translated(dump: dump).hashCode);
    expect(translated(dump: dump).toString(), contains('Anna'));
    expect(const SkipCleantime().toString(), 'SkipCleantime()');
    expect(const SkipCleantime().hashCode, const SkipCleantime().hashCode);
  });
}
