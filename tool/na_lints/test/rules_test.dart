@Tags(['unit'])
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:na_lints/src/plugin.dart';
import 'package:test/test.dart';

void main() {
  final fixturesRoot = _fixturesRoot();
  final collection = AnalysisContextCollection(
    includedPaths: [fixturesRoot],
    sdkPath: _dartSdkPath(),
  );
  final rules = naLintRules.whereType<DartLintRule>();

  for (final rule in rules) {
    final ruleName = rule.code.name;
    group(ruleName, () {
      final fixtures = _fixturesUnder(directory: '$fixturesRoot/$ruleName');

      test('has fixtures', () {
        expect(fixtures, isNotEmpty);
      });

      for (final fixture in fixtures) {
        test(fixture.path.substring(fixturesRoot.length + 1), () async {
          final unit = await _resolve(collection: collection, file: fixture);
          final compileErrors = unit.diagnostics.where(
            (final diagnostic) => diagnostic.severity == Severity.error,
          );
          expect(compileErrors, isEmpty);

          final reported = await rule.testRun(unit);
          final actual = reported
              .map(
                (final diagnostic) =>
                    unit.lineInfo.getLocation(diagnostic.offset).lineNumber,
              )
              .toSet();
          final expected = _expectedLines(
            source: unit.content,
            ruleName: ruleName,
          );
          expect(actual, equals(expected));
        });
      }
    });
  }
}

List<File> _fixturesUnder({required final String directory}) =>
    Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .where((final file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((final a, final b) => a.path.compareTo(b.path));

Future<ResolvedUnitResult> _resolve({
  required final AnalysisContextCollection collection,
  required final File file,
}) async {
  final result = await collection
      .contextFor(file.path)
      .currentSession
      .getResolvedUnit(file.path);
  if (result is ResolvedUnitResult) {
    return result;
  }
  fail('Could not resolve ${file.path}: $result');
}

Set<int> _expectedLines({
  required final String source,
  required final String ruleName,
}) {
  final marker = '// expect_${'lint'}: $ruleName';
  final lines = source.split('\n');
  return {
    for (var index = 0; index < lines.length; index++)
      if (lines[index].trim() == marker) index + 2,
  };
}

String _dartSdkPath() {
  final executable = File(Platform.resolvedExecutable).absolute.path;
  final separator = Platform.pathSeparator;
  final cache = '${separator}bin${separator}cache$separator';
  final cacheIndex = executable.indexOf(cache);
  if (cacheIndex >= 0) {
    return [
      executable.substring(0, cacheIndex),
      'bin',
      'cache',
      'dart-sdk',
    ].join(separator);
  }
  return File(executable).parent.parent.path;
}

String _fixturesRoot() {
  final cwd = Directory.current.path;
  return [
    '$cwd/test/fixtures',
    '$cwd/tool/na_lints/test/fixtures',
  ].firstWhere(
    (final path) => Directory(path).existsSync(),
    orElse: () => throw StateError(
      'fixtures not found from $cwd; run from the repo root or tool/na_lints',
    ),
  );
}
