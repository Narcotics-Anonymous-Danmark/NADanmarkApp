// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_store_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AscListDto _$AscListDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AscListDto', json, ($checkedConvert) {
      final val = AscListDto(
        data: $checkedConvert(
          'data',
          (v) => (v as List<dynamic>?)
              ?.map((e) => AscResourceDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

AscResourceDto _$AscResourceDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AscResourceDto', json, ($checkedConvert) {
      final val = AscResourceDto(
        id: $checkedConvert('id', (v) => const LenientText().fromJson(v)),
        attributes: $checkedConvert(
          'attributes',
          (v) => v == null
              ? null
              : AscAttributesDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

AscAttributesDto _$AscAttributesDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AscAttributesDto', json, ($checkedConvert) {
      final val = AscAttributesDto(
        processingState: $checkedConvert(
          'processingState',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AscRequestDtoToJson(AscRequestDto instance) =>
    <String, dynamic>{'data': instance.data.toJson()};

Map<String, dynamic> _$AscRequestDataDtoToJson(AscRequestDataDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': ?instance.id,
      'attributes': instance.attributes.toJson(),
      'relationships': ?instance.relationships?.toJson(),
    };

Map<String, dynamic> _$AscLocalizationAttributesDtoToJson(
  AscLocalizationAttributesDto instance,
) => <String, dynamic>{
  'whatsNew': instance.whatsNew,
  'locale': ?instance.locale,
};

Map<String, dynamic> _$AscRelationshipsDtoToJson(
  AscRelationshipsDto instance,
) => <String, dynamic>{'build': instance.build.toJson()};

Map<String, dynamic> _$AscRelationshipDtoToJson(AscRelationshipDto instance) =>
    <String, dynamic>{'data': instance.data.toJson()};

Map<String, dynamic> _$AscReferenceDtoToJson(AscReferenceDto instance) =>
    <String, dynamic>{'type': instance.type, 'id': instance.id};
