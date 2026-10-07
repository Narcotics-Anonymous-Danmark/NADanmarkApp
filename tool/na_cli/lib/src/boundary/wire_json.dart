import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

typedef WireObject = Map<String, dynamic>;

sealed class WireRead<T> {
  const WireRead();
}

final class WireDecoded<T> extends WireRead<T> {
  const WireDecoded({required this.value});

  final T value;
}

final class WireRejected<T> extends WireRead<T> {
  const WireRejected({required this.reason});

  final String reason;
}

final class LenientText implements JsonConverter<String?, Object?> {
  const LenientText();

  @override
  String? fromJson(final Object? json) => switch (json) {
    final String text => text,
    final num number => number.toString(),
    _ => null,
  };

  @override
  Object? toJson(final String? object) => object;
}

final class LenientFlag implements JsonConverter<bool?, Object?> {
  const LenientFlag();

  @override
  bool? fromJson(final Object? json) => switch (json) {
    final bool flag => flag,
    _ => null,
  };

  @override
  Object? toJson(final bool? object) => object;
}

final class WireJson {
  const WireJson();

  WireRead<T> object<T>({
    required final String text,
    required final T Function(WireObject json) fromJson,
  }) => switch (_parse(text: text)) {
    WireDecoded<Object?>(value: final WireObject json) => _build(
      build: () => fromJson(json),
    ),
    WireDecoded<Object?>() => const WireRejected(
      reason: 'expected a JSON object',
    ),
    WireRejected<Object?>(:final reason) => WireRejected(reason: reason),
  };

  WireRead<List<T>> objects<T>({
    required final String text,
    required final T Function(WireObject json) fromJson,
  }) => switch (_parse(text: text)) {
    WireDecoded<Object?>(value: final List<dynamic> items) => WireDecoded(
      value: List<T>.unmodifiable(
        items
            .whereType<WireObject>()
            .map((final item) => _build(build: () => fromJson(item)))
            .whereType<WireDecoded<T>>()
            .map((final decoded) => decoded.value),
      ),
    ),
    WireDecoded<Object?>() => const WireRejected(
      reason: 'expected a JSON list',
    ),
    WireRejected<Object?>(:final reason) => WireRejected(reason: reason),
  };

  WireRead<Map<String, String>> textEntries({required final String text}) =>
      switch (_parse(text: text)) {
        WireDecoded<Object?>(value: final WireObject json) => WireDecoded(
          value: Map.unmodifiable({
            for (final entry in json.entries)
              if (entry.value case final String value) entry.key: value,
          }),
        ),
        WireDecoded<Object?>() => const WireRejected(
          reason: 'expected a JSON object',
        ),
        WireRejected<Object?>(:final reason) => WireRejected(reason: reason),
      };

  String encode({required final WireObject json}) => jsonEncode(json);

  WireRead<Object?> _parse({required final String text}) {
    try {
      return WireDecoded(value: jsonDecode(text));
    } on FormatException catch (error) {
      return WireRejected(reason: error.message);
    }
  }

  WireRead<T> _build<T>({required final T Function() build}) {
    try {
      return WireDecoded(value: build());
    } on CheckedFromJsonException catch (error) {
      return WireRejected(
        reason: '${error.key}: ${error.message ?? 'unexpected value'}',
      );
    }
  }
}
