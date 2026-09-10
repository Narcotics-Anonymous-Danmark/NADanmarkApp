@Tags(['unit'])
library;

import 'dart:async';

import 'package:adapter_legacy_store/adapter_legacy_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MethodChannelLegacyStore.channelName);
  const store = MethodChannelLegacyStore(
    channel: channel,
    timeout: Duration(milliseconds: 200),
  );

  void answer(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a JSON dump becomes the found entries without nulls', () async {
    answer((call) async {
      expect(call.method, 'readAll');
      return '{"language":"en","searchRange":30,"theme":null}';
    });
    expect(
      await store.readAll(),
      const LegacyStoreFound(entries: {'language': 'en', 'searchRange': 30}),
    );
  });

  test('null means no database', () async {
    answer((call) async => null);
    expect(await store.readAll(), const LegacyStoreAbsent());
  });

  test('a missing plugin also means no database', () async {
    expect(await store.readAll(), const LegacyStoreAbsent());
  });

  test('platform errors, timeouts and bad JSON are unreadable', () async {
    answer(
      (call) async =>
          throw PlatformException(code: 'legacy_store', message: 'corrupt'),
    );
    expect(
      await store.readAll(),
      const LegacyStoreUnreadable(detail: 'legacy_store: corrupt'),
    );
    answer((call) => Completer<Object?>().future);
    expect(await store.readAll(), isA<LegacyStoreUnreadable>());
    expect(
      MethodChannelLegacyStore.decode(json: 'nope'),
      isA<LegacyStoreUnreadable>(),
    );
    expect(
      MethodChannelLegacyStore.decode(json: '[1]'),
      isA<LegacyStoreUnreadable>(),
    );
  });

  test('legacyStoreOverrides binds the port', () {
    final container = ProviderContainer(
      overrides: legacyStoreOverrides(timeout: const Duration(seconds: 5)),
    );
    addTearDown(container.dispose);
    expect(
      container.read(legacyStorePortProvider),
      isA<MethodChannelLegacyStore>(),
    );
  });
}
