import 'package:na_cli/src/host/env_value.dart';
import 'package:na_cli/src/http/http_call.dart';
import 'package:na_cli/src/http/http_reply.dart';
import 'package:na_cli/src/ports/clock.dart';
import 'package:na_cli/src/ports/console.dart';
import 'package:na_cli/src/ports/environment.dart';
import 'package:na_cli/src/ports/http_transport.dart';
import 'package:na_cli/src/ports/secret_generator.dart';
import 'package:na_cli/src/ports/sleeper.dart';

final class EnvironmentMimic implements Environment {
  const EnvironmentMimic({final Map<String, String> values = const {}})
    : _values = values;

  final Map<String, String> _values;

  @override
  EnvValue lookup({required final EnvKey key}) {
    final value = _values[key.value];
    return value == null || value.isEmpty
        ? EnvUnset(key: key)
        : EnvSet(value: value);
  }
}

final class ConsoleMimic implements Console {
  final List<String> outLines = [];
  final List<String> errLines = [];

  String get allOutput => [...outLines, ...errLines].join('\n');

  @override
  void out({required final String line}) => outLines.add(line);

  @override
  void err({required final String line}) => errLines.add(line);
}

final class FixedClock implements Clock {
  FixedClock({required this.current});

  DateTime current;

  @override
  DateTime now() => current;
}

final class SleeperMimic implements Sleeper {
  SleeperMimic({final void Function() onSleep = _noop}) : _onSleep = onSleep;

  final void Function() _onSleep;
  final List<Duration> sleeps = [];

  static void _noop() {}

  @override
  Future<void> sleep({required final Duration duration}) async {
    sleeps.add(duration);
    _onSleep();
  }
}

final class SecretGeneratorMimic implements SecretGenerator {
  const SecretGeneratorMimic();

  @override
  String randomToken({required final int bytes}) => 'f' * (bytes * 2);
}

final class HttpTransportMimic implements HttpTransport {
  HttpTransportMimic({final List<HttpReply> replies = const []})
    : _replies = [...replies];

  final List<HttpReply> _replies;
  final List<HttpCall> calls = [];

  @override
  Future<HttpReply> send({required final HttpCall call}) async {
    calls.add(call);
    return _replies.isEmpty
        ? const HttpReply(status: HttpStatus(200), body: '{}')
        : _replies.removeAt(0);
  }
}
