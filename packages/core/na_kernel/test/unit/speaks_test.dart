@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/speaks.dart';

void main() {
  group('Requirement: Text folding', () {
    test('Folding Danish letters', () {
      expect(
        const FeedText('  Åbnings-Speak  København ').folded,
        const FoldedText('abnings-speak kobenhavn'),
      );
    });

    test('Tidy strips stray punctuation', () {
      expect(
        const FeedText('.Vilborg trin 10-11-12.').tidied,
        const FeedText('Vilborg trin 10-11-12'),
      );
    });

    test('accents and combining marks are dropped', () {
      expect(const FeedText('René').folded, const FoldedText('rene'));
      expect(
        const FeedText('Gårdsbo').folded,
        const FoldedText('gardsbo'),
      );
    });

    test('Æ and Ø fold to ae and o', () {
      expect(const FeedText('ÆBLE Øer').folded, const FoldedText('aeble oer'));
    });

    test('tidy collapses whitespace and keeps inner punctuation', () {
      expect(
        const FeedText(' / Aalborg\n\n2015 ;: ').tidied,
        const FeedText('Aalborg 2015'),
      );
    });

    test('a query splits into folded terms', () {
      expect(const FeedText(' Kokna   2026 ').folded.terms, const [
        FoldedText('kokna'),
        FoldedText('2026'),
      ]);
      expect(const FeedText('   ').folded.terms, isEmpty);
    });
  });

  group('Requirement: Convention parsing', () {
    test('Convention with city', () {
      expect(
        ParsedConvention.of(title: const FeedText('KOKNA - København')),
        const ParsedConvention(
          key: ConventionKey('kokna'),
          label: ConventionLabel('KOKNA'),
          city: InCity(name: CityName('København')),
        ),
      );
    });

    test('Foreign speaks fold into the same convention', () {
      expect(
        ParsedConvention.of(title: const FeedText('KOKNA - Udenlandske Speak')),
        const ParsedConvention(
          key: ConventionKey('kokna'),
          label: ConventionLabel('KOKNA'),
          city: NoCity(),
        ),
      );
      final catalog = catalogOf([
        aGroup(
          entries: [anEntry(url: const FeedText('https://audio.test/1.mp3'))],
        ),
        aGroup(
          title: const FeedText('KOKNA - Udenlandske Speak'),
          language: SpeakLanguage.english,
          entries: [anEntry(url: const FeedText('https://audio.test/2.mp3'))],
        ),
      ]);
      expect(catalog.conventions, const [
        SpeakConvention(
          key: ConventionKey('kokna'),
          label: ConventionLabel('KOKNA'),
          city: InCity(name: CityName('København')),
          count: SpeakCount(2),
        ),
      ]);
    });

    test('Shouty label is sentence-cased', () {
      expect(
        ParsedConvention.of(title: const FeedText('BLANDEDE SPEAK')).label,
        const ConventionLabel('Blandede speak'),
      );
    });

    test('a hyphenated name without spaces is not split', () {
      expect(
        ParsedConvention.of(title: const FeedText('Konvent-camp Skanderborg')),
        const ParsedConvention(
          key: ConventionKey('konvent-camp skanderborg'),
          label: ConventionLabel('Konvent-camp Skanderborg'),
          city: NoCity(),
        ),
      );
    });

    test('joined acronyms stay upper case', () {
      expect(
        ParsedConvention.of(title: const FeedText('kokna/ckna - aarhus')),
        const ParsedConvention(
          key: ConventionKey('kokna/ckna'),
          label: ConventionLabel('KOKNA/CKNA'),
          city: InCity(name: CityName('Aarhus')),
        ),
      );
    });

    test('an empty title is the Speaks convention', () {
      expect(
        ParsedConvention.of(title: const FeedText('  ')),
        const ParsedConvention(
          key: ConventionKey('speaks'),
          label: ConventionLabel('Speaks'),
          city: NoCity(),
        ),
      );
    });
  });

  group('Requirement: Date parsing', () {
    SpeakDate parsed(String field, {String fallback = ''}) =>
        SpeakDate.parse(field: FeedText(field), fallback: FeedText(fallback));

    test('Full date', () {
      final date = parsed('13-2-22');
      expect(
        date,
        const FullDate(date: LocalDate(year: 2022, month: 2, day: 13)),
      );
      expect(date.years, const [SpeakYear(2022)]);
      expect(partsOf(date.dateLabels), ['13-02-2022']);
      expect(date.sortKey, const SpeakSortKey(20220213));
    });

    test('Year from the file name', () {
      final speak = aSpeakFrom(
        year: const FeedText('?'),
        location: const FeedText(''),
        url: const FeedText(
          'https://audio.test/KOKNA%2030%202026%20%C3%A5bningsspeak.wav',
        ),
      );
      expect(speak.date, const YearOnly(year: SpeakYear(2026)));
      expect(speak.date.sortKey, const SpeakSortKey(20260000));
    });

    test('Unknown date', () {
      final date = parsed('?', fallback: 'Aalborg hovedspeak');
      expect(date, const UnknownDate());
      expect(date.years, isEmpty);
      expect(date.sortKey, const SpeakSortKey(0));
    });

    test('slashes and four-digit years are full dates', () {
      expect(
        parsed('26/10-1998'),
        const FullDate(date: LocalDate(year: 1998, month: 10, day: 26)),
      );
    });

    test('padded years are years', () {
      expect(parsed(' 2015 '), const YearOnly(year: SpeakYear(2015)));
      expect(partsOf(parsed(' 2015 ').timeLabels), ['2015']);
    });

    test('an impossible day falls back to a year elsewhere', () {
      expect(
        parsed('32-1-20', fallback: 'KOKNA 2019'),
        const YearOnly(year: SpeakYear(2019)),
      );
    });
  });

  group('Requirement: Kind detection and speaker', () {
    test('Name carries the kind', () {
      final speak = aSpeakFrom(name: const FeedText('Hovedspeak Sigi'));
      expect(speak.kind, const KindOf(kind: SpeakKind.main));
      expect(speak.speaker, const NamedSpeaker(name: SpeakerName('Sigi')));
      expect(speak.title, const SpeakerTitle(name: SpeakerName('Sigi')));
    });

    test('Kind from the file name only', () {
      final speak = aSpeakFrom(
        name: const FeedText(''),
        url: const FeedText(
          'https://audio.test/KOKNA%2030%202026%20%C3%A5bningsspeak.wav',
        ),
      );
      expect(speak.kind, const KindOf(kind: SpeakKind.opening));
      expect(speak.speaker, const NoSpeaker());
      expect(speak.title, const KindTitle(kind: SpeakKind.opening));
    });

    test('Danish prefixes with upper-case letters are removed', () {
      expect(
        speakerOf(name: const FeedText('Åbningsspeaker Louise')),
        const NamedSpeaker(name: SpeakerName('Louise')),
      );
      expect(
        speakerOf(name: const FeedText('HOVEDSPEAK: Sigi')),
        const NamedSpeaker(name: SpeakerName('Sigi')),
      );
    });

    test('the first candidate with a kind wins', () {
      expect(
        detectKind(
          candidates: const [
            FeedText('Anna'),
            FeedText('Afslutning KOKNA'),
            FeedText('opening'),
          ],
        ),
        const KindOf(kind: SpeakKind.closing),
      );
      expect(
        detectKind(candidates: const [FeedText('Main speak')]),
        const KindOf(kind: SpeakKind.main),
      );
      expect(
        detectKind(candidates: const [FeedText('Anna'), FeedText('')]),
        const NoKind(),
      );
    });
  });

  group('Requirement: Title, edition and meta lines', () {
    test('Meta with edition and year', () {
      final speak = aSpeakFrom(name: const FeedText('Hovedspeak Sigi'));
      expect(speak.title, const SpeakerTitle(name: SpeakerName('Sigi')));
      expect(partsOf(speak.meta), ['KOKNA 30', '2026']);
      expect(partsOf(speak.context), ['KOKNA 30', '2026']);
    });

    test('Edition shortened by convention label', () {
      final speak = aSpeakFrom(
        title: const FeedText('Konvent-camp Skanderborg'),
        location: const FeedText('Konvent-camp Skanderborg 2015'),
        year: const FeedText('2015'),
      );
      expect(speak.edition, const EditionOf(text: EditionText('2015')));
      expect(partsOf(speak.meta), ['2015']);
      expect(partsOf(speak.context), ['Konvent-camp Skanderborg', '2015']);
    });

    test('an edition without a year keeps the convention name', () {
      expect(
        shortEditionOf(
          edition: const EditionOf(text: EditionText('KOKNA 30')),
          label: const ConventionLabel('KOKNA'),
        ),
        const EditionOf(text: EditionText('KOKNA 30')),
      );
    });

    test('convention acronyms in a location are upper-cased', () {
      expect(
        editionOf(location: const FeedText('kokna 27')),
        const EditionOf(text: EditionText('KOKNA 27')),
      );
      expect(editionOf(location: const FeedText(' ? ')), const NoEdition());
    });

    test('the title falls back to the edition and then the convention', () {
      expect(
        aSpeakFrom(name: const FeedText('')).title,
        const EditionTitle(edition: EditionText('KOKNA 30')),
      );
      final bare = aSpeakFrom(
        name: const FeedText(''),
        location: const FeedText('?'),
        year: const FeedText('?'),
      );
      expect(
        bare.title,
        const ConventionTitle(label: ConventionLabel('KOKNA')),
      );
      expect(bare.meta, isEmpty);
      expect(partsOf(bare.context), ['KOKNA']);
    });

    test('a full date is the time label', () {
      final speak = aSpeakFrom(
        title: const FeedText('Viborg online'),
        location: const FeedText('Viborg'),
        year: const FeedText('13-2-22'),
      );
      expect(partsOf(speak.meta), ['Viborg', '13-02-2022']);
      expect(partsOf(speak.context), ['Viborg online', 'Viborg', '13-02-2022']);
    });
  });

  group('Requirement: Deduplication and catalog', () {
    test('Duplicate URL kept once', () {
      final catalog = catalogOf([
        aGroup(),
        aGroup(title: const FeedText('BLANDEDE SPEAK')),
      ]);
      expect(catalog.speaks, hasLength(1));
      expect(catalog.speaks.single.convention, const ConventionKey('kokna'));
      expect(
        catalog.conventions.map((convention) => convention.key),
        const [ConventionKey('kokna')],
      );
    });

    test('Language words are searchable', () {
      final english = aSpeakFrom(language: SpeakLanguage.english);
      final danish = aSpeakFrom();
      expect(english.searchText.value, contains('engelsk'));
      expect(danish.searchText.value, isNot(contains('engelsk')));
      expect(danish.searchText.value, contains('dansk'));
    });

    test('Kind words in both languages are searchable', () {
      final speak = aSpeakFrom(name: const FeedText('Hovedspeak Sigi'));
      expect(speak.searchText.value, contains('hovedspeak'));
      expect(speak.searchText.value, contains('main speak'));
    });

    test('the file name, city and date label are searchable', () {
      final speak = aSpeakFrom(
        year: const FeedText('13-2-22'),
        url: const FeedText('https://audio.test/Sigi%20R%C3%A5.mp3?x=1'),
      );
      expect(speak.searchText.value, contains('sigi ra'));
      expect(speak.searchText.value, contains('kobenhavn'));
      expect(speak.searchText.value, contains('13-02-2022'));
    });

    test('conventions keep first-seen order and years are newest first', () {
      final catalog = catalogOf([
        aGroup(
          title: const FeedText('BLANDEDE SPEAK'),
          entries: [
            anEntry(
              url: const FeedText('https://audio.test/1.mp3'),
              year: const FeedText('2015'),
            ),
          ],
        ),
        aGroup(
          entries: [
            anEntry(
              url: const FeedText('https://audio.test/2.mp3'),
              year: const FeedText('2026'),
            ),
            anEntry(
              url: const FeedText('https://audio.test/3.mp3'),
              year: const FeedText('2015'),
            ),
            anEntry(
              url: const FeedText('https://audio.test/4.mp3'),
              year: const FeedText('?'),
              location: const FeedText('?'),
            ),
          ],
        ),
      ]);
      expect(catalog.conventions.map((convention) => convention.label), const [
        ConventionLabel('Blandede speak'),
        ConventionLabel('KOKNA'),
      ]);
      expect(catalog.conventions.map((convention) => convention.count), const [
        SpeakCount(1),
        SpeakCount(3),
      ]);
      expect(catalog.years, const [SpeakYear(2026), SpeakYear(2015)]);
      expect(
        catalog.conventionOf(key: const ConventionKey('kokna')).city,
        const InCity(name: CityName('København')),
      );
      expect(
        catalog.conventionOf(key: const ConventionKey('missing')).count,
        const SpeakCount(0),
      );
    });

    test('catalogues and speaks compare by value', () {
      expect(catalogOf([aGroup()]), catalogOf([aGroup()]));
      expect(catalogOf([aGroup()]).hashCode, catalogOf([aGroup()]).hashCode);
      expect(SpeakCatalog.empty.speaks, isEmpty);
      expect(
        aGroup(),
        isNot(aGroup(language: SpeakLanguage.english)),
      );
      expect(anEntry().toString(), contains('speak.mp3'));
    });
  });
}
