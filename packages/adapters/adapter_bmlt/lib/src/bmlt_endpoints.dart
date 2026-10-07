extension type const BmltBaseUrl(String value) {}

final class BmltEndpoints {
  const BmltEndpoints({required this.denmark, required this.tomato});

  final BmltBaseUrl denmark;
  final BmltBaseUrl tomato;

  String get allDenmarkMeetings =>
      '${denmark.value}?switcher=GetSearchResults'
      '&sort_keys=weekday_tinyint,start_time';

  String get denmarkMunicipalities =>
      '${denmark.value}?switcher=GetSearchResults'
      '&data_field_key=location_municipality'
      '&sort_keys=location_municipality';

  String get danishFormats =>
      '${denmark.value}?switcher=GetFormats&lang_enum=da';

  String get englishFormats =>
      '${denmark.value}?switcher=GetFormats&lang_enum=en';
}
