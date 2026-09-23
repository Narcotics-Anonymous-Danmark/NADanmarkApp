import 'dart:async';

import 'package:flutter/services.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
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

  static const WireJson _wire = WireJson();

  static LegacyStoreRead decode({required String json}) => switch (_wire
      .parse(text: json, context: 'dump')
      .flatMap(
        transform: (decoded) => _wire.object(
          json: decoded,
          fromJson: LegacyStoreDumpDto.fromJson,
          context: 'dump',
        ),
      )) {
    Ok(:final value) => LegacyStoreFound(dump: value),
    Err(:final error) => LegacyStoreUnreadable(detail: error.detail),
  };
}
