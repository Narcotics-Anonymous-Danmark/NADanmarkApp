// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AudiobookDto _$AudiobookDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AudiobookDto', json, ($checkedConvert) {
      final val = AudiobookDto(
        bookTitle: $checkedConvert(
          'bookTitle',
          (v) => const LenientText().fromJson(v),
        ),
        chapters: $checkedConvert(
          'chapters',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ChapterDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

ChapterDto _$ChapterDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChapterDto', json, ($checkedConvert) {
      final val = ChapterDto(
        title: $checkedConvert('title', (v) => const LenientText().fromJson(v)),
        url: $checkedConvert('url', (v) => const LenientText().fromJson(v)),
        duration: $checkedConvert(
          'duration',
          (v) => const LenientText().fromJson(v),
        ),
      );
      return val;
    });

ReadingDto _$ReadingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingDto', json, ($checkedConvert) {
      final val = ReadingDto(
        title: $checkedConvert('title', (v) => const LenientText().fromJson(v)),
        heading: $checkedConvert(
          'heading',
          (v) => const LenientText().fromJson(v),
        ),
        background: $checkedConvert(
          'background',
          (v) => const LenientText().fromJson(v),
        ),
        blocks: $checkedConvert(
          'blocks',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ReadingBlockDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

ReadingBlockDto _$ReadingBlockDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingBlockDto', json, ($checkedConvert) {
      final val = ReadingBlockDto(
        kind: $checkedConvert('kind', (v) => const LenientText().fromJson(v)),
        spans: $checkedConvert(
          'spans',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ReadingSpanDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ReadingLineDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

ReadingLineDto _$ReadingLineDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingLineDto', json, ($checkedConvert) {
      final val = ReadingLineDto(
        spans: $checkedConvert(
          'spans',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ReadingSpanDto.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

ReadingSpanDto _$ReadingSpanDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReadingSpanDto', json, ($checkedConvert) {
      final val = ReadingSpanDto(
        text: $checkedConvert('text', (v) => const LenientText().fromJson(v)),
        emphasis: $checkedConvert('emphasis', (v) => v as bool?),
      );
      return val;
    });
