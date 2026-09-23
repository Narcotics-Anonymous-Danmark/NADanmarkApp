import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

typedef WireObject = Map<String, dynamic>;

final class LenientText implements JsonConverter<String?, Object?> {
  const LenientText();

  @override
  String? fromJson(Object? json) => switch (json) {
    final String text => text,
    final double number when number == number.roundToDouble() =>
      number.toInt().toString(),
    final num number => number.toString(),
    _ => null,
  };

  @override
  Object? toJson(String? object) => object;
}

final class LenientInt implements JsonConverter<int?, Object?> {
  const LenientInt();

  @override
  int? fromJson(Object? json) => switch (json) {
    final int number => number,
    final double number when number == number.roundToDouble() => number.toInt(),
    final String text => int.tryParse(text.trim()),
    _ => null,
  };

  @override
  Object? toJson(int? object) => object;
}

final class WireJson {
  const WireJson();

  Outcome<Object?, DecodeFailure> parse({
    required String text,
    required String context,
  }) {
    try {
      return Ok(value: jsonDecode(text));
    } on FormatException catch (error) {
      return Err(error: DecodeFailure(detail: '$context: ${error.message}'));
    }
  }

  Outcome<T, DecodeFailure> object<T>({
    required Object? json,
    required T Function(WireObject json) fromJson,
    required String context,
  }) => switch (json) {
    final WireObject map => _guard(
      build: () => fromJson(map),
      context: context,
    ),
    _ => Err(error: DecodeFailure(detail: '$context: not a JSON object')),
  };

  Outcome<List<T>, DecodeFailure> rows<T>({
    required Object? json,
    required T Function(WireObject json) fromJson,
    required String context,
  }) => switch (json) {
    final List<dynamic> items => Ok(
      value: List<T>.unmodifiable(
        items.indexed
            .map(
              (entry) => object(
                json: entry.$2,
                fromJson: fromJson,
                context: '$context[${entry.$1}]',
              ),
            )
            .whereType<Ok<T, DecodeFailure>>()
            .map((ok) => ok.value),
      ),
    ),
    final WireObject map when map.isEmpty => Ok(
      value: List<T>.unmodifiable([]),
    ),
    _ => Err(error: DecodeFailure(detail: '$context: not a list')),
  };

  Outcome<T, DecodeFailure> _guard<T>({
    required T Function() build,
    required String context,
  }) {
    try {
      return Ok(value: build());
    } on CheckedFromJsonException catch (error) {
      return Err(
        error: DecodeFailure(
          detail: '$context.${error.key}: ${error.message ?? 'unexpected'}',
        ),
      );
    }
  }
}
