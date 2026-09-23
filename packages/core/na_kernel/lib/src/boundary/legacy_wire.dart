import 'package:json_annotation/json_annotation.dart';
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
final class LegacyStoreDumpDto {
  const LegacyStoreDumpDto({
    this.language,
    this.firstday,
    this.searchRange,
    this.cleanTimeUnitSort,
    this.theme,
    this.meetingFormatsV1,
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

  WireObject toJson() => _$LegacyStoreDumpDtoToJson(this);

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
  _ => null,
};

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
