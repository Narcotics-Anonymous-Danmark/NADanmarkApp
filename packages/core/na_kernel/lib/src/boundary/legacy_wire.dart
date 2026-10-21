import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/bmlt_wire.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/results/outcome.dart';

part 'legacy_wire.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  explicitToJson: true,
  converters: [LenientText()],
)
@immutable
final class LegacyStoreDumpDto {
  const LegacyStoreDumpDto({
    this.language,
    this.firstday,
    this.searchRange,
    this.cleanTimeUnitSort,
    this.theme,
    this.meetingFormatsV1,
    this.cleanDateProfiles,
    this.activeProfile,
  });

  factory LegacyStoreDumpDto.fromJson(WireObject json) =>
      _$LegacyStoreDumpDtoFromJson(json);

  final String? language;
  final String? firstday;
  final String? searchRange;
  final String? cleanTimeUnitSort;
  final String? theme;
  @JsonKey(name: 'meeting_formats_v1', fromJson: _formatsCache)
  final FormatsCacheDto? meetingFormatsV1;
  @JsonKey(fromJson: _cleanDateProfiles)
  final List<LegacyCleanDateProfileDto>? cleanDateProfiles;
  final String? activeProfile;

  WireObject toJson() => _$LegacyStoreDumpDtoToJson(this);

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  @override
  int get hashCode => _equality.hash(toJson());

  @override
  bool operator ==(Object other) =>
      other is LegacyStoreDumpDto && _equality.equals(other.toJson(), toJson());

  @override
  String toString() => 'LegacyStoreDumpDto(${toJson().keys.join(', ')})';
}

FormatsCacheDto? _formatsCache(Object? json) => switch (json) {
  final WireObject map => FormatsCacheDto.fromJson(map),
  final String text => switch (const WireJson()
      .parse(text: text, context: 'meeting_formats_v1')
      .flatMap(
        transform: (decoded) => const WireJson().object(
          json: decoded,
          fromJson: FormatsCacheDto.fromJson,
          context: 'meeting_formats_v1',
        ),
      )) {
    Ok(:final value) => value,
    Err() => null,
  },
  Object() || null => null,
};

List<LegacyCleanDateProfileDto>? _cleanDateProfiles(Object? json) =>
    switch (json) {
      null => null,
      final List<Object?> items => List.unmodifiable(
        items.whereType<WireObject>().map(LegacyCleanDateProfileDto.fromJson),
      ),
      final String text => switch (const WireJson().parse(
        text: text,
        context: 'cleanDateProfiles',
      )) {
        Ok(:final List<Object?> value) => _cleanDateProfiles(value),
        Ok() || Err() => const [],
      },
      Object() => const [],
    };

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
@immutable
final class LegacyCleanDateProfileDto {
  const LegacyCleanDateProfileDto({this.name, this.cleandate});

  factory LegacyCleanDateProfileDto.fromJson(WireObject json) =>
      _$LegacyCleanDateProfileDtoFromJson(json);

  final String? name;
  final String? cleandate;

  WireObject toJson() => _$LegacyCleanDateProfileDtoToJson(this);

  @override
  int get hashCode => Object.hash(name, cleandate);

  @override
  bool operator ==(Object other) =>
      other is LegacyCleanDateProfileDto &&
      other.name == name &&
      other.cleandate == cleandate;
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText(), LenientInt()],
)
final class MigrationMarkerDto {
  const MigrationMarkerDto({
    this.version,
    this.completedAt,
    this.imported,
    this.skipped,
  });

  factory MigrationMarkerDto.fromJson(WireObject json) =>
      _$MigrationMarkerDtoFromJson(json);

  final String? version;
  final String? completedAt;
  final int? imported;
  final int? skipped;

  WireObject toJson() => _$MigrationMarkerDtoToJson(this);
}
