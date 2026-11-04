@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

Chapter aChapter({TrackTitle title = const TrackTitle('01. Indledning')}) =>
    Chapter(
      title: title,
      url: AudioUrl(Uri.parse('https://www.nadanmark.dk/1.mp3')),
      label: const DurationLabel('3:45'),
    );

Audiobook aBook({List<Chapter>? chapters}) => Audiobook(
  id: AudiobookId.howAndWhy,
  title: const PlaylistTitle('Det Virker'),
  chapters: chapters ?? [aChapter()],
);

void main() {
  test('book ids carry the playlist id and the legacy totals', () {
    expect(AudiobookId.values.map((book) => book.playlistId.value), [
      'basic-text',
      'how-and-why',
      'step-working-guides',
    ]);
    expect(AudiobookId.values.map((book) => book.total.text), [
      '13:53:58',
      '06:11:37',
      '05:03:49',
    ]);
  });

  test('a book becomes a book playlist with tracks by URL', () {
    final playlist = aBook().playlist(cover: const NoCover());
    expect(playlist.kind, PlaylistKind.book);
    expect(playlist.id, const PlaylistId('how-and-why'));
    expect(playlist.title, const PlaylistTitle('Det Virker'));
    expect(
      playlist.tracks.single,
      MediaTrack(
        id: const TrackId('https://www.nadanmark.dk/1.mp3'),
        title: const TrackTitle('01. Indledning'),
        url: AudioUrl(Uri.parse('https://www.nadanmark.dk/1.mp3')),
        label: const DurationLabel('3:45'),
      ),
    );
    expect(aBook().chapterLengths, [
      const KnownLength(duration: Duration(seconds: 225)),
    ]);
  });

  test('books and chapters compare by value', () {
    expect(aBook(), aBook());
    expect(aBook().hashCode, aBook().hashCode);
    expect(
      aBook(),
      isNot(aBook(chapters: [aChapter(title: const TrackTitle('x'))])),
    );
    expect(aChapter(), aChapter());
    expect(aChapter().hashCode, aChapter().hashCode);
    expect(aChapter().toString(), 'Chapter(01. Indledning)');
    expect(aBook().toString(), 'Audiobook(how-and-why, 1 chapters)');
  });

  test('readings clamp their index and join their spans', () {
    const line = ReadingLine(
      spans: [
        ReadingSpan(text: ReadingText('Gud, '), emphasis: Emphasis.plain),
        ReadingSpan(
          text: ReadingText('som vi opfattede Ham'),
          emphasis: Emphasis.emphasised,
        ),
      ],
    );
    expect(line.plainText, 'Gud, som vi opfattede Ham');
    expect(
      line.spans.first,
      const ReadingSpan(text: ReadingText('Gud, '), emphasis: Emphasis.plain),
    );
    expect(line.spans.first.hashCode, line.spans.first.hashCode);
    const first = Reading(
      title: ReadingTitle('A'),
      heading: ReadingHeading('A'),
      colour: ReadingColour(0xFFFFFFFF),
      blocks: [ReadingParagraph(line: line)],
    );
    const second = Reading(
      title: ReadingTitle('B'),
      heading: ReadingHeading('B'),
      colour: ReadingColour(0xFF000000),
      blocks: [
        HangingParagraph(line: line),
        NumberedList(items: [line]),
      ],
    );
    const collection = ReadingCollection(readings: [first, second]);
    expect(collection.at(index: const ReadingIndex(1)).title.text, 'B');
    expect(collection.at(index: const ReadingIndex(9)).title.text, 'B');
    expect(collection.at(index: const ReadingIndex(-1)).title.text, 'A');
    expect(first.toString(), 'Reading(A)');
  });
}
