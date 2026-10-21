import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/cleantime/cleantime_profiles.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/local_date.dart';

part 'cleantime_profiles_codec.g.dart';

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText()],
)
final class CleantimeProfileDto {
  const CleantimeProfileDto({this.name, this.cleanDate});

  factory CleantimeProfileDto.fromJson(WireObject json) =>
      _$CleantimeProfileDtoFromJson(json);

  final String? name;
  final String? cleanDate;

  WireObject toJson() => _$CleantimeProfileDtoToJson(this);
}

final class CleantimeProfilesCodec {
  const CleantimeProfilesCodec();

  static const WireJson _wire = WireJson();

  String encodeProfiles({required List<CleantimeProfile> profiles}) =>
      jsonEncode(
        List<WireObject>.unmodifiable(
          profiles.map(
            (profile) => CleantimeProfileDto(
              name: profile.name.text,
              cleanDate: profile.cleanDate.iso8601,
            ).toJson(),
          ),
        ),
      );

  Outcome<List<CleantimeProfile>, DecodeFailure> decodeProfiles({
    required String text,
  }) => _wire
      .parse(text: text, context: 'cleantimeProfiles')
      .flatMap(
        transform: (json) => _wire.rows(
          json: json,
          fromJson: CleantimeProfileDto.fromJson,
          context: 'cleantimeProfiles',
        ),
      )
      .map(
        transform: (dtos) => List<CleantimeProfile>.unmodifiable(
          dtos
              .map((dto) => profileOf(dto: dto))
              .whereType<Ok<CleantimeProfile, DecodeFailure>>()
              .map((ok) => ok.value),
        ),
      );

  Outcome<CleantimeProfile, DecodeFailure> profileOf({
    required CleantimeProfileDto dto,
  }) => switch ((
    dto.name?.trim(),
    LocalDate.parseIso(text: dto.cleanDate ?? ''),
  )) {
    (final String name, Ok(:final value)) when name.isNotEmpty => Ok(
      value: CleantimeProfile(name: ProfileName(name), cleanDate: value),
    ),
    Record() => const Err(
      error: DecodeFailure(detail: 'cleantimeProfiles: name or cleanDate'),
    ),
  };

  String encodeActive({required ProfileIndex index}) =>
      index.position.toString();

  Outcome<ProfileIndex, DecodeFailure> decodeActive({required String text}) =>
      switch (int.tryParse(text.trim())) {
        final int position => Ok(value: ProfileIndex(position)),
        null => Err(
          error: DecodeFailure(
            detail: 'activeCleantimeProfile: "$text" is not an integer',
          ),
        ),
      };
}
