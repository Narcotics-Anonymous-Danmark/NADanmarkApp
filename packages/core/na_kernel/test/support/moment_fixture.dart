import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';

part 'moment_fixture.g.dart';

@JsonSerializable(createToJson: false, checked: true)
final class MomentFixtureDto {
  const MomentFixtureDto({this.rows});

  factory MomentFixtureDto.fromJson(WireObject json) =>
      _$MomentFixtureDtoFromJson(json);

  final List<MomentRowDto>? rows;
}

@JsonSerializable(createToJson: false, checked: true)
final class MomentRowDto {
  const MomentRowDto({
    this.clean,
    this.today,
    this.ymd,
    this.md,
    this.days,
    this.tag,
    this.upcoming,
  });

  factory MomentRowDto.fromJson(WireObject json) =>
      _$MomentRowDtoFromJson(json);

  final String? clean;
  final String? today;
  final List<int>? ymd;
  final List<int>? md;
  final int? days;
  final String? tag;
  final List<String>? upcoming;
}

final class MomentCase {
  const MomentCase({
    required this.cleanDate,
    required this.today,
    required this.cleanTime,
    required this.anniversaryToday,
    required this.upcoming,
  });

  final LocalDate cleanDate;
  final LocalDate today;
  final CleanTime cleanTime;
  final MomentText anniversaryToday;
  final MomentUpcoming upcoming;

  String get label => '$cleanDate → $today';
}

extension type const MomentText(String text) {}

sealed class MomentUpcoming {
  const MomentUpcoming();
}

final class UpcomingRecorded extends MomentUpcoming {
  const UpcomingRecorded({required this.entries});

  final List<MomentText> entries;
}

final class UpcomingNotRecorded extends MomentUpcoming {
  const UpcomingNotRecorded();
}

MomentText describeAnniversary({required Anniversary anniversary}) =>
    MomentText(
      '${anniversary.kind.keyTag.file}:${countOf(anniversary: anniversary)}',
    );

MomentText describeToday({required AnniversaryToday today}) => switch (today) {
  OnAnniversary(:final anniversary) => describeAnniversary(
    anniversary: anniversary,
  ),
  NoAnniversary() => const MomentText(''),
};

MomentText describeUpcoming({required UpcomingAnniversary upcoming}) =>
    MomentText(
      '${upcoming.anniversary.kind.keyTag.file}:'
      '${countOf(anniversary: upcoming.anniversary)}:${upcoming.date}',
    );

enum MomentDifference { monthEndEcho, unexplained }

MomentDifference momentDifference({required MomentCase entry}) {
  final yesterday = entry.today.plusDays(days: -1);
  final matching =
      [
        ...Anniversary.fixed,
        ...List.generate(
          60,
          (offset) => Anniversary.afterYears(years: YearCount(offset + 2)),
        ),
      ].where(
        (anniversary) =>
            describeAnniversary(anniversary: anniversary) ==
            entry.anniversaryToday,
      );
  return entry.today.plusDays(days: 1).day == 1 &&
          entry.cleanDate.day < entry.today.day &&
          AnniversaryToday.of(cleanDate: entry.cleanDate, today: entry.today)
              is NoAnniversary &&
          matching.any(
            (anniversary) =>
                anniversary.dateFor(cleanDate: entry.cleanDate) == yesterday,
          )
      ? MomentDifference.monthEndEcho
      : MomentDifference.unexplained;
}

int countOf({required Anniversary anniversary}) => switch (anniversary.offset) {
  AfterDays(:final days) => days.value,
  AfterMonths(:final months) => months.value,
  AfterYears(:final years) => years.value,
};

List<MomentCase> momentCases() {
  const wire = WireJson();
  final decoded = wire
      .parse(text: _fixtureText(), context: 'moment fixture')
      .flatMap(
        transform: (json) => wire.object(
          json: json,
          fromJson: MomentFixtureDto.fromJson,
          context: 'moment fixture',
        ),
      );
  return switch (decoded) {
    Ok(:final value) => List.unmodifiable(
      (value.rows ?? const <MomentRowDto>[]).map(_caseOf),
    ),
    Err(:final error) => throw StateError('moment fixture: $error'),
  };
}

MomentCase _caseOf(MomentRowDto row) {
  final ymd = row.ymd ?? const <int>[];
  final md = row.md ?? const <int>[];
  return MomentCase(
    cleanDate: _date(text: row.clean ?? ''),
    today: _date(text: row.today ?? ''),
    cleanTime: CleanTime(
      yearsMonthsDays: YearsMonthsDays(
        years: YearCount(ymd[0]),
        months: MonthCount(ymd[1]),
        days: DayCount(ymd[2]),
      ),
      monthsDays: MonthsDays(months: MonthCount(md[0]), days: DayCount(md[1])),
      days: DayCount(row.days ?? -1),
    ),
    anniversaryToday: MomentText(row.tag ?? ''),
    upcoming: switch (row.upcoming) {
      final List<String> entries => UpcomingRecorded(
        entries: List.unmodifiable(entries.map(MomentText.new)),
      ),
      null => const UpcomingNotRecorded(),
    },
  );
}

LocalDate _date({required String text}) =>
    switch (LocalDate.parseIso(text: text)) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('moment fixture: $error'),
    };

String _fixtureText() {
  final segments = Directory.current.absolute.uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  return List.generate(
        segments.length + 1,
        (depth) => File(
          '/${segments.take(segments.length - depth).join('/')}'
          '/packages/core/na_testing/fixtures/cleantime/moment_cleantime.json',
        ),
      )
      .firstWhere(
        (candidate) => candidate.existsSync(),
        orElse: () => throw StateError('moment_cleantime.json not found'),
      )
      .readAsStringSync();
}
