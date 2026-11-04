import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_values.dart';

@immutable
final class MediaTrack {
  const MediaTrack({
    required this.id,
    required this.title,
    required this.url,
    required this.label,
  });

  final TrackId id;
  final TrackTitle title;
  final AudioUrl url;
  final DurationLabel label;

  @override
  int get hashCode => Object.hash(id, title, url, label);

  @override
  bool operator ==(Object other) =>
      other is MediaTrack &&
      other.id == id &&
      other.title == title &&
      other.url == url &&
      other.label == label;

  @override
  String toString() => 'MediaTrack(${title.text})';
}

@immutable
sealed class TrackLookup {
  const TrackLookup();
}

final class FoundTrack extends TrackLookup {
  const FoundTrack({required this.index, required this.track});

  final TrackIndex index;
  final MediaTrack track;
}

final class NoTrackAt extends TrackLookup {
  const NoTrackAt();
}

enum Neighbour { available, unavailable }

@immutable
final class MediaPlaylist {
  const MediaPlaylist({
    required this.id,
    required this.kind,
    required this.title,
    required this.cover,
    required this.tracks,
  });

  final PlaylistId id;
  final PlaylistKind kind;
  final PlaylistTitle title;
  final PlaylistCover cover;
  final List<MediaTrack> tracks;

  TrackLookup trackAt({required TrackIndex index}) =>
      index.position >= 0 && index.position < tracks.length
      ? FoundTrack(index: index, track: tracks[index.position])
      : const NoTrackAt();

  TrackLookup trackWithId({required TrackId id}) =>
      switch (tracks.indexWhere((track) => track.id == id)) {
        -1 => const NoTrackAt(),
        final int position => FoundTrack(
          index: TrackIndex(position),
          track: tracks[position],
        ),
      };

  Neighbour previousOf({required TrackIndex index}) =>
      index.position > 0 ? Neighbour.available : Neighbour.unavailable;

  Neighbour nextOf({required TrackIndex index}) =>
      index.position < tracks.length - 1
      ? Neighbour.available
      : Neighbour.unavailable;

  static const ListEquality<MediaTrack> _tracks = ListEquality();

  @override
  int get hashCode => Object.hash(id, kind, title, cover, _tracks.hash(tracks));

  @override
  bool operator ==(Object other) =>
      other is MediaPlaylist &&
      other.id == id &&
      other.kind == kind &&
      other.title == title &&
      other.cover == cover &&
      _tracks.equals(other.tracks, tracks);

  @override
  String toString() => 'MediaPlaylist(${kind.code} ${id.value})';
}
