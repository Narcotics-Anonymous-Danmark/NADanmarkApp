import 'package:meta/meta.dart';
import 'package:na_kernel/src/time/weekday.dart';
import 'package:na_kernel/src/values/clean_time_unit_order.dart';
import 'package:na_kernel/src/values/km.dart';
import 'package:na_kernel/src/values/language.dart';
import 'package:na_kernel/src/values/storage_key.dart';

@immutable
final class Settings {
  const Settings({
    required this.language,
    required this.firstDayOfWeek,
    required this.cleanTimeUnitOrder,
    required this.searchRadius,
  });

  static const Settings defaults = Settings(
    language: Language.fallback,
    firstDayOfWeek: FirstDayOfWeek.fallback,
    cleanTimeUnitOrder: CleanTimeUnitOrder.fallback,
    searchRadius: Km.searchRadiusFallback,
  );

  final Language language;
  final FirstDayOfWeek firstDayOfWeek;
  final CleanTimeUnitOrder cleanTimeUnitOrder;
  final Km searchRadius;

  Settings withLanguage({required Language language}) => Settings(
    language: language,
    firstDayOfWeek: firstDayOfWeek,
    cleanTimeUnitOrder: cleanTimeUnitOrder,
    searchRadius: searchRadius,
  );

  Settings withFirstDayOfWeek({required FirstDayOfWeek firstDayOfWeek}) =>
      Settings(
        language: language,
        firstDayOfWeek: firstDayOfWeek,
        cleanTimeUnitOrder: cleanTimeUnitOrder,
        searchRadius: searchRadius,
      );

  Settings withCleanTimeUnitOrder({
    required CleanTimeUnitOrder cleanTimeUnitOrder,
  }) => Settings(
    language: language,
    firstDayOfWeek: firstDayOfWeek,
    cleanTimeUnitOrder: cleanTimeUnitOrder,
    searchRadius: searchRadius,
  );

  Settings withSearchRadius({required Km searchRadius}) => Settings(
    language: language,
    firstDayOfWeek: firstDayOfWeek,
    cleanTimeUnitOrder: cleanTimeUnitOrder,
    searchRadius: Km.clampedSearchRadius(value: searchRadius.value),
  );

  Map<StorageKey, String> get stored => Map.unmodifiable({
    SettingKeys.language: language.code,
    SettingKeys.firstDayOfWeek: firstDayOfWeek.code,
    SettingKeys.cleanTimeUnitOrder: cleanTimeUnitOrder.code,
    SettingKeys.searchRadius: searchRadius.code,
  });

  @override
  int get hashCode =>
      Object.hash(language, firstDayOfWeek, cleanTimeUnitOrder, searchRadius);

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.language == language &&
      other.firstDayOfWeek == firstDayOfWeek &&
      other.cleanTimeUnitOrder == cleanTimeUnitOrder &&
      other.searchRadius == searchRadius;

  @override
  String toString() =>
      'Settings(${language.code}, ${firstDayOfWeek.code}, '
      '${cleanTimeUnitOrder.code}, ${searchRadius.value} km)';
}

abstract final class SettingKeys {
  static const StorageKey language = StorageKey('language');
  static const StorageKey firstDayOfWeek = StorageKey('firstday');
  static const StorageKey cleanTimeUnitOrder = StorageKey('cleanTimeUnitSort');
  static const StorageKey searchRadius = StorageKey('searchRange');
  static const StorageKey legacyMigrationCompleted = StorageKey(
    'legacyMigration.completed',
  );

  static const List<StorageKey> all = [
    language,
    firstDayOfWeek,
    cleanTimeUnitOrder,
    searchRadius,
  ];
}
