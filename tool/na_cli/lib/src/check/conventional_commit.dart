final class ConventionalCommit {
  const ConventionalCommit();

  static final RegExp _conventional = RegExp(
    '^(feat|fix|chore|refactor|docs|test|ci|build|perf|revert)'
    r'(\([a-z0-9-]+\))?!?: .{1,72}$',
  );

  static final RegExp _tooling = RegExp(
    '^(Merge |Revert |fixup! |squash! |amend! )',
  );

  CommitMessageVerdict check({required final String message}) {
    final lines = message
        .split('\n')
        .map((final line) => line.trimRight())
        .where((final line) => line.isNotEmpty && !line.startsWith('#'))
        .toList(growable: false);
    if (lines.isEmpty) {
      return const CommitMessageRejected(reason: 'commit message is empty');
    }
    final subject = lines.first;
    if (_conventional.hasMatch(subject) || _tooling.hasMatch(subject)) {
      return CommitMessageAccepted(subject: subject);
    }
    return CommitMessageRejected(
      reason:
          '"$subject" is not a conventional commit: '
          'type(scope)!: subject, subject up to 72 characters, '
          'type in feat|fix|chore|refactor|docs|test|ci|build|perf|revert',
    );
  }
}

sealed class CommitMessageVerdict {
  const CommitMessageVerdict();
}

final class CommitMessageAccepted extends CommitMessageVerdict {
  const CommitMessageAccepted({required this.subject});

  final String subject;
}

final class CommitMessageRejected extends CommitMessageVerdict {
  const CommitMessageRejected({required this.reason});

  final String reason;
}
