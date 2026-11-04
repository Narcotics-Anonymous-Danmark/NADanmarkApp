import 'dart:async';

import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';

enum SessionVisibility { hidden, shown }

final class MediaSessionMimic implements MediaSessionPort {
  MediaSessionMimic();

  final StreamController<RemoteCommand> _commands =
      StreamController<RemoteCommand>.broadcast(sync: true);
  List<SessionTrack> shown = const [];
  List<SessionPlayback> playbacks = const [];
  SessionVisibility visibility = SessionVisibility.hidden;
  CallCount hides = const CallCount(0);

  SessionPlayback get lastPlayback => playbacks.last;

  SessionTrack get lastTrack => shown.last;

  @override
  Stream<RemoteCommand> get commands => _commands.stream;

  @override
  Future<void> show({
    required SessionTrack track,
    required SessionPlayback playback,
  }) async {
    visibility = SessionVisibility.shown;
    shown = List.unmodifiable([...shown, track]);
    playbacks = List.unmodifiable([...playbacks, playback]);
  }

  @override
  Future<void> update({required SessionPlayback playback}) async {
    playbacks = List.unmodifiable([...playbacks, playback]);
  }

  @override
  Future<void> hide() async {
    visibility = SessionVisibility.hidden;
    hides = hides.next;
  }

  void press({required RemoteCommand command}) => _commands.add(command);

  Future<void> dispose() => _commands.close();
}
