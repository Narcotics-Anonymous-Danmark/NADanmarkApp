import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/legacy_wire.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/weekday.dart';
import 'package:na_kernel/src/values/clean_time_unit_order.dart';
import 'package:na_kernel/src/values/km.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/settings.dart';
import 'package:na_kernel/src/values/storage_key.dart';

@immutable
final class LegacySettingsTranslation {
  const LegacySettingsTranslation({
    required this.settings,
    required this.importedKeys,
    required this.skippedKeys,
  });

  final Settings settings;
  final List<StorageKey> importedKeys;
  final List<StorageKey> skippedKeys;

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
    required List<StorageKey> left,
    required List<StorageKey> right,
  }) =>
      left.length == right.length &&
      left.indexed.every((entry) => right[entry.$1] == entry.$2);
}

final class LegacySettingsTranslator {
  const LegacySettingsTranslator();

  static const StorageKey legacyThemeKey = StorageKey('theme');

  LegacySettingsTranslation translate({required LegacyStoreDumpDto dump}) {
    final imported = <StorageKey>[];
    final skipped = <StorageKey>[];
    var settings = Settings.defaults;

    void consider<T>({
      required StorageKey key,
      required String? value,
      required Outcome<T, Object> Function(String value) decode,
      required Settings Function(T value) apply,
    }) {
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
      key: SettingKeys.language,
      value: dump.language,
      decode: (value) => Language.parse(code: value),
      apply: (value) => settings.withLanguage(language: value),
    );
    consider<FirstDayOfWeek>(
      key: SettingKeys.firstDayOfWeek,
      value: dump.firstday,
      decode: (value) => FirstDayOfWeek.parse(code: value),
      apply: (value) => settings.withFirstDayOfWeek(firstDayOfWeek: value),
    );
    consider<Km>(
      key: SettingKeys.searchRadius,
      value: dump.searchRange,
      decode: (value) => Km.parseSearchRadius(text: value),
      apply: (value) => settings.withSearchRadius(searchRadius: value),
    );
    consider<CleanTimeUnitOrder>(
      key: SettingKeys.cleanTimeUnitOrder,
      value: dump.cleanTimeUnitSort,
      decode: (value) => CleanTimeUnitOrder.parse(code: value),
      apply: (value) =>
          settings.withCleanTimeUnitOrder(cleanTimeUnitOrder: value),
    );
    if (dump.theme != null) {
      skipped.add(legacyThemeKey);
    }
    return LegacySettingsTranslation(
      settings: settings,
      importedKeys: List.unmodifiable(imported),
      skippedKeys: List.unmodifiable(skipped),
    );
  }
}
