import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class AssetJftSource implements JftPort {
  const AssetJftSource({required this.bundle});

  static const String assetKey = 'packages/adapter_jft/assets/jft.json';

  final AssetBundle bundle;

  @override
  Future<Outcome<JftCalendar, Failure>> load() => bundle
      .loadString(assetKey)
      .then<Outcome<JftCalendar, Failure>>((text) => decode(text: text))
      .catchError(
        (Object error) => Err<JftCalendar, Failure>(
          error: UnavailableFailure(what: '$assetKey: $error'),
        ),
        test: (error) => error is FlutterError,
      );

  static Outcome<JftCalendar, Failure> decode({required String text}) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException catch (error) {
      return Err(error: DecodeFailure(detail: 'jft.json: ${error.message}'));
    }
    return switch (json) {
      final List<Object?> items => _entries(items: items).map(
        transform: (entries) => JftCalendar(entries: entries),
      ),
      _ => const Err(error: DecodeFailure(detail: 'jft.json: not a list')),
    };
  }

  static Outcome<List<JftEntry>, Failure> _entries({
    required List<Object?> items,
  }) {
    final decoded = items.indexed.map(
      (entry) => switch (entry.$2) {
        final JsonMap item => _entry(
          reader: JsonReader(json: item, context: 'jft[${entry.$1}]'),
        ),
        _ => Err<JftEntry, Failure>(
          error: DecodeFailure(detail: 'jft[${entry.$1}] is not an object'),
        ),
      },
    );
    final errors = decoded.whereType<Err<JftEntry, Failure>>();
    return errors.isEmpty
        ? Ok(
            value: List.unmodifiable(
              decoded.whereType<Ok<JftEntry, Failure>>().map((ok) => ok.value),
            ),
          )
        : Err(error: errors.first.error);
  }

  static Outcome<JftEntry, Failure> _entry({
    required JsonReader reader,
  }) => reader
      .integer(key: 'day')
      .flatMap(
        transform: (day) => reader
            .string(key: 'month')
            .flatMap(
              transform: (monthName) =>
                  DanishMonth.parse(name: monthName).flatMap(
                    transform: (month) => reader
                        .string(key: 'title')
                        .flatMap(
                          transform: (title) => reader
                              .string(key: 'quote')
                              .flatMap(
                                transform: (quote) => reader
                                    .string(key: 'source')
                                    .flatMap(
                                      transform: (source) => reader
                                          .string(key: 'text')
                                          .flatMap(
                                            transform: (text) => reader
                                                .string(key: 'jft')
                                                .map(
                                                  transform: (jft) => JftEntry(
                                                    day: day,
                                                    month: month,
                                                    title: title,
                                                    quote: quote,
                                                    source: source,
                                                    text: text,
                                                    closing: JftClosing.parse(
                                                      text: jft,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                    ),
                              ),
                        ),
                  ),
            ),
      );
}
