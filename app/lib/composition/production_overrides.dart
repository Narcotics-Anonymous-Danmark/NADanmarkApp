import 'package:adapter_clock/adapter_clock.dart';
import 'package:adapter_jft/adapter_jft.dart';
import 'package:adapter_legacy_store/adapter_legacy_store.dart';
import 'package:adapter_links/adapter_links.dart';
import 'package:adapter_storage/adapter_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:na_app/composition/app_info_loader.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<Override>> productionOverrides() async => [
  ...clockOverrides(zone: TimeZoneId.copenhagen),
  ...storageOverrides(preferences: SharedPreferencesAsync()),
  ...jftOverrides(bundle: rootBundle),
  ...linksOverrides(),
  ...legacyStoreOverrides(timeout: const Duration(seconds: 5)),
  eventBusProvider.overrideWithValue(BroadcastEventBus()),
  appInfoProvider.overrideWithValue(await loadAppInfo()),
];
