import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';

part 'bmlt_wire.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class BmltMeetingDto {
  const BmltMeetingDto({
    this.idBigint,
    this.meetingName,
    this.weekdayTinyint,
    this.startTime,
    this.durationTime,
    this.formats,
    this.formatSharedIdList,
    this.rootServerUri,
    this.rootServerId,
    this.virtualMeetingLink,
    this.phoneMeetingNumber,
    this.latitude,
    this.longitude,
    this.locationText,
    this.locationStreet,
    this.locationCitySubsection,
    this.locationNeighborhood,
    this.locationMunicipality,
    this.locationSubProvince,
    this.locationProvince,
    this.locationPostalCode1,
    this.locationInfo,
    this.comments,
    this.virtualMeetingAdditionalInfo,
    this.contactPhone1,
    this.contactEmail1,
    this.trainLines,
    this.busLines,
  });

  factory BmltMeetingDto.fromJson(WireObject json) =>
      _$BmltMeetingDtoFromJson(json);

  @JsonKey(name: 'id_bigint')
  final String? idBigint;
  @JsonKey(name: 'meeting_name')
  final String? meetingName;
  @JsonKey(name: 'weekday_tinyint')
  final String? weekdayTinyint;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'duration_time')
  final String? durationTime;
  final String? formats;
  @JsonKey(name: 'format_shared_id_list')
  final String? formatSharedIdList;
  @JsonKey(name: 'root_server_uri')
  final String? rootServerUri;
  @JsonKey(name: 'root_server_id')
  final String? rootServerId;
  @JsonKey(name: 'virtual_meeting_link')
  final String? virtualMeetingLink;
  @JsonKey(name: 'phone_meeting_number')
  final String? phoneMeetingNumber;
  final String? latitude;
  final String? longitude;
  @JsonKey(name: 'location_text')
  final String? locationText;
  @JsonKey(name: 'location_street')
  final String? locationStreet;
  @JsonKey(name: 'location_city_subsection')
  final String? locationCitySubsection;
  @JsonKey(name: 'location_neighborhood')
  final String? locationNeighborhood;
  @JsonKey(name: 'location_municipality')
  final String? locationMunicipality;
  @JsonKey(name: 'location_sub_province')
  final String? locationSubProvince;
  @JsonKey(name: 'location_province')
  final String? locationProvince;
  @JsonKey(name: 'location_postal_code_1')
  final String? locationPostalCode1;
  @JsonKey(name: 'location_info')
  final String? locationInfo;
  final String? comments;
  @JsonKey(name: 'virtual_meeting_additional_info')
  final String? virtualMeetingAdditionalInfo;
  @JsonKey(name: 'contact_phone_1')
  final String? contactPhone1;
  @JsonKey(name: 'contact_email_1')
  final String? contactEmail1;
  @JsonKey(name: 'train_lines')
  final String? trainLines;
  @JsonKey(name: 'bus_lines')
  final String? busLines;

  WireObject toJson() => _$BmltMeetingDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class BmltMunicipalityDto {
  const BmltMunicipalityDto({this.locationMunicipality});

  factory BmltMunicipalityDto.fromJson(WireObject json) =>
      _$BmltMunicipalityDtoFromJson(json);

  @JsonKey(name: 'location_municipality')
  final String? locationMunicipality;

  WireObject toJson() => _$BmltMunicipalityDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class BmltFormatDto {
  const BmltFormatDto({
    this.id,
    this.keyString,
    this.nameString,
    this.descriptionString,
    this.formatTypeEnum,
    this.lang,
  });

  factory BmltFormatDto.fromJson(WireObject json) =>
      _$BmltFormatDtoFromJson(json);

  final String? id;
  @JsonKey(name: 'key_string')
  final String? keyString;
  @JsonKey(name: 'name_string')
  final String? nameString;
  @JsonKey(name: 'description_string')
  final String? descriptionString;
  @JsonKey(name: 'format_type_enum')
  final String? formatTypeEnum;
  final String? lang;

  WireObject toJson() => _$BmltFormatDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  explicitToJson: true,
  converters: [LenientInt()],
)
final class FormatsCacheDto {
  const FormatsCacheDto({this.fetchedAt, this.formats});

  factory FormatsCacheDto.fromJson(WireObject json) =>
      _$FormatsCacheDtoFromJson(json);

  final int? fetchedAt;
  final List<BmltFormatDto>? formats;

  WireObject toJson() => _$FormatsCacheDtoToJson(this);
}
