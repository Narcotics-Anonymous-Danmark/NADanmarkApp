import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/boundary.dart';

part 'assets_wire.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class AudiobookDto {
  const AudiobookDto({this.bookTitle, this.chapters});

  factory AudiobookDto.fromJson(WireObject json) =>
      _$AudiobookDtoFromJson(json);

  final String? bookTitle;
  final List<ChapterDto>? chapters;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class ChapterDto {
  const ChapterDto({this.title, this.url, this.duration});

  factory ChapterDto.fromJson(WireObject json) => _$ChapterDtoFromJson(json);

  final String? title;
  final String? url;
  final String? duration;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class ReadingDto {
  const ReadingDto({this.title, this.heading, this.background, this.blocks});

  factory ReadingDto.fromJson(WireObject json) => _$ReadingDtoFromJson(json);

  final String? title;
  final String? heading;
  final String? background;
  final List<ReadingBlockDto>? blocks;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class ReadingBlockDto {
  const ReadingBlockDto({this.kind, this.spans, this.items});

  factory ReadingBlockDto.fromJson(WireObject json) =>
      _$ReadingBlockDtoFromJson(json);

  final String? kind;
  final List<ReadingSpanDto>? spans;
  final List<ReadingLineDto>? items;
}

@JsonSerializable(checked: true, createToJson: false)
final class ReadingLineDto {
  const ReadingLineDto({this.spans});

  factory ReadingLineDto.fromJson(WireObject json) =>
      _$ReadingLineDtoFromJson(json);

  final List<ReadingSpanDto>? spans;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class ReadingSpanDto {
  const ReadingSpanDto({this.text, this.emphasis});

  factory ReadingSpanDto.fromJson(WireObject json) =>
      _$ReadingSpanDtoFromJson(json);

  final String? text;
  final bool? emphasis;
}
