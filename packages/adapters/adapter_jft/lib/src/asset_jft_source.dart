import 'package:adapter_jft/src/jft_wire.dart';
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

  static const WireJson _wire = WireJson();

  static Outcome<JftCalendar, Failure> decode({required String text}) =>
      switch (_wire
          .parse(text: text, context: 'jft.json')
          .flatMap(
            transform: (json) => _wire.rows(
              json: json,
              fromJson: JftEntryDto.fromJson,
              context: 'jft',
            ),
          )) {
        Ok(:final value) => _entries(dtos: value),
        Err(:final error) => Err(error: error),
      };

  static Outcome<JftCalendar, Failure> _entries({
    required List<JftEntryDto> dtos,
  }) {
    final decoded = dtos.indexed.map(
      (entry) => _entry(dto: entry.$2, context: 'jft[${entry.$1}]'),
    );
    final errors = decoded.whereType<Err<JftEntry, Failure>>();
    return errors.isEmpty
        ? Ok(
            value: JftCalendar(
              entries: List.unmodifiable(
                decoded.whereType<Ok<JftEntry, Failure>>().map(
                  (ok) => ok.value,
                ),
              ),
            ),
          )
        : Err(error: errors.first.error);
  }

  static Outcome<JftEntry, Failure> _entry({
    required JftEntryDto dto,
    required String context,
  }) => switch ((
    dto.day,
    dto.month,
    dto.title,
    dto.quote,
    dto.source,
    dto.text,
    dto.jft,
  )) {
    (
      final int day,
      final String month,
      final String title,
      final String quote,
      final String source,
      final String text,
      final String jft,
    ) =>
      DanishMonth.parse(name: month).map(
        transform: (month) => JftEntry(
          day: DayOfMonth(day),
          month: month,
          title: JftTitle(title),
          quote: JftQuote(quote),
          source: JftSource(source),
          text: JftText(text),
          closing: JftClosing.parse(text: jft),
        ),
      ),
    _ => Err(error: DecodeFailure(detail: '$context: incomplete entry')),
  };
}
