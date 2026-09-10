import 'package:meta/meta.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/weekday.dart';
import 'package:na_kernel/src/values/clean_time_unit_order.dart';
import 'package:na_kernel/src/values/km.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/settings.dart';

typedef LegacyStoreEntries = Map<String, Object?>;

@immutable
final class LegacySettingsTranslation {
  const LegacySettingsTranslation({
    required this.settings,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final Settings settings;
  final List<String> importedKeys;
  final List<String> skippedKeys;

  @override
  int get hashCode => Object.hash(
    settings,
    Object.hashAll(importedKeys),
    Object.hashAll(skippedKeys),
  );

  @override
  bool operator ==(Object other) =>
      other is LegacySettingsTranslation &&
      other.settings == settings &&
      _sameList(left: other.importedKeys, right: importedKeys) &&
      _sameList(left: other.skippedKeys, right: skippedKeys);

  static bool _sameList({
    required List<String> left,
    required List<String> right,
  }) =>
      left.length == right.length &&
      left.indexed.every((entry) => right[entry.$1] == entry.$2);
}

final class LegacySettingsTranslator {
  const LegacySettingsTranslator();

  static const List<String> knownKeys = [
    'language',
    'firstday',
    'searchRange',
    'cleanTimeUnitSort',
    'theme',
  ];

  LegacySettingsTranslation translate({required LegacyStoreEntries entries}) {
    final imported = <String>[];
    final skipped = <String>[];
    var settings = Settings.defaults;

    void consider<T>({
      required String key,
      required Outcome<T, Object> Function(Object value) decode,
      required Settings Function(T value) apply,
    }) {
      final value = entries[key];
      if (value == null) {
        return;
      }
      switch (decode(value)) {
        case Ok(:final value):
          settings = apply(value);
          imported.add(key);
        case Err():
          skipped.add(key);
      }
    }

    consider<Language>(
      key: 'language',
      decode: (value) => Language.parse(code: value.toString()),
      apply: (value) => settings.withLanguage(language: value),
    );
    consider<FirstDayOfWeek>(
      key: 'firstday',
      decode: (value) => FirstDayOfWeek.parse(code: value.toString()),
      apply: (value) => settings.withFirstDayOfWeek(firstDayOfWeek: value),
    );
    consider<Km>(
      key: 'searchRange',
      decode: (value) => Km.parseSearchRadius(text: _integral(value)),
      apply: (value) => settings.withSearchRadius(searchRadius: value),
    );
    consider<CleanTimeUnitOrder>(
      key: 'cleanTimeUnitSort',
      decode: (value) => CleanTimeUnitOrder.parse(code: value.toString()),
      apply: (value) =>
          settings.withCleanTimeUnitOrder(cleanTimeUnitOrder: value),
    );
    if (entries.containsKey('theme')) {
      skipped.add('theme');
    }
    return LegacySettingsTranslation(
      settings: settings,
      importedKeys: List.unmodifiable(imported),
      skippedKeys: List.unmodifiable(skipped),
    );
  }

  String _integral(Object value) => switch (value) {
    final int number => number.toString(),
    final double number when number == number.roundToDouble() =>
      number.toInt().toString(),
    final Object other => other.toString(),
  };
}
