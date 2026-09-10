import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/weekday.dart';
import 'package:na_kernel/src/values/clean_time_unit_order.dart';
import 'package:na_kernel/src/values/km.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/settings.dart';
import 'package:na_kernel/src/values/storage_key.dart';

final class SettingsCodec {
  const SettingsCodec();

  Settings decode({required Map<StorageKey, String> stored}) => Settings(
    language: _field(
      stored: stored,
      key: SettingKeys.language,
      parse: (code) => Language.parse(code: code),
      fallback: Settings.defaults.language,
    ),
    firstDayOfWeek: _field(
      stored: stored,
      key: SettingKeys.firstDayOfWeek,
      parse: (code) => FirstDayOfWeek.parse(code: code),
      fallback: Settings.defaults.firstDayOfWeek,
    ),
    cleanTimeUnitOrder: _field(
      stored: stored,
      key: SettingKeys.cleanTimeUnitOrder,
      parse: (code) => CleanTimeUnitOrder.parse(code: code),
      fallback: Settings.defaults.cleanTimeUnitOrder,
    ),
    searchRadius: _field(
      stored: stored,
      key: SettingKeys.searchRadius,
      parse: (code) => Km.parseSearchRadius(text: code),
      fallback: Settings.defaults.searchRadius,
    ),
  );

  Map<StorageKey, String> encode({required Settings settings}) =>
      settings.stored;

  T _field<T>({
    required Map<StorageKey, String> stored,
    required StorageKey key,
    required Outcome<T, Object> Function(String code) parse,
    required T fallback,
  }) => switch (stored[key]) {
    final String code => parse(code).fold(
      onOk: (value) => value,
      onErr: (error) => fallback,
    ),
    null => fallback,
  };
}
