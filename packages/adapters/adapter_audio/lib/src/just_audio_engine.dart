import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:na_ports/na_ports.dart';

final class JustAudioEngine implements AudioEnginePort {
  JustAudioEngine({required this.player, required this.positionEvery}) {
    _subscriptions.addAll([
      player.playerStateStream.listen(_onPlayerState),
      player.durationStream.listen(_onDuration),
      player.errorStream.listen(
        (error) => _fail(detail: '${error.code}: ${error.message}'),
      ),
      player
          .createPositionStream(
            minPeriod: positionEvery,
            maxPeriod: positionEvery,
          )
          .listen(_onPosition),
    ]);
  }

  final AudioPlayer player;
  final Duration positionEvery;
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  _Item _item = const _NoItem();

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Future<LoadToken> load({
    required EngineItem item,
    required Duration startAt,
  }) async {
    final token = LoadToken();
    _item = _LiveItem(token: token, phase: _Phase.waiting);
    try {
      await player.setAudioSource(
        AudioSource.uri(item.url.uri),
        initialPosition: startAt,
      );
    } on PlayerInterruptedException {
      return token;
    } on PlayerException catch (error) {
      _failLoad(token: token, detail: '${error.code}: ${error.message}');
    } on PlatformException catch (error) {
      _failLoad(token: token, detail: '${error.code}: ${error.message}');
    }
    return token;
  }

  @override
  Future<void> play() async {
    switch (_item) {
      case _LiveItem():
        unawaited(player.play());
      case _NoItem():
        return;
    }
  }

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek({required Duration position}) => player.seek(position);

  @override
  Future<void> release() async {
    _item = const _NoItem();
    await player.stop();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await player.dispose();
    await _events.close();
  }

  void _failLoad({required LoadToken token, required String detail}) {
    switch (_item) {
      case _LiveItem(token: final current) when current == token:
        _item = const _NoItem();
      case _LiveItem() || _NoItem():
        break;
    }
    _emit(
      event: EngineFailed(token: token, detail: EngineFailureDetail(detail)),
    );
  }

  void _onPlayerState(PlayerState state) {
    switch ((_item, state.processingState)) {
      case (
            _LiveItem(:final token, phase: _Phase.waiting),
            ProcessingState.ready,
          )
          when state.playing:
        _item = _LiveItem(token: token, phase: _Phase.running);
        _emit(event: EngineRunning(token: token));
      case (_LiveItem(:final token), ProcessingState.completed):
        _item = const _NoItem();
        _emit(event: EngineEnded(token: token));
      case (_LiveItem() || _NoItem(), ProcessingState()):
        return;
    }
  }

  void _onDuration(Duration? duration) {
    switch (_item) {
      case _LiveItem(:final token)
          when duration != null && duration > Duration.zero:
        _emit(
          event: EngineLength(token: token, length: duration),
        );
      case _LiveItem() || _NoItem():
        return;
    }
  }

  void _onPosition(Duration position) {
    switch (_item) {
      case _LiveItem(:final token, phase: _Phase.running) when player.playing:
        _emit(
          event: EnginePosition(token: token, position: position),
        );
      case _LiveItem() || _NoItem():
        return;
    }
  }

  void _fail({required String detail}) {
    switch (_item) {
      case _LiveItem(:final token):
        _item = const _NoItem();
        _emit(
          event: EngineFailed(
            token: token,
            detail: EngineFailureDetail(detail),
          ),
        );
      case _NoItem():
        return;
    }
  }

  void _emit({required EngineEvent event}) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}

enum _Phase { waiting, running }

sealed class _Item {
  const _Item();
}

final class _NoItem extends _Item {
  const _NoItem();
}

final class _LiveItem extends _Item {
  const _LiveItem({required this.token, required this.phase});

  final LoadToken token;
  final _Phase phase;
}
