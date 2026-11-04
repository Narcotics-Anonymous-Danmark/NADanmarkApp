import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_playlist.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/time/instant.dart';
import 'package:na_kernel/src/values/storage_key.dart';

@immutable
final class ResumePoint {
  ResumePoint({
    required this.trackId,
    required this.trackIndex,
    required Duration position,
    required this.length,
    required this.updatedAt,
  }) : position = Duration(seconds: position.inSeconds);

  final TrackId trackId;
  final TrackIndex trackIndex;
  final Duration position;
  final MediaLength length;
  final Instant updatedAt;

  @override
  int get hashCode =>
      Object.hash(trackId, trackIndex, position, length, updatedAt);

  @override
  bool operator ==(Object other) =>
      other is ResumePoint &&
      other.trackId == trackId &&
      other.trackIndex == trackIndex &&
      other.position == position &&
      other.length == length &&
      other.updatedAt == updatedAt;

  @override
  String toString() =>
      'ResumePoint(${trackIndex.position} @ ${position.inSeconds} s, '
      '$length, ${trackId.value})';
}

@immutable
sealed class ResumeState {
  const ResumeState();
}

final class NotStarted extends ResumeState {
  const NotStarted();

  @override
  int get hashCode => (NotStarted).hashCode;

  @override
  bool operator ==(Object other) => other is NotStarted;

  @override
  String toString() => 'NotStarted';
}

final class ResumeAt extends ResumeState {
  const ResumeAt({required this.point});

  final ResumePoint point;

  @override
  int get hashCode => Object.hash(ResumeAt, point);

  @override
  bool operator ==(Object other) => other is ResumeAt && other.point == point;

  @override
  String toString() => 'ResumeAt($point)';
}

@immutable
final class ResumeIndex {
  const ResumeIndex({required this.points});

  static const ResumeIndex empty = ResumeIndex(points: {});

  final Map<PlaylistId, ResumePoint> points;

  ResumeState stateOf({required PlaylistId id}) => switch (points[id]) {
    final ResumePoint point => ResumeAt(point: point),
    null => const NotStarted(),
  };

  ResumeIndex withPoint({
    required PlaylistId id,
    required ResumePoint point,
  }) => ResumeIndex(points: Map.unmodifiable({...points, id: point}));

  ResumeIndex without({required PlaylistId id}) => ResumeIndex(
    points: Map.unmodifiable(
      Map.fromEntries(points.entries.where((entry) => entry.key != id)),
    ),
  );

  @override
  int get hashCode => Object.hashAllUnordered(
    points.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  @override
  bool operator ==(Object other) =>
      other is ResumeIndex &&
      other.points.length == points.length &&
      points.entries.every((entry) => other.points[entry.key] == entry.value);

  @override
  String toString() => 'ResumeIndex($points)';
}

const String resumeKeyPrefix = 'mediaResume.';

extension ResumeKeys on PlaylistKind {
  String get pointKeyPrefix => '$resumeKeyPrefix$code.';

  StorageKey pointKey({required PlaylistId id}) =>
      StorageKey('$pointKeyPrefix${id.value}');

  StorageKey get indexKey => StorageKey('${resumeKeyPrefix}index.$code');
}

@immutable
sealed class ResumeTrack {
  const ResumeTrack();

  static ResumeTrack of({
    required MediaPlaylist playlist,
    required ResumeState resume,
  }) => switch (resume) {
    NotStarted() => const NoResumeTrack(),
    ResumeAt(:final point) => switch (playlist.trackAt(
      index: point.trackIndex,
    )) {
      FoundTrack(:final track, :final index) when track.id == point.trackId =>
        ResumeTrackAt(index: index, position: point.position),
      FoundTrack() || NoTrackAt() => switch (playlist.trackWithId(
        id: point.trackId,
      )) {
        FoundTrack(:final index) => ResumeTrackAt(
          index: index,
          position: point.position,
        ),
        NoTrackAt() => const NoResumeTrack(),
      },
    },
  };
}

final class ResumeTrackAt extends ResumeTrack {
  const ResumeTrackAt({required this.index, required this.position});

  final TrackIndex index;
  final Duration position;
}

final class NoResumeTrack extends ResumeTrack {
  const NoResumeTrack();
}
