// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jft_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JftEntryDto _$JftEntryDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'JftEntryDto',
  json,
  ($checkedConvert) {
    final val = JftEntryDto(
      day: $checkedConvert('day', (v) => const LenientInt().fromJson(v)),
      month: $checkedConvert('month', (v) => const LenientText().fromJson(v)),
      title: $checkedConvert('title', (v) => const LenientText().fromJson(v)),
      quote: $checkedConvert('quote', (v) => const LenientText().fromJson(v)),
      source: $checkedConvert('source', (v) => const LenientText().fromJson(v)),
      text: $checkedConvert('text', (v) => const LenientText().fromJson(v)),
      jft: $checkedConvert('jft', (v) => const LenientText().fromJson(v)),
    );
    return val;
  },
);
