import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:na_cli/src/boundary/option_value.dart';

final class ArgReader {
  const ArgReader._({required final ArgResults results}) : _results = results;

  factory ArgReader.of({required final Command<int> command}) {
    final results = command.argResults;
    if (results == null) {
      throw StateError('Command ${command.name} has not been parsed');
    }
    return ArgReader._(results: results);
  }

  final ArgResults _results;

  OptionValue option({required final String name}) {
    final value = _results[name];
    if (value is String && value.isNotEmpty) {
      return OptionGiven(value: value);
    }
    return const OptionOmitted();
  }

  FlagState flag({required final String name}) =>
      _results.flag(name) ? FlagState.on : FlagState.off;

  List<String> multi({required final String name}) =>
      _results.multiOption(name);

  List<String> get rest => _results.rest;

  List<String> get afterSeparator {
    final index = _results.arguments.indexOf('--');
    if (index < 0) {
      return const [];
    }
    return _results.arguments.sublist(index + 1);
  }

  List<String> get positionals {
    final rest = _results.rest;
    final passThrough = afterSeparator.length;
    return rest.sublist(0, rest.length - passThrough);
  }
}
