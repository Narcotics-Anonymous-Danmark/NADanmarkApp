// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmlt_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmltMeetingDto _$BmltMeetingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BmltMeetingDto',
      json,
      ($checkedConvert) {
        final val = BmltMeetingDto(
          idBigint: $checkedConvert(
            'id_bigint',
            (v) => const LenientText().fromJson(v),
          ),
          meetingName: $checkedConvert(
            'meeting_name',
            (v) => const LenientText().fromJson(v),
          ),
          weekdayTinyint: $checkedConvert(
            'weekday_tinyint',
            (v) => const LenientText().fromJson(v),
          ),
          startTime: $checkedConvert(
            'start_time',
            (v) => const LenientText().fromJson(v),
          ),
          durationTime: $checkedConvert(
            'duration_time',
            (v) => const LenientText().fromJson(v),
          ),
          formats: $checkedConvert(
            'formats',
            (v) => const LenientText().fromJson(v),
          ),
          formatSharedIdList: $checkedConvert(
            'format_shared_id_list',
            (v) => const LenientText().fromJson(v),
          ),
          rootServerUri: $checkedConvert(
            'root_server_uri',
            (v) => const LenientText().fromJson(v),
          ),
          rootServerId: $checkedConvert(
            'root_server_id',
            (v) => const LenientText().fromJson(v),
          ),
          virtualMeetingLink: $checkedConvert(
            'virtual_meeting_link',
            (v) => const LenientText().fromJson(v),
          ),
          phoneMeetingNumber: $checkedConvert(
            'phone_meeting_number',
            (v) => const LenientText().fromJson(v),
          ),
          latitude: $checkedConvert(
            'latitude',
            (v) => const LenientText().fromJson(v),
          ),
          longitude: $checkedConvert(
            'longitude',
            (v) => const LenientText().fromJson(v),
          ),
          locationText: $checkedConvert(
            'location_text',
            (v) => const LenientText().fromJson(v),
          ),
          locationStreet: $checkedConvert(
            'location_street',
            (v) => const LenientText().fromJson(v),
          ),
          locationCitySubsection: $checkedConvert(
            'location_city_subsection',
            (v) => const LenientText().fromJson(v),
          ),
          locationNeighborhood: $checkedConvert(
            'location_neighborhood',
            (v) => const LenientText().fromJson(v),
          ),
          locationMunicipality: $checkedConvert(
            'location_municipality',
            (v) => const LenientText().fromJson(v),
          ),
          locationSubProvince: $checkedConvert(
            'location_sub_province',
            (v) => const LenientText().fromJson(v),
          ),
          locationProvince: $checkedConvert(
            'location_province',
            (v) => const LenientText().fromJson(v),
          ),
          locationPostalCode1: $checkedConvert(
            'location_postal_code_1',
            (v) => const LenientText().fromJson(v),
          ),
          locationInfo: $checkedConvert(
            'location_info',
            (v) => const LenientText().fromJson(v),
          ),
          comments: $checkedConvert(
            'comments',
            (v) => const LenientText().fromJson(v),
          ),
          virtualMeetingAdditionalInfo: $checkedConvert(
            'virtual_meeting_additional_info',
            (v) => const LenientText().fromJson(v),
          ),
          contactPhone1: $checkedConvert(
            'contact_phone_1',
            (v) => const LenientText().fromJson(v),
          ),
          contactEmail1: $checkedConvert(
            'contact_email_1',
            (v) => const LenientText().fromJson(v),
          ),
          trainLines: $checkedConvert(
            'train_lines',
            (v) => const LenientText().fromJson(v),
          ),
          busLines: $checkedConvert(
            'bus_lines',
            (v) => const LenientText().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'idBigint': 'id_bigint',
        'meetingName': 'meeting_name',
        'weekdayTinyint': 'weekday_tinyint',
        'startTime': 'start_time',
        'durationTime': 'duration_time',
        'formatSharedIdList': 'format_shared_id_list',
        'rootServerUri': 'root_server_uri',
        'rootServerId': 'root_server_id',
        'virtualMeetingLink': 'virtual_meeting_link',
        'phoneMeetingNumber': 'phone_meeting_number',
        'locationText': 'location_text',
        'locationStreet': 'location_street',
        'locationCitySubsection': 'location_city_subsection',
        'locationNeighborhood': 'location_neighborhood',
        'locationMunicipality': 'location_municipality',
        'locationSubProvince': 'location_sub_province',
        'locationProvince': 'location_province',
        'locationPostalCode1': 'location_postal_code_1',
        'locationInfo': 'location_info',
        'virtualMeetingAdditionalInfo': 'virtual_meeting_additional_info',
        'contactPhone1': 'contact_phone_1',
        'contactEmail1': 'contact_email_1',
        'trainLines': 'train_lines',
        'busLines': 'bus_lines',
      },
    );

Map<String, dynamic> _$BmltMeetingDtoToJson(
  BmltMeetingDto instance,
) => <String, dynamic>{
  'id_bigint': ?const LenientText().toJson(instance.idBigint),
  'meeting_name': ?const LenientText().toJson(instance.meetingName),
  'weekday_tinyint': ?const LenientText().toJson(instance.weekdayTinyint),
  'start_time': ?const LenientText().toJson(instance.startTime),
  'duration_time': ?const LenientText().toJson(instance.durationTime),
  'formats': ?const LenientText().toJson(instance.formats),
  'format_shared_id_list': ?const LenientText().toJson(
    instance.formatSharedIdList,
  ),
  'root_server_uri': ?const LenientText().toJson(instance.rootServerUri),
  'root_server_id': ?const LenientText().toJson(instance.rootServerId),
  'virtual_meeting_link': ?const LenientText().toJson(
    instance.virtualMeetingLink,
  ),
  'phone_meeting_number': ?const LenientText().toJson(
    instance.phoneMeetingNumber,
  ),
  'latitude': ?const LenientText().toJson(instance.latitude),
  'longitude': ?const LenientText().toJson(instance.longitude),
  'location_text': ?const LenientText().toJson(instance.locationText),
  'location_street': ?const LenientText().toJson(instance.locationStreet),
  'location_city_subsection': ?const LenientText().toJson(
    instance.locationCitySubsection,
  ),
  'location_neighborhood': ?const LenientText().toJson(
    instance.locationNeighborhood,
  ),
  'location_municipality': ?const LenientText().toJson(
    instance.locationMunicipality,
  ),
  'location_sub_province': ?const LenientText().toJson(
    instance.locationSubProvince,
  ),
  'location_province': ?const LenientText().toJson(instance.locationProvince),
  'location_postal_code_1': ?const LenientText().toJson(
    instance.locationPostalCode1,
  ),
  'location_info': ?const LenientText().toJson(instance.locationInfo),
  'comments': ?const LenientText().toJson(instance.comments),
  'virtual_meeting_additional_info': ?const LenientText().toJson(
    instance.virtualMeetingAdditionalInfo,
  ),
  'contact_phone_1': ?const LenientText().toJson(instance.contactPhone1),
  'contact_email_1': ?const LenientText().toJson(instance.contactEmail1),
  'train_lines': ?const LenientText().toJson(instance.trainLines),
  'bus_lines': ?const LenientText().toJson(instance.busLines),
};

BmltMunicipalityDto _$BmltMunicipalityDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BmltMunicipalityDto',
      json,
      ($checkedConvert) {
        final val = BmltMunicipalityDto(
          locationMunicipality: $checkedConvert(
            'location_municipality',
            (v) => const LenientText().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'locationMunicipality': 'location_municipality'},
    );

Map<String, dynamic> _$BmltMunicipalityDtoToJson(
  BmltMunicipalityDto instance,
) => <String, dynamic>{
  'location_municipality': ?const LenientText().toJson(
    instance.locationMunicipality,
  ),
};

BmltFormatDto _$BmltFormatDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BmltFormatDto',
      json,
      ($checkedConvert) {
        final val = BmltFormatDto(
          id: $checkedConvert('id', (v) => const LenientText().fromJson(v)),
          keyString: $checkedConvert(
            'key_string',
            (v) => const LenientText().fromJson(v),
          ),
          nameString: $checkedConvert(
            'name_string',
            (v) => const LenientText().fromJson(v),
          ),
          descriptionString: $checkedConvert(
            'description_string',
            (v) => const LenientText().fromJson(v),
          ),
          formatTypeEnum: $checkedConvert(
            'format_type_enum',
            (v) => const LenientText().fromJson(v),
          ),
          lang: $checkedConvert('lang', (v) => const LenientText().fromJson(v)),
        );
        return val;
      },
      fieldKeyMap: const {
        'keyString': 'key_string',
        'nameString': 'name_string',
        'descriptionString': 'description_string',
        'formatTypeEnum': 'format_type_enum',
      },
    );

Map<String, dynamic> _$BmltFormatDtoToJson(
  BmltFormatDto instance,
) => <String, dynamic>{
  'id': ?const LenientText().toJson(instance.id),
  'key_string': ?const LenientText().toJson(instance.keyString),
  'name_string': ?const LenientText().toJson(instance.nameString),
  'description_string': ?const LenientText().toJson(instance.descriptionString),
  'format_type_enum': ?const LenientText().toJson(instance.formatTypeEnum),
  'lang': ?const LenientText().toJson(instance.lang),
};

FormatsCacheDto _$FormatsCacheDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FormatsCacheDto', json, ($checkedConvert) {
      final val = FormatsCacheDto(
        fetchedAt: $checkedConvert(
          'fetchedAt',
          (v) => const LenientInt().fromJson(v),
        ),
        formats: $checkedConvert(
          'formats',
          (v) => (v as List<dynamic>?)
              ?.map((e) => BmltFormatDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FormatsCacheDtoToJson(FormatsCacheDto instance) =>
    <String, dynamic>{
      'fetchedAt': ?const LenientInt().toJson(instance.fetchedAt),
      'formats': ?instance.formats?.map((e) => e.toJson()).toList(),
    };
