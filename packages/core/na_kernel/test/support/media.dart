import 'package:na_kernel/na_kernel.dart';

extension WholeSeconds on int {
  Duration get seconds => Duration(seconds: this);
}

KnownLength lengthOf(Duration duration) => KnownLength(duration: duration);

MediaTrack aTrack({
  TrackId id = const TrackId('https://example.dk/1.mp3'),
  TrackTitle title = const TrackTitle('01. Track'),
  DurationLabel label = const DurationLabel('8:10'),
}) => MediaTrack(
  id: id,
  title: title,
  url: AudioUrl(Uri.parse(id.value)),
  label: label,
);

TrackId chapterId(TrackIndex index) =>
    TrackId('https://example.dk/${index.position}.mp3');

MediaPlaylist aBook({
  ChapterCount chapters = const ChapterCount(8),
  PlaylistId id = const PlaylistId('basic-text'),
}) => MediaPlaylist(
  id: id,
  kind: PlaylistKind.book,
  title: const PlaylistTitle('Basis Tekst'),
  cover: const NoCover(),
  tracks: List.generate(
    chapters.value,
    (index) => aTrack(
      id: chapterId(TrackIndex(index)),
      title: TrackTitle('Chapter $index'),
    ),
  ),
);

ResumePoint aPoint({
  TrackIndex trackIndex = const TrackIndex(4),
  TrackId? trackId,
  Duration? position,
  MediaLength? length,
  Instant? updatedAt,
}) => ResumePoint(
  trackId: trackId ?? chapterId(trackIndex),
  trackIndex: trackIndex,
  position: position ?? 120.seconds,
  length: length ?? lengthOf(600.seconds),
  updatedAt: updatedAt ?? Instant(DateTime.utc(2026, 5)),
);
