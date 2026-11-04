import 'package:adapter_assets/src/assets_wire.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class AssetReadings implements ReadingsPort {
  const AssetReadings({required this.bundle});

  static const String assetKey = 'packages/adapter_assets/assets/readings.json';

  final AssetBundle bundle;

  @override
  Future<Outcome<ReadingCollection, Failure>> load() => bundle
      .loadString(assetKey)
      .then<Outcome<ReadingCollection, Failure>>((text) => decode(text: text))
      .catchError(
        (Object error) => Err<ReadingCollection, Failure>(
          error: UnavailableFailure(what: '$assetKey: $error'),
        ),
        test: (error) => error is FlutterError,
      );

  static const WireJson _wire = WireJson();

  static Outcome<ReadingCollection, Failure> decode({required String text}) =>
      switch (_wire
          .parse(text: text, context: 'readings.json')
          .flatMap(
            transform: (json) => _wire.list(
              json: json,
              fromJson: ReadingDto.fromJson,
              context: 'readings',
            ),
          )) {
        Ok(:final value) => _collection(dtos: value),
        Err(:final error) => Err(error: error),
      };

  static Outcome<ReadingCollection, Failure> _collection({
    required List<ReadingDto> dtos,
  }) {
    final readings = dtos.map(_reading).toList();
    if (readings.any((reading) => reading == null)) {
      return const Err(error: DecodeFailure(detail: 'readings: bad reading'));
    }
    return Ok(
      value: ReadingCollection(
        readings: List.unmodifiable(readings.whereType<Reading>()),
      ),
    );
  }

  static final RegExp _colour = RegExp(r'^#([0-9A-Fa-f]{6})$');

  static Reading? _reading(ReadingDto dto) {
    final title = dto.title?.trim() ?? '';
    final heading = dto.heading?.trim() ?? '';
    final colour = _colour.firstMatch(dto.background?.trim() ?? '')?.group(1);
    final blocks = (dto.blocks ?? const <ReadingBlockDto>[])
        .map(_block)
        .toList();
    if (title.isEmpty ||
        heading.isEmpty ||
        colour == null ||
        blocks.isEmpty ||
        blocks.any((block) => block == null)) {
      return null;
    }
    return Reading(
      title: ReadingTitle(title),
      heading: ReadingHeading(heading),
      colour: ReadingColour(0xFF000000 | int.parse(colour, radix: 16)),
      blocks: List.unmodifiable(blocks.whereType<ReadingBlock>()),
    );
  }

  static ReadingBlock? _block(ReadingBlockDto dto) => switch (dto.kind) {
    'paragraph' => switch (_line(dto.spans)) {
      final ReadingLine line => ReadingParagraph(line: line),
      null => null,
    },
    'hanging' => switch (_line(dto.spans)) {
      final ReadingLine line => HangingParagraph(line: line),
      null => null,
    },
    'numbered' => switch ((dto.items ?? const <ReadingLineDto>[])
        .map((item) => _line(item.spans))
        .toList()) {
      final List<ReadingLine?> items
          when items.isNotEmpty && items.every((item) => item != null) =>
        NumberedList(items: List.unmodifiable(items.whereType<ReadingLine>())),
      List<ReadingLine?>() => null,
    },
    String() || null => null,
  };

  static ReadingLine? _line(List<ReadingSpanDto>? spans) {
    final kept = (spans ?? const <ReadingSpanDto>[])
        .where((span) => (span.text ?? '').isNotEmpty)
        .map(
          (span) => ReadingSpan(
            text: ReadingText(span.text ?? ''),
            emphasis: span.emphasis == true
                ? Emphasis.emphasised
                : Emphasis.plain,
          ),
        )
        .toList();
    return kept.isEmpty ? null : ReadingLine(spans: List.unmodifiable(kept));
  }
}
