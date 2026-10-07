import 'package:json_annotation/json_annotation.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

part 'app_store_wire.g.dart';

@JsonSerializable(checked: true, createToJson: false)
final class AscListDto {
  const AscListDto({this.data});

  factory AscListDto.fromJson(final WireObject json) =>
      _$AscListDtoFromJson(json);

  final List<AscResourceDto>? data;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class AscResourceDto {
  const AscResourceDto({this.id, this.attributes});

  factory AscResourceDto.fromJson(final WireObject json) =>
      _$AscResourceDtoFromJson(json);

  final String? id;
  final AscAttributesDto? attributes;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class AscAttributesDto {
  const AscAttributesDto({this.processingState});

  factory AscAttributesDto.fromJson(final WireObject json) =>
      _$AscAttributesDtoFromJson(json);

  final String? processingState;
}

@JsonSerializable(createFactory: false, explicitToJson: true)
final class AscRequestDto {
  const AscRequestDto({required this.data});

  final AscRequestDataDto data;

  WireObject toJson() => _$AscRequestDtoToJson(this);
}

@JsonSerializable(
  createFactory: false,
  explicitToJson: true,
  includeIfNull: false,
)
final class AscRequestDataDto {
  const AscRequestDataDto({
    required this.type,
    required this.attributes,
    this.id,
    this.relationships,
  });

  final String type;
  final String? id;
  final AscLocalizationAttributesDto attributes;
  final AscRelationshipsDto? relationships;

  WireObject toJson() => _$AscRequestDataDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
final class AscLocalizationAttributesDto {
  const AscLocalizationAttributesDto({required this.whatsNew, this.locale});

  final String whatsNew;
  final String? locale;

  WireObject toJson() => _$AscLocalizationAttributesDtoToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
final class AscRelationshipsDto {
  const AscRelationshipsDto({required this.build});

  final AscRelationshipDto build;

  WireObject toJson() => _$AscRelationshipsDtoToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
final class AscRelationshipDto {
  const AscRelationshipDto({required this.data});

  final AscReferenceDto data;

  WireObject toJson() => _$AscRelationshipDtoToJson(this);
}

@JsonSerializable(createFactory: false)
final class AscReferenceDto {
  const AscReferenceDto({required this.type, required this.id});

  final String type;
  final String id;

  WireObject toJson() => _$AscReferenceDtoToJson(this);
}
