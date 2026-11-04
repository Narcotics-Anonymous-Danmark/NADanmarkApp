import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

extension WholeSeconds on int {
  Duration get seconds => Duration(seconds: this);
}

TrackId chapterTrackId({required TrackIndex index}) =>
    TrackId('https://audio.test/chapter-${index.position}.mp3');

MediaTrack aMediaTrack({
  TrackId id = const TrackId('https://audio.test/chapter-0.mp3'),
  TrackTitle title = const TrackTitle('01. Chapter'),
  DurationLabel label = const DurationLabel('8:10'),
}) => MediaTrack(
  id: id,
  title: title,
  url: AudioUrl(Uri.parse(id.value)),
  label: label,
);

MediaPlaylist aBookPlaylist({
  PlaylistId id = const PlaylistId('basic-text'),
  PlaylistTitle title = const PlaylistTitle('Basis Tekst'),
  ChapterCount chapters = const ChapterCount(5),
  DurationLabel label = const DurationLabel('8:10'),
  PlaylistCover cover = const NoCover(),
}) => MediaPlaylist(
  id: id,
  kind: PlaylistKind.book,
  title: title,
  cover: cover,
  tracks: List.unmodifiable(
    List.generate(
      chapters.value,
      (index) => aMediaTrack(
        id: chapterTrackId(index: TrackIndex(index)),
        title: TrackTitle('Chapter ${index + 1}'),
        label: label,
      ),
    ),
  ),
);

const PlaylistId aSpeakUrl = PlaylistId('https://audio.test/speak.mp3');

MediaPlaylist aSpeakPlaylist({
  PlaylistId url = aSpeakUrl,
  PlaylistTitle title = const PlaylistTitle('Convention 2024'),
  TrackTitle trackTitle = const TrackTitle('Anna D.'),
  DurationLabel label = const DurationLabel(''),
}) => MediaPlaylist(
  id: url,
  kind: PlaylistKind.speak,
  title: title,
  cover: const NoCover(),
  tracks: List.unmodifiable([
    MediaTrack(
      id: TrackId(url.value),
      title: trackTitle,
      url: AudioUrl(Uri.parse(url.value)),
      label: label,
    ),
  ]),
);

final Instant aResumeTime = Instant(DateTime.utc(2026, 5, 1, 10));

ResumePoint aResumePoint({
  TrackIndex trackIndex = const TrackIndex(4),
  Duration position = const Duration(seconds: 120),
  MediaLength length = const KnownLength(duration: Duration(seconds: 600)),
}) => ResumePoint(
  trackId: chapterTrackId(index: trackIndex),
  trackIndex: trackIndex,
  position: position,
  length: length,
  updatedAt: aResumeTime,
);

Map<String, String> aStoredResumePoint({
  required ResumePoint point,
  PlaylistKind kind = PlaylistKind.book,
  PlaylistId id = const PlaylistId('basic-text'),
}) {
  const codec = ResumeCodec();
  return Map.unmodifiable({
    kind.pointKey(id: id).name: codec.encodePoint(point: point),
    kind.indexKey.name: codec.encodeIndex(
      index: ResumeIndex.empty.withPoint(id: id, point: point),
    ),
  });
}

LegacyStoreDumpDto aLegacyResumeDump({
  Map<String, ResumePointDto> entries = const {},
}) => LegacyStoreDumpDto(
  mediaResume: entries.isEmpty
      ? {
          'mediaResume.book.basic-text': const ResumeCodec().dtoOf(
            point: aResumePoint(),
          ),
        }
      : entries,
);
