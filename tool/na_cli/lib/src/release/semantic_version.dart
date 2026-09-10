import 'package:meta/meta.dart';

@immutable
final class SemanticVersion {
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  final int major;
  final int minor;
  final int patch;

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  static SemanticVersionParse parse({required final String text}) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) {
      return SemanticVersionRejected(reason: '"$text" is not x.y.z');
    }
    return SemanticVersionParsed(
      version: SemanticVersion(
        major: int.parse(match.group(1).toString()),
        minor: int.parse(match.group(2).toString()),
        patch: int.parse(match.group(3).toString()),
      ),
    );
  }

  SemanticVersion bump({required final BumpKind kind}) => switch (kind) {
    BumpKind.major => SemanticVersion(major: major + 1, minor: 0, patch: 0),
    BumpKind.minor => SemanticVersion(major: major, minor: minor + 1, patch: 0),
    BumpKind.patch => SemanticVersion(
      major: major,
      minor: minor,
      patch: patch + 1,
    ),
  };

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(final Object other) =>
      other is SemanticVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

enum BumpKind {
  patch,
  minor,
  major
  ;

  static BumpKindParse parse({required final String text}) {
    final found = BumpKind.values.where((final kind) => kind.name == text);
    if (found.isEmpty) {
      return BumpKindRejected(reason: '"$text" is not patch|minor|major');
    }
    return BumpKindParsed(kind: found.first);
  }
}

sealed class BumpKindParse {
  const BumpKindParse();
}

final class BumpKindParsed extends BumpKindParse {
  const BumpKindParsed({required this.kind});

  final BumpKind kind;
}

final class BumpKindRejected extends BumpKindParse {
  const BumpKindRejected({required this.reason});

  final String reason;
}

sealed class SemanticVersionParse {
  const SemanticVersionParse();
}

final class SemanticVersionParsed extends SemanticVersionParse {
  const SemanticVersionParsed({required this.version});

  final SemanticVersion version;
}

final class SemanticVersionRejected extends SemanticVersionParse {
  const SemanticVersionRejected({required this.reason});

  final String reason;
}
