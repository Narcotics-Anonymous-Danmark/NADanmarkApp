@Tags(['unit'])
library;

import 'package:na_cli/src/check/conventional_commit.dart';
import 'package:test/test.dart';

void main() {
  const check = ConventionalCommit();

  test('accepts type, optional scope, breaking marker and subject', () {
    for (final message in [
      'feat: add meetings',
      'fix(meetings): handle empty list',
      'refactor(na-kernel)!: rename LocalDate',
      'chore: bump deps\n\nBody text',
    ]) {
      expect(check.check(message: message), isA<CommitMessageAccepted>());
    }
  });

  test('accepts merge, revert and fixup lines', () {
    for (final message in [
      "Merge branch 'main' into feature",
      'Revert "feat: add meetings"',
      'fixup! feat: add meetings',
    ]) {
      expect(check.check(message: message), isA<CommitMessageAccepted>());
    }
  });

  test('ignores comment lines from the editor template', () {
    expect(
      check.check(message: '# Please enter\nfeat: hello'),
      isA<CommitMessageAccepted>(),
    );
  });

  test(
    'rejects unknown types, uppercase scopes, empty and long subjects',
    () {
      for (final message in [
        'feature: add',
        'feat(Meetings): add',
        'feat:',
        'feat: ${'x' * 73}',
        '',
      ]) {
        expect(check.check(message: message), isA<CommitMessageRejected>());
      }
    },
  );
}
