import 'package:adapter_bmlt/src/bmlt_endpoints.dart';
import 'package:adapter_bmlt/src/dio_meeting_formats.dart';
import 'package:adapter_bmlt/src/dio_meeting_search.dart';
import 'package:dio/dio.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> bmltOverrides({
  required Dio dio,
  required BmltEndpoints endpoints,
}) => [
  meetingSearchPortProvider.overrideWithValue(
    DioMeetingSearch(dio: dio, endpoints: endpoints),
  ),
  meetingFormatsPortProvider.overrideWithValue(
    DioMeetingFormats(dio: dio, endpoints: endpoints),
  ),
];
