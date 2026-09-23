@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

FormatIndex danishIndex() => FormatIndex.build(
  rows: recordedFormatRows(),
  display: FormatLanguageCode.danish,
);

List<String> names({
  required FormatIndex index,
  required List<String> keys,
  List<int> ids = const [],
  MeetingOrigin origin = MeetingOrigin.denmark,
}) => index
    .formatsOf(
      codes: MeetingFormatCodes(
        keys: List.unmodifiable(keys.map(FormatKey.new)),
        sharedIds: List.unmodifiable(ids.map(FormatId.new)),
      ),
      origin: origin,
    )
    .map((format) => format.name)
    .toList();

void main() {
  group('Resolving a meeting from the Danish root', () {
    test('shared ids win when their count matches the keys', () {
      expect(names(index: danishIndex(), keys: ['LUK', 'BFID'], ids: [4, 14]), [
        'Lukket',
        'Bare For I Dag',
      ]);
    });

    test('ids are ignored when the counts differ', () {
      expect(names(index: danishIndex(), keys: ['ÅM', 'BT'], ids: [4]), [
        'Åben Møde',
        'Basis Tekst',
      ]);
    });

    test('ids are ignored for meetings aggregated with a root server id', () {
      expect(
        names(
          index: danishIndex(),
          keys: ['ÅM'],
          ids: [4],
          origin: MeetingOrigin.denmarkAggregated,
        ),
        ['Åben Møde'],
      );
    });

    test('an unknown id falls back to the key', () {
      expect(names(index: danishIndex(), keys: ['BT'], ids: [999]), [
        'Basis Tekst',
      ]);
    });

    test('keys match case-insensitively when unambiguous', () {
      expect(names(index: danishIndex(), keys: ['bt']), ['Basis Tekst']);
    });

    test('an English key resolves to the Danish definition', () {
      expect(names(index: danishIndex(), keys: ['O']), ['Åben Møde']);
    });

    test('an unknown key is shown raw as content', () {
      final formats = danishIndex().formatsOf(
        codes: const MeetingFormatCodes(
          keys: [FormatKey('XYZ')],
          sharedIds: [],
        ),
        origin: MeetingOrigin.denmark,
      );
      expect(formats, [MeetingFormat.unresolved(key: const FormatKey('XYZ'))]);
      expect(formats.single.category, FormatCategory.content);
    });

    test('no keys means no formats', () {
      expect(names(index: danishIndex(), keys: const []), isEmpty);
    });
  });

  group('Resolving a meeting from another root', () {
    test('only English keys resolve, shown in the display language', () {
      final formats = danishIndex().formatsOf(
        codes: const MeetingFormatCodes(keys: [FormatKey('O')], sharedIds: []),
        origin: MeetingOrigin.otherRoot,
      );
      expect(formats.single.key, const FormatKey('ÅM'));
      expect(formats.single.name, 'Åben Møde');
    });

    test('a Danish key stays raw', () {
      expect(
        names(
          index: danishIndex(),
          keys: ['ÅM'],
          origin: MeetingOrigin.otherRoot,
        ),
        ['ÅM'],
      );
    });
  });

  group('Ordering and duplicates', () {
    test('category order first, then Danish collation of names', () {
      expect(
        names(
          index: danishIndex(),
          keys: ['BT', 'ST', 'ÅM', 'ENG', 'HV', 'XYZ', 'BFID'],
        ),
        [
          'Stempelmøde',
          'Engelsk Møde',
          'Åben Møde',
          'Handicap venlig',
          'Bare For I Dag',
          'Basis Tekst',
          'XYZ',
        ],
      );
    });

    test('keys resolving to the same format collapse to one', () {
      expect(names(index: danishIndex(), keys: ['ÅM', 'O']), ['Åben Møde']);
    });
  });

  group('Ambiguous lower-case keys', () {
    final index = FormatIndex.build(
      rows: [
        aFormatRow(id: 90, key: 'Se', name: 'Se'),
        aFormatRow(id: 91, key: 'SE', name: 'SE'),
        aFormatRow(id: 92, key: 'sE', name: 'sE'),
      ],
      display: FormatLanguageCode.danish,
    );

    test('an exact key still resolves', () {
      expect(names(index: index, keys: ['Se']), ['Se']);
    });

    test(
      'the ambiguous lower-case key resolves to none, even after a third row',
      () {
        expect(names(index: index, keys: ['se']), ['se']);
      },
    );
  });

  group('Display language', () {
    test('English names in English', () {
      final english = FormatIndex.build(
        rows: recordedFormatRows(),
        display: FormatLanguageCode.english,
      );
      expect(names(index: english, keys: ['ÅM'], ids: [17]), ['Open']);
    });

    test('a Danish-only format keeps its Danish name in English', () {
      final english = FormatIndex.build(
        rows: recordedFormatRows(),
        display: FormatLanguageCode.english,
      );
      expect(names(index: english, keys: ['ST'], ids: [55]), ['Stempelmøde']);
    });

    test('the display language follows the app language', () {
      expect(
        FormatLanguageCode.displayFor(language: Language.danish),
        FormatLanguageCode.danish,
      );
      expect(
        FormatLanguageCode.displayFor(language: Language.english),
        FormatLanguageCode.english,
      );
    });
  });

  group('Format definitions', () {
    test('categories map from format_type_enum', () {
      const table = {
        'ALERT': FormatCategory.alert,
        'LANG': FormatCategory.language,
        'FC3': FormatCategory.audience,
        'O': FormatCategory.audience,
        'C': FormatCategory.audience,
        'FC2': FormatCategory.facility,
        'FC1': FormatCategory.content,
        '': FormatCategory.content,
      };
      for (final entry in table.entries) {
        expect(
          FormatCategory.fromTypeEnum(typeEnum: entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test(
      'a blank name falls back to the key and a blank description is none',
      () {
        final format = MeetingFormat.fromRow(
          row: aFormatRow(key: 'K', name: ' ', description: ''),
        );
        expect(format.name, 'K');
        expect(format.description, const NoDescription());
        expect(
          MeetingFormat.fromRow(row: aFormatRow()).description,
          const Described(text: 'Alle er velkomne'),
        );
      },
    );

    test('rows without a key are ignored', () {
      final index = FormatIndex.build(
        rows: [aFormatRow(id: 1, key: ' ')],
        display: FormatLanguageCode.danish,
      );
      expect(names(index: index, keys: ['ÅM'], ids: [1]), ['ÅM']);
    });

    test('formats and rows compare by value', () {
      expect(aFormatRow(), aFormatRow());
      expect(aFormatRow().hashCode, aFormatRow().hashCode);
      expect(aFormatRow().toString(), 'FormatRow(17, ÅM, da)');
      expect(
        MeetingFormat.fromRow(row: aFormatRow()).toString(),
        'MeetingFormat(ÅM, Åben Møde, audience)',
      );
      expect(const Described(text: 'a'), const Described(text: 'a'));
      expect(
        FormatIndex.empty.formatsOf(
          codes: MeetingFormatCodes.none,
          origin: MeetingOrigin.denmark,
        ),
        isEmpty,
      );
    });
  });

  group('Danish collation', () {
    const collation = DanishCollation();

    List<String> sorted(List<String> words) =>
        [...words]
          ..sort((left, right) => collation.compare(left: left, right: right));

    test('æ, ø and å come after z', () {
      expect(sorted(['Åben', 'Zebra', 'Ærlig', 'Øl', 'abc', 'Basis']), [
        'abc',
        'Basis',
        'Zebra',
        'Ærlig',
        'Øl',
        'Åben',
      ]);
    });

    test('aa sorts as å and ä, ö as æ, ø', () {
      expect(sorted(['Aarhus', 'Øst', 'Zulu']), ['Zulu', 'Øst', 'Aarhus']);
      expect(collation.compare(left: 'ä', right: 'æ'), 0);
      expect(collation.compare(left: 'ö', right: 'ø'), 0);
    });

    test('letters compare case-insensitively, lower case first on a tie', () {
      expect(sorted(['b', 'A', 'a']), ['a', 'A', 'b']);
      expect(collation.compare(left: 'Café', right: 'cafe'), 1);
      expect(collation.compare(left: 'ab', right: 'abc'), -1);
    });
  });
}
