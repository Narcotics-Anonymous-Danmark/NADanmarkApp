import 'package:na_kernel/na_kernel.dart';

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

  String nearby({required GeoPoint centre, required Km radius}) =>
      '${tomato.value}?switcher=GetSearchResults'
      '&geo_width_km=${radius.value}'
      '&long_val=${centre.longitude.value}'
      '&lat_val=${centre.latitude.value}'
      '&sort_keys=longitude,latitude'
      '&callingApp=bmlt_search_3_ionic';

  String get danishFormats =>
      '${denmark.value}?switcher=GetFormats&lang_enum=da';

  String get englishFormats =>
      '${denmark.value}?switcher=GetFormats&lang_enum=en';
}
