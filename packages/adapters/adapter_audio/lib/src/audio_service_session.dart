import 'dart:async';

import 'package:adapter_audio/src/artwork_files.dart';
import 'package:audio_service/audio_service.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class AudioServiceSession extends BaseAudioHandler
    implements MediaSessionPort {
  AudioServiceSession({required this.artwork});

  final ArtworkFiles artwork;
  final StreamController<RemoteCommand> _commands =
      StreamController<RemoteCommand>.broadcast();
  _Shown _shown = const _NothingShown();

  @override
  Stream<RemoteCommand> get commands => _commands.stream;

  @override
  Future<void> show({
    required SessionTrack track,
    required SessionPlayback playback,
  }) async {
    _shown = _TrackShown(track: track);
    mediaItem.add(
      MediaItem(
        id: track.id.value,
        title: track.title.text,
        album: track.album.text,
        artist: track.album.text,
        duration: switch (track.length) {
          KnownLength(:final duration) => duration,
          UnknownLength() => null,
        },
        artUri: await artwork.uriFor(cover: track.cover),
      ),
    );
    playbackState.add(stateOf(track: track, playback: playback));
  }

  @override
  Future<void> update({required SessionPlayback playback}) async {
    switch (_shown) {
      case _TrackShown(:final track):
        playbackState.add(stateOf(track: track, playback: playback));
      case _NothingShown():
        return;
    }
  }

  @override
  Future<void> hide() async {
    _shown = const _NothingShown();
    playbackState.add(PlaybackState());
    mediaItem.add(null);
  }

  static PlaybackState stateOf({
    required SessionTrack track,
    required SessionPlayback playback,
  }) {
    final playing = playback.status == ActiveStatus.playing;
    final controls = [
      if (track.previous == Neighbour.available) MediaControl.skipToPrevious,
      MediaControl.rewind,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.fastForward,
      if (track.next == Neighbour.available) MediaControl.skipToNext,
      MediaControl.stop,
    ];
    final rewind = controls.indexOf(MediaControl.rewind);
    return PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [rewind, rewind + 1, rewind + 2],
      processingState: switch (playback.status) {
        ActiveStatus.loading => AudioProcessingState.loading,
        ActiveStatus.playing ||
        ActiveStatus.paused => AudioProcessingState.ready,
      },
      playing: playing,
      updatePosition: playback.position,
    );
  }

  @override
  Future<void> play() async => _commands.add(const RemotePlay());

  @override
  Future<void> pause() async => _commands.add(const RemotePause());

  @override
  Future<void> stop() async => _commands.add(const RemoteStop());

  @override
  Future<void> skipToNext() async => _commands.add(const RemoteNext());

  @override
  Future<void> skipToPrevious() async => _commands.add(const RemotePrevious());

  @override
  Future<void> fastForward() async => _commands.add(const RemoteSkipForward());

  @override
  Future<void> rewind() async => _commands.add(const RemoteSkipBackward());

  @override
  Future<void> seek(Duration position) async =>
      _commands.add(RemoteSeek(position: position));

  @override
  Future<void> click([MediaButton? button]) async =>
      _commands.add(switch (button) {
        MediaButton.media || null => const RemoteToggle(),
        MediaButton.next => const RemoteNext(),
        MediaButton.previous => const RemotePrevious(),
      });

  Future<void> close() => _commands.close();
}

sealed class _Shown {
  const _Shown();
}

final class _NothingShown extends _Shown {
  const _NothingShown();
}

final class _TrackShown extends _Shown {
  const _TrackShown({required this.track});

  final SessionTrack track;
}
