import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/speaks/feed_text.dart';
import 'package:na_kernel/src/speaks/speak_feed.dart';
import 'package:na_kernel/src/speaks/speak_values.dart';

part 'speaks_wire.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  explicitToJson: true,
  converters: [LenientText()],
)
final class SpeakGroupDto {
  const SpeakGroupDto({this.title, this.speaks});

  factory SpeakGroupDto.fromJson(WireObject json) =>
      _$SpeakGroupDtoFromJson(json);

  final String? title;
  final List<SpeakEntryDto>? speaks;

  WireObject toJson() => _$SpeakGroupDtoToJson(this);
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class SpeakEntryDto {
  const SpeakEntryDto({this.name, this.location, this.year, this.audioUrl});

  factory SpeakEntryDto.fromJson(WireObject json) =>
      _$SpeakEntryDtoFromJson(json);

  final String? name;
  final String? location;
  final String? year;
  final String? audioUrl;

  WireObject toJson() => _$SpeakEntryDtoToJson(this);
}

final class SpeaksMapper {
  const SpeaksMapper();

  static const WireJson _wire = WireJson();

  Outcome<List<FeedGroup>, DecodeFailure> groups({
    required Object? json,
    required SpeakLanguage language,
  }) => _wire
      .rows(
        json: json,
        fromJson: SpeakGroupDto.fromJson,
        context: 'speaks.${language.code}',
      )
      .map(
        transform: (dtos) => List<FeedGroup>.unmodifiable(
          dtos.map((dto) => group(dto: dto, language: language)),
        ),
      );

  FeedGroup group({
    required SpeakGroupDto dto,
    required SpeakLanguage language,
  }) => FeedGroup(
    title: FeedText(dto.title ?? ''),
    language: language,
    entries: List.unmodifiable(
      (dto.speaks ?? const <SpeakEntryDto>[])
          .map((entry) => this.entry(dto: entry))
          .whereType<Ok<FeedEntry, DecodeFailure>>()
          .map((ok) => ok.value),
    ),
  );

  Outcome<FeedEntry, DecodeFailure> entry({required SpeakEntryDto dto}) {
    final text = (dto.audioUrl ?? '').trim();
    return switch (Uri.tryParse(text)) {
      final Uri uri
          when text.isNotEmpty &&
              (uri.scheme == 'http' || uri.scheme == 'https') &&
              uri.host.isNotEmpty =>
        Ok(
          value: FeedEntry(
            id: PlaylistId(text),
            url: AudioUrl(uri),
            name: FeedText(dto.name ?? ''),
            location: FeedText(dto.location ?? ''),
            year: FeedText(dto.year ?? ''),
          ),
        ),
      Object() || null => Err(
        error: DecodeFailure(detail: 'speak: "$text" is not an audio URL'),
      ),
    };
  }
}
