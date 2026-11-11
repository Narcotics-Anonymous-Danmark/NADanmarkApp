import 'dart:async';

import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';
import 'package:na_testing/src/time/test_time.dart';

enum EngineStart { whenPlayed, onCue }

enum EnginePlayback { stopped, playing, paused }

enum LoadGate { open, held }

@immutable
final class EngineLoad {
  const EngineLoad({
    required this.item,
    required this.startAt,
    required this.token,
  });

  final EngineItem item;
  final Duration startAt;
  final LoadToken token;

  @override
  int get hashCode => Object.hash(item, startAt, token);

  @override
  bool operator ==(Object other) =>
      other is EngineLoad &&
      other.item == item &&
      other.startAt == startAt &&
      other.token == token;

  @override
  String toString() =>
      'EngineLoad(${item.url.uri} @ ${startAt.inSeconds} s, $token)';
}

final class AudioEngineMimic implements AudioEnginePort {
  AudioEngineMimic({
    required this.time,
    required this.start,
    required this.reportedLength,
  });

  static const Duration tick = Duration(seconds: 1);

  final TestTime time;
  EngineStart start;
  MediaLength reportedLength;
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast(sync: true);
  _MimicItem _item = const _Unloaded();
  EnginePlayback playback = EnginePlayback.stopped;
  _TickState _ticking = const _NotTicking();
  List<EngineLoad> loads = const [];
  List<Duration> seeks = const [];
  CallCount plays = const CallCount(0);
  CallCount pauses = const CallCount(0);
  CallCount releases = const CallCount(0);
  LoadGate gate = LoadGate.open;
  Completer<void> _held = Completer<void>();

  LoadToken get token => _loaded.token;

  Duration get position => _loaded.position;

  _Loaded get _loaded => switch (_item) {
    final _Loaded loaded => loaded,
    _Unloaded() => throw StateError('the engine mimic has nothing loaded'),
  };

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Future<void> load({
    required EngineItem item,
    required Duration startAt,
    required LoadToken token,
  }) async {
    _stopTicking();
    _item = _Loaded(token: token, position: startAt, started: _Started.no);
    playback = EnginePlayback.paused;
    loads = List.unmodifiable([
      ...loads,
      EngineLoad(item: item, startAt: startAt, token: token),
    ]);
    switch (reportedLength) {
      case KnownLength(:final duration):
        _events.add(EngineLength(token: token, length: duration));
      case UnknownLength():
        break;
    }
    switch (gate) {
      case LoadGate.held:
        await _held.future;
      case LoadGate.open:
        break;
    }
  }

  void openLoads() {
    gate = LoadGate.open;
    _held.complete();
    _held = Completer<void>();
  }

  @override
  Future<void> play() async {
    plays = plays.next;
    playback = EnginePlayback.playing;
    switch ((start, _item)) {
      case (EngineStart.whenPlayed, _Loaded(started: _Started.no)):
        run();
      case (
        EngineStart.whenPlayed || EngineStart.onCue,
        _Loaded(started: _Started.yes),
      ):
        _startTicking();
      case (EngineStart.onCue, _Loaded(started: _Started.no)):
      case (EngineStart(), _Unloaded()):
        break;
    }
  }

  @override
  Future<void> pause() async {
    pauses = pauses.next;
    playback = EnginePlayback.paused;
    _stopTicking();
  }

  @override
  Future<void> seek({required Duration position}) async {
    seeks = List.unmodifiable([...seeks, position]);
    _item = _loaded.at(position: position);
  }

  @override
  Future<void> release() async {
    releases = releases.next;
    playback = EnginePlayback.stopped;
    _stopTicking();
  }

  void run() {
    final loaded = _loaded;
    _item = loaded.running();
    _events.add(EngineRunning(token: loaded.token));
    _startTicking();
  }

  void finish() {
    _stopTicking();
    _events.add(EngineEnded(token: token));
  }

  void fail({required EngineFailureDetail detail}) {
    _stopTicking();
    _events.add(EngineFailed(token: token, detail: detail));
  }

  void emit({required EngineEvent event}) => _events.add(event);

  void _startTicking() {
    _stopTicking();
    _ticking = _Ticking(
      handle: time.schedule(
        delay: tick,
        action: _advance,
        repeat: Repeat.periodic,
      ),
    );
  }

  void _advance() {
    final moved = _loaded.at(position: position + tick);
    _item = moved;
    _events.add(EnginePosition(token: moved.token, position: moved.position));
    switch (reportedLength) {
      case KnownLength(:final duration) when moved.position >= duration:
        finish();
      case KnownLength() || UnknownLength():
        break;
    }
  }

  void _stopTicking() {
    switch (_ticking) {
      case _Ticking(:final handle):
        handle.cancel();
      case _NotTicking():
        break;
    }
    _ticking = const _NotTicking();
  }

  Future<void> dispose() => _events.close();
}

enum _Started { yes, no }

sealed class _MimicItem {
  const _MimicItem();
}

final class _Unloaded extends _MimicItem {
  const _Unloaded();
}

final class _Loaded extends _MimicItem {
  const _Loaded({
    required this.token,
    required this.position,
    required this.started,
  });

  final LoadToken token;
  final Duration position;
  final _Started started;

  _Loaded at({required Duration position}) =>
      _Loaded(token: token, position: position, started: started);

  _Loaded running() =>
      _Loaded(token: token, position: position, started: _Started.yes);
}

sealed class _TickState {
  const _TickState();
}

final class _Ticking extends _TickState {
  const _Ticking({required this.handle});

  final ScheduledHandle handle;
}

final class _NotTicking extends _TickState {
  const _NotTicking();
}
