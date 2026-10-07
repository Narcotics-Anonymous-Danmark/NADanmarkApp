import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/src/generated/recorded_bmlt.dart';

const BmltMapper _mapper = BmltMapper();

BmltMeetingDto aBmltMeetingDto({
  int id = 115,
  String name = 'Traditionerne tro',
  int weekday = 1,
  String startTime = '11:00:00',
  String duration = '01:00:00',
  String formats = 'LUK,BFID,T,TR,LI,ID',
  String sharedIds = '4,14,27,30,36,54',
  String municipality = 'Varde',
  String locationText = 'Frivillighuset',
  String street = 'Storegade 25B',
  String postalCode = '6800 Varde',
  String comments = 'Dyr er ikke tilladt i lokalerne',
  String virtualLink = '',
  String phoneMeeting = '',
  String busLines = '',
  String trainLines = '',
  String latitude = '55.6201832',
  String longitude = '8.4830404',
  String rootServerUri = 'https://www.nadanmark.dk/main_server',
  String rootServerId = '',
}) => BmltMeetingDto(
  idBigint: '$id',
  meetingName: name,
  weekdayTinyint: '$weekday',
  startTime: startTime,
  durationTime: duration,
  formats: formats,
  formatSharedIdList: sharedIds,
  rootServerUri: rootServerUri,
  rootServerId: rootServerId,
  virtualMeetingLink: virtualLink,
  phoneMeetingNumber: phoneMeeting,
  latitude: latitude,
  longitude: longitude,
  locationText: locationText,
  locationStreet: street,
  locationMunicipality: municipality,
  locationPostalCode1: postalCode,
  comments: comments,
  trainLines: trainLines,
  busLines: busLines,
);

BmltMunicipalityDto aBmltMunicipalityDto({String municipality = 'Varde'}) =>
    BmltMunicipalityDto(locationMunicipality: municipality);

BmltFormatDto aBmltFormatDto({
  int id = 17,
  String key = 'ÅM',
  String name = 'Åben Møde',
  String description =
      'Dette er et åbent møde hvor ikke addict og ligende, alle er velkommen',
  String typeEnum = 'FC3',
  String language = 'da',
}) => BmltFormatDto(
  id: '$id',
  keyString: key,
  nameString: name,
  descriptionString: description,
  formatTypeEnum: typeEnum,
  lang: language,
);

List<BmltMeetingDto> recordedMeetingDtos() =>
    List.unmodifiable(recordedDenmarkMeetings.map(BmltMeetingDto.fromJson));

List<BmltMunicipalityDto> recordedMunicipalityDtos() => List.unmodifiable(
  recordedDenmarkMunicipalities.map(
    (name) => BmltMunicipalityDto(locationMunicipality: name),
  ),
);

List<BmltFormatDto> recordedDanishFormatDtos() =>
    List.unmodifiable(recordedFormatsDa.map(BmltFormatDto.fromJson));

List<BmltFormatDto> recordedEnglishFormatDtos() =>
    List.unmodifiable(recordedFormatsEn.map(BmltFormatDto.fromJson));

Meeting aMeeting({
  int id = 115,
  String name = 'Traditionerne tro',
  Weekday weekday = Weekday.sunday,
  String startTime = '11:00:00',
  String duration = '01:00:00',
  String formats = 'LUK,BFID,T,TR,LI,ID',
  String sharedIds = '4,14,27,30,36,54',
  String municipality = 'Varde',
  String virtualLink = '',
  String phoneMeeting = '',
  String busLines = '',
  String trainLines = '',
  String latitude = '55.6201832',
  String longitude = '8.4830404',
  String rootServerUri = 'https://www.nadanmark.dk/main_server',
}) => switch (_mapper.meeting(
  dto: aBmltMeetingDto(
    id: id,
    name: name,
    weekday: weekday.bmltTinyint,
    startTime: startTime,
    duration: duration,
    formats: formats,
    sharedIds: sharedIds,
    municipality: municipality,
    virtualLink: virtualLink,
    phoneMeeting: phoneMeeting,
    busLines: busLines,
    trainLines: trainLines,
    latitude: latitude,
    longitude: longitude,
    rootServerUri: rootServerUri,
  ),
)) {
  Ok(:final value) => value,
  Err(:final error) => throw ArgumentError('aMeeting: $error'),
};

FormatRow aMeetingFormatRow({
  int id = 17,
  String key = 'ÅM',
  String name = 'Åben Møde',
  String description =
      'Dette er et åbent møde hvor ikke addict og ligende, alle er velkommen',
  String typeEnum = 'FC3',
  String language = 'da',
}) => formatRowsFrom(
  dtos: [
    aBmltFormatDto(
      id: id,
      key: key,
      name: name,
      description: description,
      typeEnum: typeEnum,
      language: language,
    ),
  ],
).single;

List<FormatRow> formatRowsFrom({required List<BmltFormatDto> dtos}) =>
    _mapper.formatRowsOf(dtos: dtos);

List<FormatRow> recordedFormatRows() => formatRowsFrom(
  dtos: [...recordedDanishFormatDtos(), ...recordedEnglishFormatDtos()],
);
