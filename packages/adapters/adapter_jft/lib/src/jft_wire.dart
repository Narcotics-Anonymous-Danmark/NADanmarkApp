import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/boundary.dart';

part 'jft_wire.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: false,
  converters: [LenientText(), LenientInt()],
)
final class JftEntryDto {
  const JftEntryDto({
    this.day,
    this.month,
    this.title,
    this.quote,
    this.source,
    this.text,
    this.jft,
  });

  factory JftEntryDto.fromJson(WireObject json) => _$JftEntryDtoFromJson(json);

  final int? day;
  final String? month;
  final String? title;
  final String? quote;
  final String? source;
  final String? text;
  final String? jft;
}
