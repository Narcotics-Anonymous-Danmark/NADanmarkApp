import 'package:na_cli/src/release/version.dart';

final class IpaFacts {
  const IpaFacts({
    required this.shortVersion,
    required this.bundleVersion,
    required this.codeResourcesPresent,
  });

  final String shortVersion;
  final String bundleVersion;
  final CodeResources codeResourcesPresent;
}

enum CodeResources { present, missing }

final class IpaVerification {
  const IpaVerification();

  List<String> problems({
    required final IpaFacts facts,
    required final AppVersion expected,
  }) => List.unmodifiable([
    if (facts.shortVersion.trim() != '${expected.version}')
      _mismatch(
        key: 'CFBundleShortVersionString',
        actual: facts.shortVersion.trim(),
        expected: '${expected.version}',
      ),
    if (facts.bundleVersion.trim() != '${expected.build.value}')
      _mismatch(
        key: 'CFBundleVersion',
        actual: facts.bundleVersion.trim(),
        expected: '${expected.build.value}',
      ),
    if (facts.codeResourcesPresent == CodeResources.missing)
      '_CodeSignature/CodeResources is missing from the app bundle',
  ]);

  String _mismatch({
    required final String key,
    required final String actual,
    required final String expected,
  }) => '$key is "$actual", expected $expected';
}
