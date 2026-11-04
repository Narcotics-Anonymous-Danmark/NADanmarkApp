import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class RemoteCommand {
  const RemoteCommand();
}

final class RemotePlay extends RemoteCommand {
  const RemotePlay();
}

final class RemotePause extends RemoteCommand {
  const RemotePause();
}

final class RemoteToggle extends RemoteCommand {
  const RemoteToggle();
}

final class RemoteNext extends RemoteCommand {
  const RemoteNext();
}

final class RemotePrevious extends RemoteCommand {
  const RemotePrevious();
}

final class RemoteSkipForward extends RemoteCommand {
  const RemoteSkipForward();
}

final class RemoteSkipBackward extends RemoteCommand {
  const RemoteSkipBackward();
}

final class RemoteSeek extends RemoteCommand {
  const RemoteSeek({required this.position});

  final Duration position;
}

final class RemoteStop extends RemoteCommand {
  const RemoteStop();
}

@immutable
final class SessionTrack {
  const SessionTrack({
    required this.id,
    required this.title,
    required this.album,
    required this.cover,
    required this.length,
    required this.kind,
    required this.previous,
    required this.next,
  });

  final TrackId id;
  final TrackTitle title;
  final PlaylistTitle album;
  final PlaylistCover cover;
  final MediaLength length;
  final PlaylistKind kind;
  final Neighbour previous;
  final Neighbour next;

  @override
  int get hashCode =>
      Object.hash(id, title, album, cover, length, kind, previous, next);

  @override
  bool operator ==(Object other) =>
      other is SessionTrack &&
      other.id == id &&
      other.title == title &&
      other.album == album &&
      other.cover == cover &&
      other.length == length &&
      other.kind == kind &&
      other.previous == previous &&
      other.next == next;

  @override
  String toString() =>
      'SessionTrack(${title.text} / ${album.text}, $length, '
      'previous ${previous.name}, next ${next.name})';
}

@immutable
final class SessionPlayback {
  const SessionPlayback({required this.status, required this.position});

  final ActiveStatus status;
  final Duration position;

  @override
  int get hashCode => Object.hash(status, position);

  @override
  bool operator ==(Object other) =>
      other is SessionPlayback &&
      other.status == status &&
      other.position == position;

  @override
  String toString() =>
      'SessionPlayback(${status.name}, ${position.inSeconds} s)';
}

abstract interface class MediaSessionPort {
  Stream<RemoteCommand> get commands;

  Future<void> show({
    required SessionTrack track,
    required SessionPlayback playback,
  });

  Future<void> update({required SessionPlayback playback});

  Future<void> hide();
}

final Provider<MediaSessionPort> mediaSessionPortProvider = unboundPort(
  portName: 'MediaSessionPort',
);
