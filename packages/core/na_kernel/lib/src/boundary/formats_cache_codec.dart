import 'dart:convert';

import 'package:na_kernel/src/boundary/bmlt_mapper.dart';
import 'package:na_kernel/src/boundary/bmlt_wire.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/meetings/formats_snapshot.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/instant.dart';

final class FormatsCacheCodec {
  const FormatsCacheCodec();

  static const WireJson _wire = WireJson();
  static const BmltMapper _mapper = BmltMapper();

  String encode({required FormatsSnapshot snapshot}) => jsonEncode(
    FormatsCacheDto(
      fetchedAt: snapshot.fetchedAt.epochMilliseconds,
      formats: List.unmodifiable(
        snapshot.rows.map((row) => _mapper.formatDto(row: row)),
      ),
    ).toJson(),
  );

  Outcome<FormatsSnapshot, DecodeFailure> decode({required String text}) =>
      _wire
          .parse(text: text, context: 'formats cache')
          .flatMap(
            transform: (json) => _wire.object(
              json: json,
              fromJson: FormatsCacheDto.fromJson,
              context: 'formats cache',
            ),
          )
          .flatMap(transform: (dto) => snapshotOf(dto: dto));

  Outcome<FormatsSnapshot, DecodeFailure> snapshotOf({
    required FormatsCacheDto dto,
  }) => switch ((dto.fetchedAt, dto.formats)) {
    (final int fetchedAt, final List<BmltFormatDto> formats) => Ok(
      value: FormatsSnapshot(
        fetchedAt: Instant(
          DateTime.fromMillisecondsSinceEpoch(fetchedAt, isUtc: true),
        ),
        rows: _mapper.formatRowsOf(dtos: formats),
      ),
    ),
    _ => const Err(
      error: DecodeFailure(detail: 'formats cache: fetchedAt or formats'),
    ),
  };
}
