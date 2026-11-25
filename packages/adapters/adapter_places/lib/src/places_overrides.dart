import 'package:adapter_places/src/dio_places.dart';
import 'package:adapter_places/src/places_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> placesOverrides({
  required Dio dio,
  required PlacesEndpoints endpoints,
}) => [
  placesPortProvider.overrideWithValue(
    DioPlaces(dio: dio, endpoints: endpoints),
  ),
];
