@Tags(['unit'])
library;

import 'package:na_ports/na_ports.dart';
import 'package:test/test.dart';

const RemoteSeek Function({required Duration position}) seek = RemoteSeek.new;

void main() {
  test('engine events carry their token', () {
    final token = LoadToken();
    final events = <EngineEvent>[
      EngineRunning(token: token),
      EngineLength(token: token, length: const Duration(seconds: 3)),
      EnginePosition(token: token, position: const Duration(seconds: 1)),
      EngineEnded(token: token),
      EngineFailed(token: token, detail: const EngineFailureDetail('404')),
    ];
    expect(events.every((event) => event.token == token), isTrue);
  });

  test('remote commands are distinct values', () {
    final builders = <RemoteCommand Function()>[
      RemotePlay.new,
      RemotePause.new,
      RemoteToggle.new,
      RemoteNext.new,
      RemotePrevious.new,
      RemoteSkipForward.new,
      RemoteSkipBackward.new,
      () => seek(position: const Duration(seconds: 9)),
      RemoteStop.new,
    ];
    final commands = builders.map((build) => build()).toList();
    expect(
      commands.map((command) => command.runtimeType).toSet(),
      hasLength(9),
    );
    expect(commands.whereType<RemoteSeek>().single.position.inSeconds, 9);
  });
}
