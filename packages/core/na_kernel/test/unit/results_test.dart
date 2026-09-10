@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Outcome', () {
    test('maps the ok value', () {
      const outcome = Ok<int, Failure>(value: 2);
      expect(
        outcome.map(transform: (value) => value * 2),
        const Ok<int, Failure>(value: 4),
      );
    });

    test('keeps the error when mapping', () {
      const outcome = Err<int, Failure>(error: PermissionDeniedFailure());
      expect(
        outcome.map(transform: (value) => value * 2),
        const Err<int, Failure>(error: PermissionDeniedFailure()),
      );
    });

    test('folds both branches', () {
      const ok = Ok<int, Failure>(value: 1);
      expect(
        ok.fold(onOk: (value) => 'ok $value', onErr: (_) => 'err'),
        'ok 1',
      );
    });
  });

  group('LoadResult', () {
    test('is built from an outcome', () {
      expect(
        LoadResult.fromOutcome(outcome: const Ok<int, Failure>(value: 3)),
        const Loaded<int>(value: 3),
      );
      expect(
        LoadResult.fromOutcome(
          outcome: const Err<int, Failure>(
            error: TimeoutFailure(after: Duration(seconds: 1)),
          ),
        ),
        const Failed<int>(failure: TimeoutFailure(after: Duration(seconds: 1))),
      );
    });

    test('maps loaded values and keeps loading', () {
      expect(
        const Loaded<int>(value: 1).map(transform: (value) => '$value'),
        const Loaded<String>(value: '1'),
      );
      expect(
        const Loading<int>().map(transform: (value) => '$value'),
        const Loading<String>(),
      );
    });
  });
}
