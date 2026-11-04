import 'dart:async';

import 'package:feature_media_player/src/application/resume_points.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<MediaPlayer, PlayerState> mediaPlayerProvider =
    NotifierProvider(MediaPlayer.new);

final class MediaPlayer extends Notifier<PlayerState> {
  _Item _item = const _NothingLoaded();
  _LastSave _lastSave = const _NeverSaved();
  _NotificationRequest _notificationRequest = _NotificationRequest.notMade;

  AudioEnginePort get _engine => ref.read(audioEnginePortProvider);

  MediaSessionPort get _session => ref.read(mediaSessionPortProvider);

  NotificationsPort get _notifications => ref.read(notificationsPortProvider);

  Clock get _clock => ref.read(clockProvider);

  ResumePoints get _resume => ref.read(resumePointsProvider.notifier);

  @override
  PlayerState build() {
    final events = _engine.events.listen(_onEngine);
    final commands = _session.commands.listen(_onRemote);
    ref
      ..onDispose(() => unawaited(events.cancel()))
      ..onDispose(() => unawaited(commands.cancel()));
    return const PlayerIdle();
  }

  Future<void> play({
    required MediaPlaylist playlist,
    required StartRequest request,
  }) async {
    if (playlist.tracks.isEmpty) {
      return;
    }
    final current = state;
    switch (current) {
      case PlayerActive(playlist: MediaPlaylist(:final id), :final trackIndex)
          when id == playlist.id &&
              switch (request) {
                ContinueListening() => true,
                StartTrack(:final index) => index == trackIndex,
              }:
        await toggle();
        return;
      case PlayerActive(playlist: MediaPlaylist(:final id))
          when id != playlist.id:
        await savePlace();
      case PlayerActive() || PlayerIdle():
        break;
    }
    final resume = await _resume.pointFor(kind: playlist.kind, id: playlist.id);
    final start = TrackStart.resolve(
      playlist: playlist,
      resume: resume,
      request: request,
    );
    await _startTrack(
      playlist: playlist,
      index: start.index,
      position: start.position,
    );
  }

  Future<void> toggle() async => switch (state) {
    PlayerActive(status: ActiveStatus.playing || ActiveStatus.loading) =>
      pause(),
    PlayerActive(status: ActiveStatus.paused) => resume(),
    PlayerIdle() => null,
  };

  Future<void> pause() async {
    switch (state) {
      case final PlayerActive active:
        await _engine.pause();
        state = active.withStatus(status: ActiveStatus.paused);
        await savePlace();
        await _publishPlayback();
      case PlayerIdle():
        return;
    }
  }

  Future<void> resume() async {
    switch (state) {
      case final PlayerActive active when active.status == ActiveStatus.paused:
        await _engine.play();
        state = active.withStatus(status: ActiveStatus.playing);
        await _publishPlayback();
      case PlayerActive() || PlayerIdle():
        return;
    }
  }

  Future<void> stop() => _stop(place: _Place.keep);

  Future<void> next() async {
    switch (state) {
      case PlayerActive(:final playlist, :final trackIndex)
          when playlist.nextOf(index: trackIndex) == Neighbour.available:
        await _startTrack(
          playlist: playlist,
          index: trackIndex.next,
          position: Duration.zero,
        );
      case PlayerActive() || PlayerIdle():
        return;
    }
  }

  Future<void> previous() async {
    switch (state) {
      case PlayerActive(:final playlist, :final trackIndex)
          when playlist.previousOf(index: trackIndex) == Neighbour.available:
        await _startTrack(
          playlist: playlist,
          index: trackIndex.previous,
          position: Duration.zero,
        );
      case PlayerActive() || PlayerIdle():
        return;
    }
  }

  Future<void> seekTo({required Duration position}) async {
    switch (state) {
      case final PlayerActive active:
        final target = active.clampSeek(target: position);
        await _engine.seek(position: target);
        state = switch (state) {
          final PlayerActive latest => latest.withPosition(position: target),
          PlayerIdle() => const PlayerIdle(),
        };
        await savePlace();
        await _publishPlayback();
      case PlayerIdle():
        return;
    }
  }

  Future<void> seekBy({required Duration delta}) async => switch (state) {
    PlayerActive(:final position) => seekTo(position: position + delta),
    PlayerIdle() => null,
  };

  Future<void> savePlace() async {
    switch (state) {
      case PlayerActive(
        :final playlist,
        :final trackIndex,
        :final position,
        :final length,
        :final track,
      ):
        final now = _clock.now();
        _lastSave = _SavedAt(at: now);
        await _resume.save(
          kind: playlist.kind,
          id: playlist.id,
          point: ResumePoint(
            trackId: track.id,
            trackIndex: trackIndex,
            position: position,
            length: length,
            updatedAt: now,
          ),
        );
      case PlayerIdle():
        return;
    }
  }

  Future<void> _startTrack({
    required MediaPlaylist playlist,
    required TrackIndex index,
    required Duration position,
  }) async {
    switch (playlist.trackAt(index: index)) {
      case FoundTrack(:final track):
        final attempt = _Starting();
        _item = attempt;
        await _engine.release();
        state = PlayerActive(
          playlist: playlist,
          trackIndex: index,
          status: ActiveStatus.loading,
          position: position,
          length: track.label.length,
        );
        final token = await _engine.load(
          item: EngineItem(url: track.url, title: track.title),
          startAt: position,
        );
        if (!identical(_item, attempt)) {
          return;
        }
        _item = _ItemLoaded(token: token);
        await _engine.play();
        await savePlace();
        _askForNotificationsOnce();
        await _showSession();
      case NoTrackAt():
        return;
    }
  }

  Future<void> _stop({required _Place place}) async {
    switch (place) {
      case _Place.keep:
        await savePlace();
      case _Place.forget:
        break;
    }
    _item = const _NothingLoaded();
    await _engine.release();
    await _session.hide();
    if (ref.mounted) {
      state = const PlayerIdle();
    }
  }

  void _onEngine(EngineEvent event) {
    switch ((_item, state)) {
      case (_ItemLoaded(:final token), final PlayerActive active)
          when token == event.token:
        unawaited(_handle(event: event, active: active));
      case (
        _ItemLoaded() || _Starting() || _NothingLoaded(),
        PlayerActive() || PlayerIdle(),
      ):
        return;
    }
  }

  Future<void> _handle({
    required EngineEvent event,
    required PlayerActive active,
  }) async {
    switch (event) {
      case EngineRunning():
        if (active.status == ActiveStatus.loading) {
          state = active.withStatus(status: ActiveStatus.playing);
          await _publishPlayback();
        }
      case EngineLength(:final length):
        state = active.withLength(length: MediaLength.of(duration: length));
        await _showSession();
      case EnginePosition(:final position):
        if (active.status != ActiveStatus.playing) {
          return;
        }
        state = active.withPosition(position: position);
        if (_saveDue(now: _clock.now()) == _SaveDue.due) {
          await savePlace();
          await _publishPlayback();
        }
      case EngineEnded():
        await _ended(active: active);
      case EngineFailed():
        await _stop(place: _Place.keep);
    }
  }

  Future<void> _ended({required PlayerActive active}) async {
    switch (active.playlist.nextOf(index: active.trackIndex)) {
      case Neighbour.available:
        await _startTrack(
          playlist: active.playlist,
          index: active.trackIndex.next,
          position: Duration.zero,
        );
      case Neighbour.unavailable:
        await _resume.clear(kind: active.playlist.kind, id: active.playlist.id);
        await _stop(place: _Place.forget);
    }
  }

  void _onRemote(RemoteCommand command) => unawaited(switch (command) {
    RemotePlay() => resume(),
    RemotePause() => pause(),
    RemoteToggle() => toggle(),
    RemoteNext() => next(),
    RemotePrevious() => previous(),
    RemoteSkipForward() => seekBy(delta: MediaRules.skipForward),
    RemoteSkipBackward() => seekBy(delta: -MediaRules.skipBackward),
    RemoteSeek(:final position) => seekTo(position: position),
    RemoteStop() => stop(),
  });

  _SaveDue _saveDue({required Instant now}) => switch (_lastSave) {
    _NeverSaved() => _SaveDue.due,
    _SavedAt(:final at) when now.since(other: at) >= MediaRules.saveEvery =>
      _SaveDue.due,
    _SavedAt() => _SaveDue.notYet,
  };

  void _askForNotificationsOnce() {
    switch (_notificationRequest) {
      case _NotificationRequest.notMade:
        _notificationRequest = _NotificationRequest.made;
        unawaited(_notifications.ensureAccess());
      case _NotificationRequest.made:
        return;
    }
  }

  Future<void> _showSession() async {
    switch (state) {
      case final PlayerActive active:
        await _session.show(
          track: SessionTrack(
            id: active.track.id,
            title: active.track.title,
            album: active.playlist.title,
            cover: active.playlist.cover,
            length: active.length,
            kind: active.playlist.kind,
            previous: _neighbour(
              active: active,
              neighbour: active.playlist.previousOf(index: active.trackIndex),
            ),
            next: _neighbour(
              active: active,
              neighbour: active.playlist.nextOf(index: active.trackIndex),
            ),
          ),
          playback: SessionPlayback(
            status: active.status,
            position: active.position,
          ),
        );
      case PlayerIdle():
        return;
    }
  }

  Neighbour _neighbour({
    required PlayerActive active,
    required Neighbour neighbour,
  }) => switch (active.playlist.kind) {
    PlaylistKind.book => neighbour,
    PlaylistKind.speak => Neighbour.unavailable,
  };

  Future<void> _publishPlayback() async {
    switch (state) {
      case PlayerActive(:final status, :final position):
        await _session.update(
          playback: SessionPlayback(status: status, position: position),
        );
      case PlayerIdle():
        return;
    }
  }
}

enum _NotificationRequest { notMade, made }

enum _SaveDue { due, notYet }

sealed class _LastSave {
  const _LastSave();
}

final class _NeverSaved extends _LastSave {
  const _NeverSaved();
}

final class _SavedAt extends _LastSave {
  const _SavedAt({required this.at});

  final Instant at;
}

enum _Place { keep, forget }

sealed class _Item {
  const _Item();
}

final class _Starting extends _Item {
  _Starting();
}

final class _ItemLoaded extends _Item {
  const _ItemLoaded({required this.token});

  final LoadToken token;
}

final class _NothingLoaded extends _Item {
  const _NothingLoaded();
}
