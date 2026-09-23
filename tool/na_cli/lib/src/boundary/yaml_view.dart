import 'package:na_cli/src/boundary/field_text.dart';
import 'package:yaml/yaml.dart';

sealed class YamlParse {
  const YamlParse();
}

final class YamlParsed extends YamlParse {
  const YamlParsed({required this.view});

  final YamlView view;
}

final class YamlMalformed extends YamlParse {
  const YamlMalformed({required this.reason});

  final String reason;
}

final class YamlView {
  const YamlView({required final Map<Object?, Object?> fields})
    : _fields = fields;

  const YamlView.empty() : _fields = const {};

  final Map<Object?, Object?> _fields;

  static YamlParse parse({required final String text}) {
    try {
      final loaded = loadYaml(text);
      if (loaded is YamlMap) {
        return YamlParsed(view: YamlView(fields: loaded));
      }
      if (loaded == null) {
        return const YamlParsed(view: YamlView.empty());
      }
      return const YamlMalformed(reason: 'expected a YAML mapping');
    } on YamlException catch (error) {
      return YamlMalformed(reason: error.message);
    }
  }

  List<String> get keys =>
      _fields.keys.map((final key) => key.toString()).toList(growable: false);

  FieldText text({required final String key}) {
    final value = _fields[key];
    if (value is String || value is num) {
      return FieldPresent(value: value.toString());
    }
    return FieldAbsent(key: key);
  }

  YamlView section({required final String key}) {
    final value = _fields[key];
    if (value is YamlMap) {
      return YamlView(fields: value);
    }
    return const YamlView.empty();
  }

  Map<String, String> dependencySpecs({required final String key}) {
    final section = _fields[key];
    if (section is! YamlMap) {
      return const {};
    }
    return Map.unmodifiable({
      for (final entry in section.entries)
        entry.key.toString(): switch (entry.value) {
          final YamlMap source when source.containsKey('path') => 'path:',
          final YamlMap source when source.containsKey('sdk') => 'sdk:',
          final YamlMap source => 'source:${source.keys.join(',')}',
          null => '',
          final Object value => value.toString(),
        },
    });
  }

  List<String> stringList({required final String key}) {
    final value = _fields[key];
    if (value is YamlList) {
      return value.map((final item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  Map<String, double> numberEntries({required final String key}) {
    final section = _fields[key];
    if (section is! YamlMap) {
      return const {};
    }
    return Map.unmodifiable({
      for (final entry in section.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).toDouble(),
    });
  }
}
