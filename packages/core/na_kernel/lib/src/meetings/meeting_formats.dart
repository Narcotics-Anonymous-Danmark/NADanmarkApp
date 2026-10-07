import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/meetings/format_codes.dart';
import 'package:na_kernel/src/values/language.dart';

extension type const FormatName(String value) {}

extension type const FormatDescriptionText(String value) {}

extension type const FormatTypeCode(String value) {}

extension type const FormatLanguageCode(String value) {
  static const FormatLanguageCode danish = FormatLanguageCode('da');
  static const FormatLanguageCode english = FormatLanguageCode('en');

  static FormatLanguageCode displayFor({required Language language}) =>
      switch (language) {
        Language.danish => danish,
        Language.english => english,
      };
}

@immutable
final class FormatRow {
  const FormatRow({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.typeEnum,
    required this.language,
  });

  final FormatId id;
  final FormatKey key;
  final FormatName name;
  final FormatDescriptionText description;
  final FormatTypeCode typeEnum;
  final FormatLanguageCode language;

  @override
  int get hashCode =>
      Object.hash(id, key, name, description, typeEnum, language);

  @override
  bool operator ==(Object other) =>
      other is FormatRow &&
      other.id == id &&
      other.key == key &&
      other.name == name &&
      other.description == description &&
      other.typeEnum == typeEnum &&
      other.language == language;

  @override
  String toString() =>
      'FormatRow(${id.value}, ${key.value}, ${language.value})';
}

enum FormatCategory {
  alert,
  language,
  audience,
  facility,
  content
  ;

  static FormatCategory fromTypeEnum({required FormatTypeCode typeEnum}) {
    final type = typeEnum.value.trim().toUpperCase();
    if (type == 'ALERT') {
      return FormatCategory.alert;
    }
    if (type == 'LANG') {
      return FormatCategory.language;
    }
    if (['FC3', 'O', 'C'].any(type.startsWith)) {
      return FormatCategory.audience;
    }
    if (type.startsWith('FC2')) {
      return FormatCategory.facility;
    }
    return FormatCategory.content;
  }
}

@immutable
sealed class FormatDescription {
  const FormatDescription();
}

final class NoDescription extends FormatDescription {
  const NoDescription();

  @override
  int get hashCode => (NoDescription).hashCode;

  @override
  bool operator ==(Object other) => other is NoDescription;

  @override
  String toString() => 'NoDescription';
}

final class Described extends FormatDescription {
  const Described({required this.text});

  final FormatDescriptionText text;

  @override
  int get hashCode => Object.hash(Described, text);

  @override
  bool operator ==(Object other) => other is Described && other.text == text;

  @override
  String toString() => 'Described(${text.value})';
}

@immutable
final class MeetingFormat {
  const MeetingFormat({
    required this.key,
    required this.name,
    required this.description,
    required this.category,
  });

  factory MeetingFormat.unresolved({required FormatKey key}) => MeetingFormat(
    key: key,
    name: FormatName(key.value),
    description: const NoDescription(),
    category: FormatCategory.content,
  );

  factory MeetingFormat.fromRow({required FormatRow row}) => MeetingFormat(
    key: row.key,
    name: row.name.value.trim().isEmpty
        ? FormatName(row.key.value)
        : FormatName(row.name.value.trim()),
    description: row.description.value.trim().isEmpty
        ? const NoDescription()
        : Described(text: FormatDescriptionText(row.description.value.trim())),
    category: FormatCategory.fromTypeEnum(typeEnum: row.typeEnum),
  );

  final FormatKey key;
  final FormatName name;
  final FormatDescription description;
  final FormatCategory category;

  @override
  int get hashCode => Object.hash(key, name, description, category);

  @override
  bool operator ==(Object other) =>
      other is MeetingFormat &&
      other.key == key &&
      other.name == name &&
      other.description == description &&
      other.category == category;

  @override
  String toString() =>
      'MeetingFormat(${key.value}, ${name.value}, ${category.name})';
}

sealed class _LowerKeyEntry {
  const _LowerKeyEntry();
}

final class _UniqueLowerKey extends _LowerKeyEntry {
  const _UniqueLowerKey({required this.format});

  final MeetingFormat format;
}

final class _AmbiguousLowerKey extends _LowerKeyEntry {
  const _AmbiguousLowerKey();
}

final class FormatIndex {
  const FormatIndex._({
    required Map<FormatId, MeetingFormat> byId,
    required Map<String, MeetingFormat> byKey,
    required Map<String, _LowerKeyEntry> byLowerKey,
    required Map<String, MeetingFormat> byEnglishKey,
  }) : _byId = byId,
       _byKey = byKey,
       _byLowerKey = byLowerKey,
       _byEnglishKey = byEnglishKey;

  factory FormatIndex.build({
    required List<FormatRow> rows,
    required FormatLanguageCode display,
  }) {
    final byId = <FormatId, MeetingFormat>{};
    final byKey = <String, MeetingFormat>{};
    final byLowerKey = <String, _LowerKeyEntry>{};
    final byEnglishKey = <String, MeetingFormat>{};
    final groups = rows
        .where((row) => row.key.value.trim().isNotEmpty)
        .groupListsBy((row) => row.id);
    for (final group in groups.entries) {
      final chosen =
          group.value.firstWhereOrNull((row) => row.language == display) ??
          group.value.firstWhereOrNull(
            (row) => row.language == FormatLanguageCode.english,
          ) ??
          group.value.first;
      final format = MeetingFormat.fromRow(row: chosen);
      byId[group.key] = format;
      for (final row in group.value) {
        byKey.putIfAbsent(row.key.value, () => format);
        byLowerKey[row.key.folded] = switch (byLowerKey[row.key.folded]) {
          null => _UniqueLowerKey(format: format),
          _UniqueLowerKey(format: final existing) when existing == format =>
            _UniqueLowerKey(format: format),
          _UniqueLowerKey() ||
          _AmbiguousLowerKey() => const _AmbiguousLowerKey(),
        };
        if (row.language == FormatLanguageCode.english) {
          byEnglishKey.putIfAbsent(row.key.value, () => format);
        }
      }
    }
    return FormatIndex._(
      byId: Map.unmodifiable(byId),
      byKey: Map.unmodifiable(byKey),
      byLowerKey: Map.unmodifiable(byLowerKey),
      byEnglishKey: Map.unmodifiable(byEnglishKey),
    );
  }

  static const FormatIndex empty = FormatIndex._(
    byId: {},
    byKey: {},
    byLowerKey: {},
    byEnglishKey: {},
  );

  final Map<FormatId, MeetingFormat> _byId;
  final Map<String, MeetingFormat> _byKey;
  final Map<String, _LowerKeyEntry> _byLowerKey;
  final Map<String, MeetingFormat> _byEnglishKey;

  List<MeetingFormat> formatsOf({
    required MeetingFormatCodes codes,
    required MeetingOrigin origin,
  }) {
    final byPosition = switch (origin) {
      MeetingOrigin.denmark when codes.sharedIds.length == codes.keys.length =>
        codes.sharedIds,
      MeetingOrigin.denmark ||
      MeetingOrigin.denmarkAggregated ||
      MeetingOrigin.otherRoot => const <FormatId>[],
    };
    final resolved = codes.keys.indexed.map(
      (entry) => _resolve(
        key: entry.$2,
        sharedIds: byPosition.skip(entry.$1).take(1),
        origin: origin,
      ),
    );
    final unique = <String, MeetingFormat>{};
    for (final format in resolved) {
      unique.putIfAbsent(format.key.value, () => format);
    }
    return List.unmodifiable(
      unique.values.sortedBy<num>((format) => format.category.index),
    );
  }

  MeetingFormat _resolve({
    required FormatKey key,
    required Iterable<FormatId> sharedIds,
    required MeetingOrigin origin,
  }) {
    final candidates = switch (origin) {
      MeetingOrigin.denmark || MeetingOrigin.denmarkAggregated => [
        ...sharedIds.map((id) => _byId[id]).nonNulls,
        ...[_byKey[key.value]].nonNulls,
        ...switch (_byLowerKey[key.folded]) {
          _UniqueLowerKey(:final format) => [format],
          _AmbiguousLowerKey() || null => const <MeetingFormat>[],
        },
      ],
      MeetingOrigin.otherRoot => [_byEnglishKey[key.value]].nonNulls,
    };
    return candidates.firstOrNull ?? MeetingFormat.unresolved(key: key);
  }
}
