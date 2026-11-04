import 'package:na_kernel/na_kernel.dart';

Audiobook anAudiobook({
  AudiobookId id = AudiobookId.basicText,
  PlaylistTitle title = const PlaylistTitle('Basis Tekst'),
  ChapterCount chapters = const ChapterCount(5),
  DurationLabel label = const DurationLabel('8:10'),
}) => Audiobook(
  id: id,
  title: title,
  chapters: List.unmodifiable(
    List.generate(
      chapters.value,
      (index) => Chapter(
        title: TrackTitle('Chapter ${index + 1}'),
        url: AudioUrl(
          Uri.parse('https://audio.test/${id.playlistId.value}/$index.mp3'),
        ),
        label: label,
      ),
    ),
  ),
);

ReadingLine aReadingLine({
  ReadingText text = const ReadingText('Vi er her.'),
}) => ReadingLine(
  spans: List.unmodifiable([ReadingSpan(text: text, emphasis: Emphasis.plain)]),
);

Reading aReading({
  ReadingTitle title = const ReadingTitle('Hvem er en addict?'),
  ReadingHeading heading = const ReadingHeading('Hvem er en addict?'),
  ReadingColour colour = const ReadingColour(0xFF9AD9E8),
  List<ReadingBlock> blocks = const [],
}) => Reading(
  title: title,
  heading: heading,
  colour: colour,
  blocks: blocks.isEmpty
      ? List.unmodifiable([ReadingParagraph(line: aReadingLine())])
      : blocks,
);

ReadingCollection aReadingCollection({List<Reading> readings = const []}) =>
    ReadingCollection(
      readings: readings.isEmpty
          ? List.unmodifiable([
              aReading(),
              aReading(
                title: const ReadingTitle('Sådan virker det'),
                heading: const ReadingHeading('Sådan virker det'),
                colour: const ReadingColour(0xFFFFFFFF),
                blocks: [
                  NumberedList(
                    items: List.unmodifiable([
                      aReadingLine(text: const ReadingText('Første trin.')),
                      aReadingLine(text: const ReadingText('Andet trin.')),
                    ]),
                  ),
                ],
              ),
            ])
          : List.unmodifiable(readings),
    );
