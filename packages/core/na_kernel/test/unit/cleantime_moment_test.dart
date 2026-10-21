@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/moment_fixture.dart';

void main() {
  final cases = momentCases();

  test('the fixture table covers every anniversary kind', () {
    expect(
      AnniversaryKind.values.every(
        (kind) => cases.any(
          (entry) => entry.anniversaryToday.text.startsWith(
            '${kind.keyTag.file}:',
          ),
        ),
      ),
      isTrue,
    );
  });

  test('breakdowns match the legacy moment code', () {
    final mismatches = cases.where(
      (entry) =>
          CleanTime.between(cleanDate: entry.cleanDate, today: entry.today) !=
          entry.cleanTime,
    );
    expect(mismatches.map((entry) => entry.label), isEmpty);
  });

  test("today's anniversary matches the legacy moment code", () {
    final mismatches = cases.where(
      (entry) =>
          describeToday(
            today: AnniversaryToday.of(
              cleanDate: entry.cleanDate,
              today: entry.today,
            ),
          ) !=
          entry.anniversaryToday,
    );
    expect(
      mismatches
          .where(
            (entry) =>
                momentDifference(entry: entry) == MomentDifference.unexplained,
          )
          .map((entry) => entry.label),
      isEmpty,
    );
    expect(mismatches, isNotEmpty);
  });

  test('upcoming anniversaries match the legacy moment code', () {
    final recorded = cases.where(
      (entry) => entry.upcoming is UpcomingRecorded,
    );
    final mismatches = recorded.where(
      (entry) => switch (entry.upcoming) {
        UpcomingRecorded(:final entries) =>
          UpcomingAnniversary.within(
                    cleanDate: entry.cleanDate,
                    today: entry.today,
                  )
                  .map((upcoming) => describeUpcoming(upcoming: upcoming))
                  .join(',') !=
              entries.join(','),
        UpcomingNotRecorded() => false,
      },
    );
    expect(recorded, isNotEmpty);
    expect(mismatches.map((entry) => entry.label), isEmpty);
  });
}
