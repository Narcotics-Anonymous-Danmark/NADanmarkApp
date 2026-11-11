import 'package:adapter_wordpress/src/dio_speaks_feed.dart';
import 'package:adapter_wordpress/src/wordpress_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> wordpressOverrides({
  required Dio dio,
  required WordPressEndpoints endpoints,
}) => [
  speaksFeedPortProvider.overrideWithValue(
    DioSpeaksFeed(dio: dio, endpoints: endpoints),
  ),
];
