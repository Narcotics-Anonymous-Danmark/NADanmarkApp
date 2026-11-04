import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_playlist.dart';
import 'package:na_kernel/src/media/media_values.dart';

enum ActiveStatus { loading, playing, paused }

@immutable
sealed class PlayerState {
  const PlayerState();
}

final class PlayerIdle extends PlayerState {
  const PlayerIdle();

  @override
  int get hashCode => (PlayerIdle).hashCode;

  @override
  bool operator ==(Object other) => other is PlayerIdle;

  @override
  String toString() => 'PlayerIdle';
}

final class PlayerActive extends PlayerState {
  const PlayerActive({
    required this.playlist,
    required this.trackIndex,
    required this.status,
    required this.position,
    required this.length,
  });

  final MediaPlaylist playlist;
  final TrackIndex trackIndex;
  final ActiveStatus status;
  final Duration position;
  final MediaLength length;

  MediaTrack get track => playlist.tracks[trackIndex.position];

  PlayerActive withStatus({required ActiveStatus status}) => PlayerActive(
    playlist: playlist,
    trackIndex: trackIndex,
    status: status,
    position: position,
    length: length,
  );

  PlayerActive withPosition({required Duration position}) => PlayerActive(
    playlist: playlist,
    trackIndex: trackIndex,
    status: status,
    position: position,
    length: length,
  );

  PlayerActive withLength({required MediaLength length}) => PlayerActive(
    playlist: playlist,
    trackIndex: trackIndex,
    status: status,
    position: position,
    length: length,
  );

  Duration clampSeek({required Duration target}) {
    final floor = target < Duration.zero ? Duration.zero : target;
    return switch (length) {
      KnownLength(:final duration) when floor > duration - _oneSecond =>
        duration - _oneSecond,
      KnownLength() || UnknownLength() => floor,
    };
  }

  static const Duration _oneSecond = Duration(seconds: 1);

  @override
  int get hashCode =>
      Object.hash(playlist, trackIndex, status, position, length);

  @override
  bool operator ==(Object other) =>
      other is PlayerActive &&
      other.playlist == playlist &&
      other.trackIndex == trackIndex &&
      other.status == status &&
      other.position == position &&
      other.length == length;

  @override
  String toString() =>
      'PlayerActive(${playlist.id.value} #${trackIndex.position} '
      '${status.name} ${position.inSeconds} s / $length)';
}
