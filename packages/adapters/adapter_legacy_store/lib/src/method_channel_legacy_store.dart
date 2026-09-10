import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';

final class MethodChannelLegacyStore implements LegacyStorePort {
  const MethodChannelLegacyStore({
    required this.channel,
    required this.timeout,
  });

  static const String channelName = 'dk.nadanmark.app/legacy_store';
  static const String readAllMethod = 'readAll';

  final MethodChannel channel;
  final Duration timeout;

  @override
  Future<LegacyStoreRead> readAll() async {
    try {
      final raw = await channel
          .invokeMethod<String>(readAllMethod)
          .timeout(timeout);
      return switch (raw) {
        null => const LegacyStoreAbsent(),
        final String json => decode(json: json),
      };
    } on MissingPluginException {
      return const LegacyStoreAbsent();
    } on PlatformException catch (error) {
      return LegacyStoreUnreadable(detail: '${error.code}: ${error.message}');
    } on TimeoutException {
      return LegacyStoreUnreadable(
        detail: 'no answer after ${timeout.inSeconds} s',
      );
    }
  }

  static LegacyStoreRead decode({required String json}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (error) {
      return LegacyStoreUnreadable(detail: 'dump: ${error.message}');
    }
    return switch (decoded) {
      final Map<String, Object?> map => LegacyStoreFound(
        entries: Map.unmodifiable({
          for (final entry in map.entries)
            if (entry.value case final Object value) entry.key: value,
        }),
      ),
      _ => const LegacyStoreUnreadable(detail: 'dump: not a JSON object'),
    };
  }
}
