// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountDto _$ServiceAccountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ServiceAccountDto',
      json,
      ($checkedConvert) {
        final val = ServiceAccountDto(
          clientEmail: $checkedConvert(
            'client_email',
            (v) => const LenientText().fromJson(v),
          ),
          privateKey: $checkedConvert(
            'private_key',
            (v) => const LenientText().fromJson(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientEmail': 'client_email',
        'privateKey': 'private_key',
      },
    );

GoogleTokenDto _$GoogleTokenDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GoogleTokenDto', json, ($checkedConvert) {
      final val = GoogleTokenDto(
        accessToken: $checkedConvert(
          'access_token',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'accessToken': 'access_token'});

PlayEditDto _$PlayEditDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlayEditDto', json, ($checkedConvert) {
      final val = PlayEditDto(
        id: $checkedConvert('id', (v) => const LenientText().fromJson(v)),
      );
      return val;
    });

Map<String, dynamic> _$PlayTrackDtoToJson(PlayTrackDto instance) =>
    <String, dynamic>{
      'releases': instance.releases.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$PlayReleaseDtoToJson(PlayReleaseDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'versionCodes': instance.versionCodes,
      'status': instance.status,
      'releaseNotes': ?instance.releaseNotes?.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$PlayReleaseNoteDtoToJson(PlayReleaseNoteDto instance) =>
    <String, dynamic>{'language': instance.language, 'text': instance.text};
