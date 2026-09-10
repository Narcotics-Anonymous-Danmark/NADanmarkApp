import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';

typedef JsonMap = Map<String, Object?>;

final class JsonReader {
  const JsonReader({required this.json, required this.context});

  final JsonMap json;
  final String context;

  Outcome<String, DecodeFailure> string({required String key}) =>
      switch (json[key]) {
        final String value => Ok(value: value),
        final num value => Ok(value: value.toString()),
        _ => _missing(key: key, expected: 'string'),
      };

  Outcome<int, DecodeFailure> integer({required String key}) =>
      switch (json[key]) {
        final int value => Ok(value: value),
        final double value when value == value.roundToDouble() => Ok(
          value: value.toInt(),
        ),
        final String value => switch (int.tryParse(value)) {
          final int parsed => Ok(value: parsed),
          null => _missing(key: key, expected: 'integer'),
        },
        _ => _missing(key: key, expected: 'integer'),
      };

  Outcome<double, DecodeFailure> decimal({required String key}) =>
      switch (json[key]) {
        final num value => Ok(value: value.toDouble()),
        final String value => switch (double.tryParse(value)) {
          final double parsed => Ok(value: parsed),
          null => _missing(key: key, expected: 'decimal'),
        },
        _ => _missing(key: key, expected: 'decimal'),
      };

  R stringOr<R>({
    required String key,
    required R Function(String value) whenPresent,
    required R Function() whenAbsent,
  }) => switch (json[key]) {
    final String value when value.isNotEmpty => whenPresent(value),
    _ => whenAbsent(),
  };

  Outcome<List<T>, DecodeFailure> listOf<T>({
    required String key,
    required Outcome<T, DecodeFailure> Function(JsonReader item) decode,
  }) => switch (json[key]) {
    final List<Object?> items => _decodeAll(
      key: key,
      items: items,
      decode: decode,
    ),
    _ => _missing(key: key, expected: 'list'),
  };

  Outcome<JsonReader, DecodeFailure> object({required String key}) =>
      switch (json[key]) {
        final JsonMap value => Ok(
          value: JsonReader(json: value, context: '$context.$key'),
        ),
        _ => _missing(key: key, expected: 'object'),
      };

  Outcome<List<T>, DecodeFailure> _decodeAll<T>({
    required String key,
    required List<Object?> items,
    required Outcome<T, DecodeFailure> Function(JsonReader item) decode,
  }) {
    final decoded = items.indexed.map(
      (entry) => switch (entry.$2) {
        final JsonMap item => decode(
          JsonReader(json: item, context: '$context.$key[${entry.$1}]'),
        ),
        _ => Err<T, DecodeFailure>(
          error: DecodeFailure(
            detail: '$context.$key[${entry.$1}] is not an object',
          ),
        ),
      },
    );
    final firstError = decoded.whereType<Err<T, DecodeFailure>>();
    return firstError.isEmpty
        ? Ok(
            value: List.unmodifiable(
              decoded.whereType<Ok<T, DecodeFailure>>().map((ok) => ok.value),
            ),
          )
        : Err(error: firstError.first.error);
  }

  Err<T, DecodeFailure> _missing<T>({
    required String key,
    required String expected,
  }) => Err(
    error: DecodeFailure(detail: '$context.$key: expected $expected'),
  );
}
