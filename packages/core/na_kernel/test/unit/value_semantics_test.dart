@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/dates.dart';

void main() {
  group('Failure value semantics', () {
    const failures = <Failure>[
      NetworkFailure(detail: 'offline'),
      DecodeFailure(detail: 'bad json'),
      PermissionDeniedFailure(),
      TimeoutFailure(after: Duration(seconds: 5)),
      StorageFailure(detail: 'disk'),
      UnavailableFailure(what: 'maps'),
    ];

    test('each failure equals a copy of itself and describes itself', () {
      const copies = <Failure>[
        NetworkFailure(detail: 'offline'),
        DecodeFailure(detail: 'bad json'),
        PermissionDeniedFailure(),
        TimeoutFailure(after: Duration(seconds: 5)),
        StorageFailure(detail: 'disk'),
        UnavailableFailure(what: 'maps'),
      ];
      for (final pair in failures.indexed) {
        expect(pair.$2, copies[pair.$1]);
        expect(pair.$2.hashCode, copies[pair.$1].hashCode);
        expect(pair.$2.toString(), contains('Failure'));
      }
    });

    test('different failures are not equal', () {
      expect(failures.toSet(), hasLength(failures.length));
    });
  });

  group('Outcome and LoadResult value semantics', () {
    test('ok, err, loading, loaded and failed compare by value', () {
      expect(
        const Ok<int, Failure>(value: 1),
        const Ok<int, Failure>(value: 1),
      );
      expect(
        const Ok<int, Failure>(value: 1).hashCode,
        const Ok<int, Failure>(value: 1).hashCode,
      );
      expect(const Ok<int, Failure>(value: 1).toString(), 'Ok(1)');
      const err = Err<int, Failure>(error: PermissionDeniedFailure());
      expect(err, const Err<int, Failure>(error: PermissionDeniedFailure()));
      expect(
        err.hashCode,
        const Err<int, Failure>(error: PermissionDeniedFailure()).hashCode,
      );
      expect(err.toString(), 'Err(PermissionDeniedFailure)');
      expect(const Loading<int>(), const Loading<int>());
      expect(const Loading<int>().hashCode, const Loading<int>().hashCode);
      expect(const Loading<int>().toString(), 'Loading');
      expect(
        const Loaded<int>(value: 2).hashCode,
        const Loaded<int>(value: 2).hashCode,
      );
      expect(const Loaded<int>(value: 2).toString(), 'Loaded(2)');
      const failed = Failed<int>(failure: StorageFailure(detail: 'x'));
      expect(failed, const Failed<int>(failure: StorageFailure(detail: 'x')));
      expect(
        failed.hashCode,
        const Failed<int>(failure: StorageFailure(detail: 'x')).hashCode,
      );
      expect(failed.toString(), 'Failed(StorageFailure(x))');
    });

    test('flatMap chains and short-circuits', () {
      const ok = Ok<int, Failure>(value: 2);
      expect(
        ok.flatMap(transform: (value) => Ok<String, Failure>(value: '$value')),
        const Ok<String, Failure>(value: '2'),
      );
      const err = Err<int, Failure>(error: PermissionDeniedFailure());
      expect(
        err.flatMap(transform: (value) => Ok<String, Failure>(value: '$value')),
        const Err<String, Failure>(error: PermissionDeniedFailure()),
      );
      expect(err.fold(onOk: (value) => 'ok', onErr: (error) => 'err'), 'err');
      expect(
        const Failed<int>(
          failure: PermissionDeniedFailure(),
        ).map(transform: (value) => '$value'),
        const Failed<String>(failure: PermissionDeniedFailure()),
      );
    });
  });

  group('Instant', () {
    test('adds durations, measures gaps and compares', () {
      final start = anInstant(hour: 10);
      final later = start.plus(duration: const Duration(minutes: 30));
      expect(later.since(other: start), const Duration(minutes: 30));
      expect(start.compareTo(other: later), Comparison.before);
      expect(later.compareTo(other: start), Comparison.after);
      expect(start.compareTo(other: anInstant(hour: 10)), Comparison.same);
      expect(start.epochMilliseconds, start.utc.millisecondsSinceEpoch);
    });
  });

  group('LocalDate extras', () {
    test('converts from DateTime, counts days and compares after', () {
      final date = LocalDate.fromDateTime(
        dateTime: DateTime(2026, 9, 10, 23, 59),
      );
      expect(date, aDate());
      expect(date.daysUntil(other: aDate(day: 12)), 2);
      expect(date.plusDays(days: 21), aDate(month: 10, day: 1));
      expect(aDate(day: 12).compareTo(other: date), Comparison.after);
      expect(date.hashCode, aDate().hashCode);
      expect(date.toString(), '2026-09-10');
      expect(
        aDate(
          month: 3,
          day: 31,
        ).wholeMonthsUntil(other: aDate(month: 4, day: 30)),
        1,
      );
    });
  });

  group('LocalTime', () {
    test('formats, adds and wraps around midnight', () {
      const time = LocalTime(hour: 23, minute: 45);
      expect(time.hhmm, '23:45');
      expect(
        time.plus(duration: const Duration(minutes: 30)),
        const LocalTime(hour: 0, minute: 15),
      );
      expect(time.minutesSinceMidnight, 23 * 60 + 45);
      expect(time, const LocalTime(hour: 23, minute: 45));
      expect(time.hashCode, const LocalTime(hour: 23, minute: 45).hashCode);
      expect(time.toString(), '23:45');
    });
  });

  group('AppVersion and Language', () {
    test('versions compare by value and print pubspec form', () {
      expect(aVersion(), aVersion());
      expect(aVersion().hashCode, aVersion().hashCode);
      expect(aVersion().toString(), '2.0.0+1120000001');
      expect(aVersion(build: 2), isNot(aVersion()));
    });

    test('languages resolve from codes with a Danish fallback', () {
      expect(Language.fromCode(code: 'en'), Language.english);
      expect(Language.fromCode(code: 'xx'), Language.danish);
    });
  });
}
