import 'package:na_kernel/na_kernel.dart';

const SpeakKindWords kindWords = SpeakKindWords(
  opening: FoldedText('abningsspeak opening speak'),
  main: FoldedText('hovedspeak main speak'),
  closing: FoldedText('afslutningsspeak closing speak'),
);

FeedEntry anEntry({
  FeedText url = const FeedText('https://audio.test/speak.mp3'),
  FeedText name = const FeedText('Anna'),
  FeedText location = const FeedText('KOKNA 30'),
  FeedText year = const FeedText('2026'),
}) => FeedEntry(
  id: PlaylistId(url.value),
  url: AudioUrl(Uri.parse(url.value)),
  name: name,
  location: location,
  year: year,
);

FeedGroup aGroup({
  FeedText title = const FeedText('KOKNA - København'),
  SpeakLanguage language = SpeakLanguage.danish,
  List<FeedEntry> entries = const [],
}) => FeedGroup(
  title: title,
  language: language,
  entries: entries.isEmpty ? [anEntry()] : entries,
);

SpeakCatalog catalogOf(List<FeedGroup> groups) =>
    SpeakCatalog.build(groups: groups, kindWords: kindWords);

Speak aSpeakFrom({
  FeedText title = const FeedText('KOKNA - København'),
  SpeakLanguage language = SpeakLanguage.danish,
  FeedText url = const FeedText('https://audio.test/speak.mp3'),
  FeedText name = const FeedText('Anna'),
  FeedText location = const FeedText('KOKNA 30'),
  FeedText year = const FeedText('2026'),
}) => catalogOf([
  aGroup(
    title: title,
    language: language,
    entries: [anEntry(url: url, name: name, location: location, year: year)],
  ),
]).speaks.single;

List<String> partsOf(List<MetaPart> parts) =>
    parts.map((part) => part.text).toList();
