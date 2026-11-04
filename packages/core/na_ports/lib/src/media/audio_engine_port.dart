import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/src/unbound_port.dart';
import 'package:riverpod/riverpod.dart';

final class LoadToken {
  LoadToken();

  @override
  String toString() => 'LoadToken#${identityHashCode(this)}';
}

extension type const EngineFailureDetail(String text) {}

@immutable
final class EngineItem {
  const EngineItem({required this.url, required this.title});

  final AudioUrl url;
  final TrackTitle title;

  @override
  int get hashCode => Object.hash(url, title);

  @override
  bool operator ==(Object other) =>
      other is EngineItem && other.url == url && other.title == title;

  @override
  String toString() => 'EngineItem(${url.uri})';
}

@immutable
sealed class EngineEvent {
  const EngineEvent({required this.token});

  final LoadToken token;
}

final class EngineRunning extends EngineEvent {
  const EngineRunning({required super.token});
}

final class EngineLength extends EngineEvent {
  const EngineLength({required super.token, required this.length});

  final Duration length;
}

final class EnginePosition extends EngineEvent {
  const EnginePosition({required super.token, required this.position});

  final Duration position;
}

final class EngineEnded extends EngineEvent {
  const EngineEnded({required super.token});
}

final class EngineFailed extends EngineEvent {
  const EngineFailed({required super.token, required this.detail});

  final EngineFailureDetail detail;
}

abstract interface class AudioEnginePort {
  Stream<EngineEvent> get events;

  Future<LoadToken> load({required EngineItem item, required Duration startAt});

  Future<void> play();

  Future<void> pause();

  Future<void> seek({required Duration position});

  Future<void> release();
}

final Provider<AudioEnginePort> audioEnginePortProvider = unboundPort(
  portName: 'AudioEnginePort',
);
