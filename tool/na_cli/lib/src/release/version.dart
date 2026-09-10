import 'package:meta/meta.dart';
import 'package:na_cli/src/release/semantic_version.dart';

extension type const BuildNumber(int value) {}

extension type const VersionCode(int value) {}

extension type const ReleaseTag(String value) {}

@immutable
final class AppVersion {
  const AppVersion({required this.version, required this.build});

  final SemanticVersion version;
  final BuildNumber build;

  static const int codeBase = 1100000000;
  static const int codeCeiling = 2100000000;

  VersionCode get code => VersionCode(
    codeBase +
        (version.major * 10000 + version.minor * 100 + version.patch) * 1000 +
        build.value,
  );

  ReleaseTag get tag => build.value == 1
      ? ReleaseTag('$version')
      : ReleaseTag('$version-b${build.value}');

  String get pubspecValue => '$version+${code.value}';

  AppVersionValidation validate() {
    final reasons = [
      if (version.minor >= 100) 'minor must be below 100',
      if (version.patch >= 100) 'patch must be below 100',
      if (build.value < 1 || build.value > 999) 'build must be within 1..999',
      if (code.value > codeCeiling) 'version code exceeds $codeCeiling',
    ];
    if (reasons.isEmpty) {
      return AppVersionAccepted(version: this);
    }
    return AppVersionRejected(reasons: List.unmodifiable(reasons));
  }

  static AppVersionParse fromCode({
    required final SemanticVersion version,
    required final VersionCode code,
  }) {
    final withoutBuild = AppVersion(
      version: version,
      build: const BuildNumber(0),
    );
    final build = code.value - withoutBuild.code.value;
    if (build < 1 || build > 999) {
      return AppVersionUnparseable(
        reason:
            'version code ${code.value} does not match $version by the formula',
      );
    }
    return AppVersionParsed(
      version: AppVersion(version: version, build: BuildNumber(build)),
    );
  }

  @override
  bool operator ==(final Object other) =>
      other is AppVersion && other.version == version && other.build == build;

  @override
  int get hashCode => Object.hash(version, build);
}

sealed class AppVersionValidation {
  const AppVersionValidation();
}

final class AppVersionAccepted extends AppVersionValidation {
  const AppVersionAccepted({required this.version});

  final AppVersion version;
}

final class AppVersionRejected extends AppVersionValidation {
  const AppVersionRejected({required this.reasons});

  final List<String> reasons;
}

sealed class AppVersionParse {
  const AppVersionParse();
}

final class AppVersionParsed extends AppVersionParse {
  const AppVersionParsed({required this.version});

  final AppVersion version;
}

final class AppVersionUnparseable extends AppVersionParse {
  const AppVersionUnparseable({required this.reason});

  final String reason;
}
