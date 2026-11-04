import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/boundary/wire_json.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/media/resume_point.dart';
import 'package:na_kernel/src/results/failure.dart';
import 'package:na_kernel/src/results/outcome.dart';
import 'package:na_kernel/src/time/instant.dart';

part 'resume_codec.g.dart';

final class LenientWholeNumber implements JsonConverter<int?, Object?> {
  const LenientWholeNumber();

  @override
  int? fromJson(Object? json) => switch (json) {
    final int number => number,
    final double number when number.isFinite => number.floor(),
    final String text => switch (num.tryParse(text.trim())) {
      final num number when number.isFinite => number.floor(),
      Object() || null => null,
    },
    Object() || null => null,
  };

  @override
  Object? toJson(int? object) => object;
}

@JsonSerializable(
  checked: true,
  includeIfNull: false,
  converters: [LenientText(), LenientWholeNumber()],
)
@immutable
final class ResumePointDto {
  const ResumePointDto({
    this.trackId,
    this.trackIndex,
    this.position,
    this.duration,
    this.updatedAt,
  });

  factory ResumePointDto.fromJson(WireObject json) =>
      _$ResumePointDtoFromJson(json);

  final String? trackId;
  final int? trackIndex;
  final int? position;
  final int? duration;
  final String? updatedAt;

  WireObject toJson() => _$ResumePointDtoToJson(this);

  @override
  int get hashCode =>
      Object.hash(trackId, trackIndex, position, duration, updatedAt);

  @override
  bool operator ==(Object other) =>
      other is ResumePointDto &&
      other.trackId == trackId &&
      other.trackIndex == trackIndex &&
      other.position == position &&
      other.duration == duration &&
      other.updatedAt == updatedAt;
}

ResumePointDto? resumePointDtoOf(Object? json) => switch (json) {
  final WireObject map => switch (const WireJson().object(
    json: map,
    fromJson: ResumePointDto.fromJson,
    context: 'resume point',
  )) {
    Ok(:final value) => value,
    Err() => null,
  },
  final String text => switch (const WireJson().parse(
    text: text,
    context: 'resume point',
  )) {
    Ok(:final WireObject value) => resumePointDtoOf(value),
    Ok() || Err() => null,
  },
  Object() || null => null,
};

final class ResumeCodec {
  const ResumeCodec();

  static const WireJson _wire = WireJson();

  ResumePointDto dtoOf({required ResumePoint point}) => ResumePointDto(
    trackId: point.trackId.value,
    trackIndex: point.trackIndex.position,
    position: point.position.inSeconds,
    duration: switch (point.length) {
      KnownLength(:final duration) => duration.inSeconds,
      UnknownLength() => null,
    },
    updatedAt: point.updatedAt.utc.toIso8601String(),
  );

  String encodePoint({required ResumePoint point}) =>
      jsonEncode(dtoOf(point: point).toJson());

  Outcome<ResumePoint, DecodeFailure> decodePoint({
    required String text,
    required Instant fallbackTime,
  }) => switch (resumePointDtoOf(text)) {
    final ResumePointDto dto => pointOf(dto: dto, fallbackTime: fallbackTime),
    null => const Err(
      error: DecodeFailure(detail: 'resume point: not an object'),
    ),
  };

  Outcome<ResumePoint, DecodeFailure> pointOf({
    required ResumePointDto dto,
    required Instant fallbackTime,
  }) => switch ((dto.trackIndex, dto.position)) {
    (final int index, final int position) when index >= 0 && position >= 0 =>
      Ok(
        value: ResumePoint(
          trackId: TrackId(dto.trackId ?? ''),
          trackIndex: TrackIndex(index),
          position: Duration(seconds: position),
          length: MediaLength.of(
            duration: Duration(seconds: dto.duration ?? 0),
          ),
          updatedAt: switch (DateTime.tryParse(dto.updatedAt ?? '')) {
            final DateTime time => Instant(time.toUtc()),
            null => fallbackTime,
          },
        ),
      ),
    Record() => const Err(
      error: DecodeFailure(detail: 'resume point: trackIndex or position'),
    ),
  };

  String encodeIndex({required ResumeIndex index}) => jsonEncode(
    Map<String, WireObject>.fromEntries(
      index.points.entries.map(
        (entry) =>
            MapEntry(entry.key.value, dtoOf(point: entry.value).toJson()),
      ),
    ),
  );

  ResumeIndex decodeIndex({
    required String text,
    required Instant fallbackTime,
  }) => switch (_wire.parse(text: text, context: 'resume index')) {
    Ok(:final WireObject value) => ResumeIndex(
      points: Map.unmodifiable(
        Map.fromEntries(
          value.entries
              .map(
                (entry) => switch (resumePointDtoOf(entry.value)) {
                  final ResumePointDto dto => switch (pointOf(
                    dto: dto,
                    fallbackTime: fallbackTime,
                  )) {
                    Ok(value: final point) => MapEntry(
                      PlaylistId(entry.key),
                      point,
                    ),
                    Err() => null,
                  },
                  null => null,
                },
              )
              .whereType<MapEntry<PlaylistId, ResumePoint>>(),
        ),
      ),
    ),
    Ok() || Err() => ResumeIndex.empty,
  };
}
