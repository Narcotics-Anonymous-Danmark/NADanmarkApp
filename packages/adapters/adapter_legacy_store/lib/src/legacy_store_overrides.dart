import 'package:adapter_legacy_store/src/method_channel_legacy_store.dart';
import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> legacyStoreOverrides({required Duration timeout}) => [
  legacyStorePortProvider.overrideWithValue(
    MethodChannelLegacyStore(
      channel: const MethodChannel(MethodChannelLegacyStore.channelName),
      timeout: timeout,
    ),
  ),
];
