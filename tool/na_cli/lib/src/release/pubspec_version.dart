import 'package:na_cli/src/release/semantic_version.dart';
import 'package:na_cli/src/release/version.dart';

final class PubspecVersion {
  const PubspecVersion();

  static final RegExp _line = RegExp(
    r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
    multiLine: true,
  );

  AppVersionParse read({required final String pubspecText}) {
    final match = _line.firstMatch(pubspecText);
    if (match == null) {
      return const AppVersionUnparseable(
        reason: 'pubspec has no "version: x.y.z+code" line',
      );
    }
    final parsed = SemanticVersion.parse(text: match.group(1).toString());
    return switch (parsed) {
      SemanticVersionRejected(:final reason) => AppVersionUnparseable(
        reason: reason,
      ),
      SemanticVersionParsed(:final version) => AppVersion.fromCode(
        version: version,
        code: VersionCode(int.parse(match.group(2).toString())),
      ),
    };
  }

  String write({
    required final String pubspecText,
    required final AppVersion version,
  }) => pubspecText.replaceFirst(_line, 'version: ${version.pubspecValue}');
}
