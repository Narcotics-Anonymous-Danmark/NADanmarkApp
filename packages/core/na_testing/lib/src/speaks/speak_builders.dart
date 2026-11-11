import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/builders/test_values.dart';

extension type const SpeakSlug(String value) {
  AudioUrlText get url => AudioUrlText('https://audio.test/speaks/$value.mp3');
}

extension type const AudioUrlText(String value) {
  PlaylistId get id => PlaylistId(value);
}

const SpeakKindWords testSpeakKindWords = SpeakKindWords(
  opening: FoldedText('abningsspeak opening speak'),
  main: FoldedText('hovedspeak main speak'),
  closing: FoldedText('afslutningsspeak closing speak'),
);

SpeakEntryDto aSpeakEntryDto({
  FeedText name = const FeedText('Anna'),
  FeedText location = const FeedText('KOKNA 30'),
  FeedText year = const FeedText('2026'),
  AudioUrlText url = const AudioUrlText(
    'https://audio.test/speaks/anna.mp3',
  ),
}) => SpeakEntryDto(
  name: name.value,
  location: location.value,
  year: year.value,
  audioUrl: url.value,
);

SpeakGroupDto aSpeakGroupDto({
  FeedText title = const FeedText('KOKNA - København'),
  List<SpeakEntryDto> speaks = const [],
}) => SpeakGroupDto(
  title: title.value,
  speaks: speaks.isEmpty ? [aSpeakEntryDto()] : speaks,
);

SpeakEntryDto sampleSpeak({
  required SpeakSlug slug,
  required FeedText name,
  required FeedText location,
  required FeedText year,
}) => aSpeakEntryDto(
  name: name,
  location: location,
  year: year,
  url: slug.url,
);

final List<SpeakGroupDto> sampleDanishSpeaks = List.unmodifiable([
  SpeakGroupDto(
    title: 'KOKNA - København',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('kokna-30-hovedspeak-sigi'),
        name: const FeedText('Hovedspeak Sigi'),
        location: const FeedText('KOKNA 30'),
        year: const FeedText('2026'),
      ),
      aSpeakEntryDto(
        name: const FeedText(''),
        location: const FeedText('KOKNA 30'),
        year: const FeedText('?'),
        url: const AudioUrlText(
          'https://audio.test/speaks/KOKNA 30 2026 åbningsspeak.wav',
        ),
      ),
      sampleSpeak(
        slug: const SpeakSlug('kokna-29-afslutning-louise'),
        name: const FeedText('Afslutningsspeak Louise'),
        location: const FeedText('Kokna 29'),
        year: const FeedText(' 2025 '),
      ),
      sampleSpeak(
        slug: const SpeakSlug('kokna-27-anders'),
        name: const FeedText('Anders'),
        location: const FeedText('KOKNA 27'),
        year: const FeedText('2023'),
      ),
    ],
  ),
  SpeakGroupDto(
    title: 'Konvent-camp Skanderborg',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('camp-2015-ase'),
        name: const FeedText('Åse'),
        location: const FeedText('Konvent-camp Skanderborg 2015'),
        year: const FeedText('2015'),
      ),
      sampleSpeak(
        slug: const SpeakSlug('camp-2016-bo'),
        name: const FeedText('Bo'),
        location: const FeedText('Konvent-camp Skanderborg 2016'),
        year: const FeedText('2016'),
      ),
    ],
  ),
  SpeakGroupDto(
    title: 'Viborg online møder',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('viborg-mette'),
        name: const FeedText('Mette'),
        location: const FeedText('.Vilborg trin 10-11-12.'),
        year: const FeedText('13-2-22'),
      ),
      sampleSpeak(
        slug: const SpeakSlug('viborg-hovedspeak'),
        name: const FeedText('Hovedspeak'),
        location: const FeedText('?'),
        year: const FeedText('?'),
      ),
    ],
  ),
  SpeakGroupDto(
    title: 'BLANDEDE SPEAK',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('aalborg-peter'),
        name: const FeedText('Peter'),
        location: const FeedText('Aalborg'),
        year: const FeedText('1998'),
      ),
      sampleSpeak(
        slug: const SpeakSlug('kokna-30-hovedspeak-sigi'),
        name: const FeedText('Sigi'),
        location: const FeedText('Aalborg'),
        year: const FeedText('2026'),
      ),
    ],
  ),
]);

final List<SpeakGroupDto> sampleEnglishSpeaks = List.unmodifiable([
  SpeakGroupDto(
    title: 'KOKNA - Udenlandske Speak',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('kokna-30-main-john'),
        name: const FeedText('Main speak John'),
        location: const FeedText('KOKNA 30'),
        year: const FeedText('2026'),
      ),
      sampleSpeak(
        slug: const SpeakSlug('kokna-28-sarah'),
        name: const FeedText('Sarah'),
        location: const FeedText('KOKNA 28'),
        year: const FeedText('2024'),
      ),
    ],
  ),
  SpeakGroupDto(
    title: 'ECCNA - Udenlandske speaks',
    speaks: [
      sampleSpeak(
        slug: const SpeakSlug('eccna-38-opening-mike'),
        name: const FeedText('Opening speak Mike'),
        location: const FeedText('ECCNA 38'),
        year: const FeedText('2022'),
      ),
    ],
  ),
]);

List<SpeakGroupDto> manySpeaks({
  RowCount count = const RowCount(100),
  FeedText title = const FeedText('KOKNA - København'),
}) => List.unmodifiable([
  SpeakGroupDto(
    title: title.value,
    speaks: List.generate(
      count.value,
      (index) => sampleSpeak(
        slug: SpeakSlug('many-$index'),
        name: FeedText('Speaker ${index.toString().padLeft(3, '0')}'),
        location: FeedText('KOKNA ${index % 30}'),
        year: FeedText('${1990 + index % 30}'),
      ),
    ),
  ),
]);

List<FeedGroup> feedGroupsOf({
  required List<SpeakGroupDto> dtos,
  required SpeakLanguage language,
}) => List.unmodifiable(
  dtos.map(
    (dto) => const SpeaksMapper().group(dto: dto, language: language),
  ),
);

SpeakCatalog sampleSpeakCatalog() => SpeakCatalog.build(
  groups: [
    ...feedGroupsOf(dtos: sampleDanishSpeaks, language: SpeakLanguage.danish),
    ...feedGroupsOf(
      dtos: sampleEnglishSpeaks,
      language: SpeakLanguage.english,
    ),
  ],
  kindWords: testSpeakKindWords,
);

Speak sampleSpeakAt({required SpeakSlug slug}) =>
    sampleSpeakCatalog().speaks.firstWhere((speak) => speak.id == slug.url.id);
