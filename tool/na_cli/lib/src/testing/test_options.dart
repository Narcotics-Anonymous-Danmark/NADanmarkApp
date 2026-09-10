import 'package:na_cli/src/fs/file_path.dart';
import 'package:na_cli/src/testing/test_level.dart';
import 'package:na_cli/src/testing/test_tool.dart';

enum CoverageCollection { on, off }

enum GoldenPolicy { keep, update }

sealed class NameFilter {
  const NameFilter();
}

final class AnyName extends NameFilter {
  const AnyName();
}

final class PlainName extends NameFilter {
  const PlainName({required this.text});

  final String text;
}

sealed class TestScope {
  const TestScope();
}

final class WholeSuite extends TestScope {
  const WholeSuite();
}

final class SingleFile extends TestScope {
  const SingleFile({required this.path});

  final FilePath path;
}

final class TestOptions {
  const TestOptions({
    required this.coverage,
    required this.nameFilter,
    required this.goldens,
  });

  static const TestOptions plain = TestOptions(
    coverage: CoverageCollection.off,
    nameFilter: AnyName(),
    goldens: GoldenPolicy.keep,
  );

  final CoverageCollection coverage;
  final NameFilter nameFilter;
  final GoldenPolicy goldens;

  List<String> passThroughArguments({
    required final TestTool tool,
    required final TestLevel level,
  }) => [
    ...switch (nameFilter) {
      AnyName() => const <String>[],
      PlainName(:final text) => ['--plain-name', text],
    },
    if (goldens == GoldenPolicy.update &&
        tool == TestTool.flutter &&
        (level == TestLevel.widget || level == TestLevel.acceptance))
      '--update-goldens',
  ];
}
