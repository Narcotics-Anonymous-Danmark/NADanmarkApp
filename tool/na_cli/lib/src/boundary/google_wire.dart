import 'package:json_annotation/json_annotation.dart';
import 'package:na_cli/src/boundary/wire_json.dart';

part 'google_wire.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
  converters: [LenientText()],
)
final class ServiceAccountDto {
  const ServiceAccountDto({this.clientEmail, this.privateKey});

  factory ServiceAccountDto.fromJson(final WireObject json) =>
      _$ServiceAccountDtoFromJson(json);

  final String? clientEmail;
  final String? privateKey;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  fieldRename: FieldRename.snake,
  converters: [LenientText()],
)
final class GoogleTokenDto {
  const GoogleTokenDto({this.accessToken});

  factory GoogleTokenDto.fromJson(final WireObject json) =>
      _$GoogleTokenDtoFromJson(json);

  final String? accessToken;
}

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText()],
)
final class PlayEditDto {
  const PlayEditDto({this.id});

  factory PlayEditDto.fromJson(final WireObject json) =>
      _$PlayEditDtoFromJson(json);

  final String? id;
}

@JsonSerializable(createFactory: false, explicitToJson: true)
final class PlayTrackDto {
  const PlayTrackDto({required this.releases});

  final List<PlayReleaseDto> releases;

  WireObject toJson() => _$PlayTrackDtoToJson(this);
}

@JsonSerializable(
  createFactory: false,
  explicitToJson: true,
  includeIfNull: false,
)
final class PlayReleaseDto {
  const PlayReleaseDto({
    required this.name,
    required this.versionCodes,
    required this.status,
    this.releaseNotes,
  });

  final String name;
  final List<String> versionCodes;
  final String status;
  final List<PlayReleaseNoteDto>? releaseNotes;

  WireObject toJson() => _$PlayReleaseDtoToJson(this);
}

@JsonSerializable(createFactory: false)
final class PlayReleaseNoteDto {
  const PlayReleaseNoteDto({required this.language, required this.text});

  final String language;
  final String text;

  WireObject toJson() => _$PlayReleaseNoteDtoToJson(this);
}
