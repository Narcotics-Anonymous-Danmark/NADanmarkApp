import 'package:adapter_assets/adapter_assets.dart';
import 'package:adapter_audio/adapter_audio.dart';
import 'package:adapter_bmlt/adapter_bmlt.dart';
import 'package:adapter_clock/adapter_clock.dart';
import 'package:adapter_geolocation/adapter_geolocation.dart';
import 'package:adapter_jft/adapter_jft.dart';
import 'package:adapter_legacy_store/adapter_legacy_store.dart';
import 'package:adapter_links/adapter_links.dart';
import 'package:adapter_notifications/adapter_notifications.dart';
import 'package:adapter_storage/adapter_storage.dart';
import 'package:adapter_wordpress/adapter_wordpress.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:na_app/composition/app_config.dart';
import 'package:na_app/composition/app_info_loader.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dio bmltDio() => networkDio();

Dio wordpressDio() => networkDio();

Dio networkDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

Future<List<Override>> productionOverrides() async => [
  ...await platformOverrides(),
  ...networkOverrides(bmlt: bmltDio(), wordpress: wordpressDio()),
];

Future<List<Override>> platformOverrides() async => [
  ...clockOverrides(zone: TimeZoneId.copenhagen),
  ...storageOverrides(preferences: SharedPreferencesAsync()),
  ...jftOverrides(bundle: rootBundle),
  ...assetsOverrides(bundle: rootBundle),
  ...await startAudio(bundle: rootBundle),
  ...linksOverrides(),
  ...geolocationOverrides(platform: GeolocatorPlatform.instance),
  ...notificationsOverrides(
    platform: FlutterLocalNotificationsPlatform.instance,
  ),
  ...legacyStoreOverrides(timeout: const Duration(seconds: 5)),
  eventBusProvider.overrideWithValue(BroadcastEventBus()),
  appInfoProvider.overrideWithValue(await loadAppInfo()),
];

List<Override> networkOverrides({required Dio bmlt, required Dio wordpress}) {
  final config = AppConfig.fromEnvironment();
  return [
    ...bmltOverrides(dio: bmlt, endpoints: config.bmlt),
    ...wordpressOverrides(dio: wordpress, endpoints: config.wordpress),
  ];
}
