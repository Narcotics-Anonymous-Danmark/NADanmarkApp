import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_playlist.dart';
import 'package:na_kernel/src/media/media_values.dart';

enum AudiobookId {
  basicText(
    playlistId: PlaylistId('basic-text'),
    total: DurationLabel('13:53:58'),
  ),
  howAndWhy(
    playlistId: PlaylistId('how-and-why'),
    total: DurationLabel('06:11:37'),
  ),
  stepWorkingGuides(
    playlistId: PlaylistId('step-working-guides'),
    total: DurationLabel('05:03:49'),
  )
  ;

  const AudiobookId({required this.playlistId, required this.total});

  final PlaylistId playlistId;
  final DurationLabel total;
}

@immutable
final class Chapter {
  const Chapter({required this.title, required this.url, required this.label});

  final TrackTitle title;
  final AudioUrl url;
  final DurationLabel label;

  MediaTrack get track => MediaTrack(
    id: TrackId(url.uri.toString()),
    title: title,
    url: url,
    label: label,
  );

  @override
  int get hashCode => Object.hash(title, url, label);

  @override
  bool operator ==(Object other) =>
      other is Chapter &&
      other.title == title &&
      other.url == url &&
      other.label == label;

  @override
  String toString() => 'Chapter(${title.text})';
}

@immutable
final class Audiobook {
  const Audiobook({
    required this.id,
    required this.title,
    required this.chapters,
  });

  final AudiobookId id;
  final PlaylistTitle title;
  final List<Chapter> chapters;

  List<MediaLength> get chapterLengths =>
      List.unmodifiable(chapters.map((chapter) => chapter.label.length));

  MediaPlaylist playlist({required PlaylistCover cover}) => MediaPlaylist(
    id: id.playlistId,
    kind: PlaylistKind.book,
    title: title,
    cover: cover,
    tracks: List.unmodifiable(chapters.map((chapter) => chapter.track)),
  );

  @override
  int get hashCode => Object.hash(id, title, Object.hashAll(chapters));

  @override
  bool operator ==(Object other) =>
      other is Audiobook &&
      other.id == id &&
      other.title == title &&
      other.chapters.length == chapters.length &&
      chapters.indexed.every((entry) => other.chapters[entry.$1] == entry.$2);

  @override
  String toString() =>
      'Audiobook(${id.playlistId.value}, ${chapters.length} chapters)';
}
