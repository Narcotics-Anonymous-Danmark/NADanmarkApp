import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_playlist.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/media/resume_point.dart';

@immutable
sealed class StartRequest {
  const StartRequest();
}

final class ContinueListening extends StartRequest {
  const ContinueListening();
}

final class StartTrack extends StartRequest {
  const StartTrack({required this.index});

  final TrackIndex index;
}

@immutable
final class TrackStart {
  const TrackStart({required this.index, required this.position});

  factory TrackStart.resolve({
    required MediaPlaylist playlist,
    required ResumeState resume,
    required StartRequest request,
  }) => switch ((request, ResumeTrack.of(playlist: playlist, resume: resume))) {
    (ContinueListening(), ResumeTrackAt(:final index, :final position)) =>
      TrackStart(
        index: index,
        position: _worthResuming(position: position),
      ),
    (ContinueListening(), NoResumeTrack()) => const TrackStart(
      index: TrackIndex(0),
      position: Duration.zero,
    ),
    (
      StartTrack(:final index),
      ResumeTrackAt(index: final resumed, :final position),
    )
        when resumed == index =>
      TrackStart(
        index: index,
        position: _worthResuming(position: position),
      ),
    (StartTrack(:final index), ResumeTrackAt() || NoResumeTrack()) =>
      TrackStart(index: index, position: Duration.zero),
  };

  static Duration _worthResuming({required Duration position}) =>
      position < MediaRules.minimumResume ? Duration.zero : position;

  final TrackIndex index;
  final Duration position;

  @override
  int get hashCode => Object.hash(index, position);

  @override
  bool operator ==(Object other) =>
      other is TrackStart && other.index == index && other.position == position;

  @override
  String toString() =>
      'TrackStart(${index.position} @ ${position.inSeconds} s)';
}
